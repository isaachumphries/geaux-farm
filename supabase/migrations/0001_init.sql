-- Geaux Farm community schema.
-- Tables, triggers, feed view, column grants, RLS policies and the image bucket.
-- Counters and the `hidden` status are written only by triggers; clients cannot set them.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- tables

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text,
  city         text,
  zone         text,
  created_at   timestamptz not null default now()
);

create table public.guides (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references public.profiles (id) on delete cascade,
  title         text not null check (char_length(title) between 5 and 80),
  summary       text check (char_length(summary) <= 280),
  cover_path    text,
  difficulty    smallint check (difficulty between 1 and 3),
  space_types   text[] not null default '{}',
  est_cost_usd  int check (est_cost_usd >= 0),
  setup_minutes int check (setup_minutes >= 0),
  materials     jsonb not null default '[]',
  steps         jsonb not null default '[]',
  plant_ids     text[] not null default '{}',
  tags          text[] not null default '{}',
  forked_from   uuid references public.guides (id) on delete set null,
  status        text not null default 'draft'
                  check (status in ('draft', 'published', 'hidden')),
  star_count    int not null default 0,
  grow_count    int not null default 0,
  remix_count   int not null default 0,
  report_count  int not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  published_at  timestamptz
);

create index guides_author_id_idx on public.guides (author_id);
create index guides_forked_from_idx on public.guides (forked_from);
create index guides_status_published_at_idx on public.guides (status, published_at desc);

create table public.guide_stars (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  guide_id   uuid not null references public.guides (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, guide_id)
);

create index guide_stars_guide_id_created_at_idx
  on public.guide_stars (guide_id, created_at desc);

create table public.guide_grows (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  guide_id   uuid not null references public.guides (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, guide_id)
);

create index guide_grows_guide_id_idx on public.guide_grows (guide_id);

create table public.guide_reports (
  guide_id    uuid not null references public.guides (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason      text not null check (reason in ('spam', 'unsafe', 'offensive', 'other')),
  note        text check (char_length(note) <= 200),
  created_at  timestamptz not null default now(),
  primary key (guide_id, reporter_id)
);

create table public.attribution_responses (
  id         bigint generated always as identity primary key,
  source     text not null,
  other_text text check (char_length(other_text) <= 60),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------- triggers and functions

-- Stamp published_at when a guide is created already published.
create function public.guides_set_published_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

create trigger guides_before_insert
  before insert on public.guides
  for each row execute function public.guides_set_published_at();

-- Touch updated_at on content edits, and stamp published_at on first publish.
create function public.guides_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end;
$$;

create trigger guides_before_update
  before update of title, summary, cover_path, difficulty, space_types,
                   est_cost_usd, setup_minutes, materials, steps, plant_ids,
                   tags, status
  on public.guides
  for each row execute function public.guides_touch_updated_at();

-- Move a counter column on the parent guide by +1/-1.
-- Security definer: clients have no update grant on the counter columns.
create function public.bump_guide_counter()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  col text := tg_argv[0];
begin
  if tg_op = 'INSERT' then
    execute format('update public.guides set %I = %I + 1 where id = $1', col, col)
      using new.guide_id;
    return new;
  else
    execute format('update public.guides set %I = greatest(%I - 1, 0) where id = $1', col, col)
      using old.guide_id;
    return old;
  end if;
end;
$$;

create trigger guide_stars_count
  after insert or delete on public.guide_stars
  for each row execute function public.bump_guide_counter('star_count');

create trigger guide_grows_count
  after insert or delete on public.guide_grows
  for each row execute function public.bump_guide_counter('grow_count');

-- Credit the parent guide the first time a fork is published.
create function public.bump_remix_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.forked_from is null or new.status <> 'published' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'published' then
    return new;
  end if;
  update public.guides
     set remix_count = remix_count + 1
   where id = new.forked_from;
  return new;
end;
$$;

create trigger guides_remix_count
  after insert or update of status on public.guides
  for each row execute function public.bump_remix_count();

-- Count a report and hide the guide once three have landed.
create function public.apply_report()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.guides
     set report_count = report_count + 1,
         status = case when report_count + 1 >= 3 then 'hidden' else status end
   where id = new.guide_id;
  return new;
end;
$$;

create trigger guide_reports_apply
  after insert on public.guide_reports
  for each row execute function public.apply_report();

-- ------------------------------------------------------------------ view

create view public.guide_feed
with (security_invoker = true) as
  select g.*,
         p.username     as author_username,
         p.display_name as author_display_name,
         coalesce(s.stars_7d, 0) as stars_7d
    from public.guides g
    join public.profiles p on p.id = g.author_id
    left join lateral (
      select count(*) as stars_7d
        from public.guide_stars gs
       where gs.guide_id = g.id
         and gs.created_at >= now() - interval '7 days'
    ) s on true
   where g.status = 'published';

-- ---------------------------------------------------------------- grants

-- Counters, report_count and the hidden status are trigger-owned.
revoke insert, update on public.guides from anon, authenticated;

grant insert (
  author_id, title, summary, cover_path, difficulty, space_types,
  est_cost_usd, setup_minutes, materials, steps, plant_ids, tags,
  forked_from, status
) on public.guides to authenticated;

grant update (
  title, summary, cover_path, difficulty, space_types, est_cost_usd,
  setup_minutes, materials, steps, plant_ids, tags, status
) on public.guides to authenticated;

-- ------------------------------------------------------------------- RLS

alter table public.profiles              enable row level security;
alter table public.guides                enable row level security;
alter table public.guide_stars           enable row level security;
alter table public.guide_grows           enable row level security;
alter table public.guide_reports         enable row level security;
alter table public.attribution_responses enable row level security;

-- profiles: world-readable, self-writable, never deletable.
create policy profiles_select_all on public.profiles
  for select using (true);

create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (id = auth.uid());

create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- guides: published to everyone, drafts to their author only.
create policy guides_select_published_or_own on public.guides
  for select using (status = 'published' or author_id = auth.uid());

create policy guides_insert_own on public.guides
  for insert to authenticated
  with check (author_id = auth.uid() and status in ('draft', 'published'));

create policy guides_update_own on public.guides
  for update to authenticated
  using (author_id = auth.uid() and status <> 'hidden')
  with check (author_id = auth.uid() and status in ('draft', 'published'));

create policy guides_delete_own on public.guides
  for delete to authenticated using (author_id = auth.uid());

-- stars and grows: readable by all, written only for yourself.
create policy guide_stars_select_all on public.guide_stars
  for select using (true);

create policy guide_stars_insert_own on public.guide_stars
  for insert to authenticated with check (user_id = auth.uid());

create policy guide_stars_delete_own on public.guide_stars
  for delete to authenticated using (user_id = auth.uid());

create policy guide_grows_select_all on public.guide_grows
  for select using (true);

create policy guide_grows_insert_own on public.guide_grows
  for insert to authenticated with check (user_id = auth.uid());

create policy guide_grows_delete_own on public.guide_grows
  for delete to authenticated using (user_id = auth.uid());

-- reports: write-only for the reporter; no read policy is defined.
create policy guide_reports_insert_own on public.guide_reports
  for insert to authenticated with check (reporter_id = auth.uid());

-- attribution: anonymous write-only, no read policy.
create policy attribution_responses_insert_any on public.attribution_responses
  for insert to anon, authenticated with check (true);

-- --------------------------------------------------------------- storage

insert into storage.buckets (id, name, public)
values ('guide-images', 'guide-images', true)
on conflict (id) do nothing;

-- Owners write only inside a folder named for their uid.
create policy guide_images_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'guide-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy guide_images_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'guide-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
