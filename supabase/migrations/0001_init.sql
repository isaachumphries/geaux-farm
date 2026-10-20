create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text,
  city text,
  zone text,
  created_at timestamptz not null default now()
);

create table public.guides (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 5 and 80),
  summary text not null check (char_length(summary) <= 280),
  cover_path text,
  difficulty smallint not null check (difficulty between 1 and 3),
  space_types text[] not null default '{}',
  est_cost_usd int check (est_cost_usd >= 0),
  setup_minutes int check (setup_minutes >= 0),
  materials jsonb not null default '[]',
  steps jsonb not null default '[]',
  plant_ids text[] not null default '{}',
  tags text[] not null default '{}',
  forked_from uuid references public.guides(id) on delete set null,
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  star_count int not null default 0,
  grow_count int not null default 0,
  remix_count int not null default 0,
  report_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);

create table public.guide_stars (
  user_id uuid not null references public.profiles(id) on delete cascade,
  guide_id uuid not null references public.guides(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, guide_id)
);

create table public.guide_grows (
  user_id uuid not null references public.profiles(id) on delete cascade,
  guide_id uuid not null references public.guides(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, guide_id)
);

create table public.guide_reports (
  guide_id uuid not null references public.guides(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('spam','unsafe','offensive','other')),
  note text check (char_length(note) <= 200),
  created_at timestamptz not null default now(),
  primary key (guide_id, reporter_id)
);

create table public.attribution_responses (
  id bigint generated always as identity primary key,
  source text not null,
  other_text text check (char_length(other_text) <= 60),
  created_at timestamptz not null default now()
);

-- timestamps
create function public.guides_before_update() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  if new.status = 'published' and old.published_at is null then
    new.published_at := now();
  end if;
  return new;
end $$;
create trigger guides_before_update
  before update of title, summary, cover_path, difficulty, space_types, est_cost_usd,
                   setup_minutes, materials, steps, plant_ids, tags, status
  on public.guides
  for each row execute function public.guides_before_update();

create function public.guides_before_insert() returns trigger
language plpgsql as $$
begin
  if new.status = 'published' then new.published_at := now(); end if;
  return new;
end $$;
create trigger guides_before_insert before insert on public.guides
  for each row execute function public.guides_before_insert();

-- counters (security definer: bypass RLS on guides)
create function public.bump_guide_counter() returns trigger
language plpgsql security definer set search_path = public as $$
declare delta int;
        gid uuid;
begin
  if tg_op = 'INSERT' then
    delta := 1;  gid := new.guide_id;
  else
    delta := -1; gid := old.guide_id;
  end if;
  if tg_table_name = 'guide_stars' then
    update guides set star_count = star_count + delta where id = gid;
  else
    update guides set grow_count = grow_count + delta where id = gid;
  end if;
  return null;
end $$;
create trigger guide_stars_count after insert or delete on public.guide_stars
  for each row execute function public.bump_guide_counter();
create trigger guide_grows_count after insert or delete on public.guide_grows
  for each row execute function public.bump_guide_counter();

create function public.bump_remix_count() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.forked_from is null or new.status <> 'published' then
    return null;
  end if;
  if tg_op = 'UPDATE' then
    if old.published_at is not null then return null; end if;
  end if;
  update guides set remix_count = remix_count + 1 where id = new.forked_from;
  return null;
end $$;
create trigger guides_remix_count after insert or update of status on public.guides
  for each row execute function public.bump_remix_count();

create function public.apply_report() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update guides
     set report_count = report_count + 1,
         status = case when report_count + 1 >= 3 then 'hidden' else status end
   where id = new.guide_id;
  return null;
end $$;
create trigger guide_reports_apply after insert on public.guide_reports
  for each row execute function public.apply_report();

-- feed view (stars are public, like GitHub stargazers)
create view public.guide_feed with (security_invoker = true) as
select g.*,
       p.username as author_username,
       p.display_name as author_display_name,
       (select count(*) from public.guide_stars s
         where s.guide_id = g.id and s.created_at > now() - interval '7 days')::int as stars_7d
from public.guides g
join public.profiles p on p.id = g.author_id
where g.status = 'published';

-- column privileges: clients can never write counters, status 'hidden', or timestamps
revoke insert, update on public.guides from anon, authenticated;
grant insert (author_id, title, summary, cover_path, difficulty, space_types, est_cost_usd,
              setup_minutes, materials, steps, plant_ids, tags, forked_from, status)
  on public.guides to authenticated;
grant update (title, summary, cover_path, difficulty, space_types, est_cost_usd,
              setup_minutes, materials, steps, plant_ids, tags, status)
  on public.guides to authenticated;

-- RLS
alter table public.profiles enable row level security;
alter table public.guides enable row level security;
alter table public.guide_stars enable row level security;
alter table public.guide_grows enable row level security;
alter table public.guide_reports enable row level security;
alter table public.attribution_responses enable row level security;

create policy profiles_read on public.profiles for select using (true);
create policy profiles_insert on public.profiles for insert to authenticated with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated using (id = auth.uid());

create policy guides_read on public.guides for select
  using (status = 'published' or author_id = auth.uid());
create policy guides_insert on public.guides for insert to authenticated
  with check (author_id = auth.uid() and status in ('draft','published'));
create policy guides_update on public.guides for update to authenticated
  using (author_id = auth.uid() and status <> 'hidden')
  with check (author_id = auth.uid() and status in ('draft','published'));
create policy guides_delete on public.guides for delete to authenticated
  using (author_id = auth.uid());

create policy stars_read on public.guide_stars for select using (true);
create policy stars_insert on public.guide_stars for insert to authenticated with check (user_id = auth.uid());
create policy stars_delete on public.guide_stars for delete to authenticated using (user_id = auth.uid());

create policy grows_read on public.guide_grows for select using (true);
create policy grows_insert on public.guide_grows for insert to authenticated with check (user_id = auth.uid());
create policy grows_delete on public.guide_grows for delete to authenticated using (user_id = auth.uid());

create policy reports_insert on public.guide_reports for insert to authenticated with check (reporter_id = auth.uid());

create policy attribution_insert on public.attribution_responses for insert to anon, authenticated with check (true);

-- storage
insert into storage.buckets (id, name, public) values ('guide-images', 'guide-images', true);
create policy guide_images_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'guide-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy guide_images_delete on storage.objects for delete to authenticated
  using (bucket_id = 'guide-images' and (storage.foldername(name))[1] = auth.uid()::text);
