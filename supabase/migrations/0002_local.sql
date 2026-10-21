-- Local board: seed offers, requests, questions and tips from neighbours
-- (plan/08 § Schema). Follows 0001_init.sql: a security-definer report
-- trigger, column grants that exclude the counters and `hidden`, and RLS
-- on every table.

create table public.local_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('offer_seeds','want_seeds','question','tip')),
  title text not null check (char_length(title) between 3 and 80),
  body text not null check (char_length(body) <= 1000),
  plant_ids text[] not null default '{}',
  lat_round numeric(4,1) not null,
  lon_round numeric(4,1) not null,
  area_label text not null,
  status text not null default 'open' check (status in ('open','closed','hidden')),
  report_count int not null default 0,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);

create table public.local_replies (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.local_posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) <= 500),
  created_at timestamptz not null default now()
);

create table public.local_reports (
  post_id uuid not null references public.local_posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in ('spam','unsafe','offensive','other')),
  created_at timestamptz not null default now(),
  primary key (post_id, reporter_id)
);

-- reports (security definer: bypass RLS on local_posts)
create function public.apply_local_report() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update local_posts
     set report_count = report_count + 1,
         status = case when report_count + 1 >= 3 then 'hidden' else status end
   where id = new.post_id;
  return null;
end $$;
create trigger local_reports_apply after insert on public.local_reports
  for each row execute function public.apply_local_report();

-- column privileges: clients can never write report_count, ids, or timestamps
revoke insert, update on public.local_posts from anon, authenticated;
grant insert (author_id, kind, title, body, plant_ids, lat_round, lon_round, area_label, status)
  on public.local_posts to authenticated;
grant update (title, body, plant_ids, status)
  on public.local_posts to authenticated;

-- RLS
alter table public.local_posts enable row level security;
alter table public.local_replies enable row level security;
alter table public.local_reports enable row level security;

create policy local_posts_read on public.local_posts for select
  using (status = 'open' or author_id = auth.uid());
create policy local_posts_insert on public.local_posts for insert to authenticated
  with check (author_id = auth.uid() and status in ('open','closed'));
create policy local_posts_update on public.local_posts for update to authenticated
  using (author_id = auth.uid() and status <> 'hidden')
  with check (author_id = auth.uid() and status in ('open','closed'));
create policy local_posts_delete on public.local_posts for delete to authenticated
  using (author_id = auth.uid());

create policy local_replies_read on public.local_replies for select using (true);
create policy local_replies_insert on public.local_replies for insert to authenticated
  with check (author_id = auth.uid());
create policy local_replies_delete on public.local_replies for delete to authenticated
  using (author_id = auth.uid());

create policy local_reports_insert on public.local_reports for insert to authenticated
  with check (reporter_id = auth.uid());
