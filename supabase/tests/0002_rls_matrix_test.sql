begin;
create extension if not exists pgtap with schema extensions;
select plan(61);

-- RLS matrix for every policy in 0001_init.sql (plan/07 § Supabase schema) and
-- 0003_guide_images_select.sql: anon / owner / other user against select,
-- insert, update, delete on each table, plus storage.objects in the
-- guide-images bucket. Every deny check has a matching allow check for the
-- same role and table, so a deny-all policy (or RLS switched off) fails the
-- suite instead of passing it.

-- Runs a statement under the current role and returns how many rows it
-- touched. RLS filters UPDATE/DELETE silently (0 rows, no error), so row
-- counts are what tell "denied" apart from "allowed".
create schema rls_test;
grant usage on schema rls_test to anon, authenticated;
create function rls_test.affected(q text) returns int
language plpgsql as $$
declare n int;
begin
  execute q;
  get diagnostics n = row_count;
  return n;
end $$;

-- Fixtures, inserted as postgres (bypasses RLS).
-- A and B have profiles; C and D are signed-up users without one yet.
insert into auth.users (id, email) values
  ('c1370000-0000-4000-8000-00000000000a', 'rls_a@example.test'),
  ('c1370000-0000-4000-8000-00000000000b', 'rls_b@example.test'),
  ('c1370000-0000-4000-8000-00000000000c', 'rls_c@example.test'),
  ('c1370000-0000-4000-8000-00000000000d', 'rls_d@example.test');

insert into public.profiles (id, username, display_name) values
  ('c1370000-0000-4000-8000-00000000000a', 'rls_a', 'A'),
  ('c1370000-0000-4000-8000-00000000000b', 'rls_b', 'B');

insert into public.guides (id, author_id, title, summary, difficulty, status) values
  ('c1370000-0000-4000-8000-0000000000a1', 'c1370000-0000-4000-8000-00000000000a',
   'A published guide', 'Published by A.', 1, 'published'),
  ('c1370000-0000-4000-8000-0000000000a2', 'c1370000-0000-4000-8000-00000000000a',
   'A draft guide', 'Drafted by A.', 1, 'draft'),
  ('c1370000-0000-4000-8000-0000000000b1', 'c1370000-0000-4000-8000-00000000000b',
   'B published guide', 'Published by B.', 1, 'published');

-- A has starred and is growing B's guide.
insert into public.guide_stars (user_id, guide_id) values
  ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000b1');
insert into public.guide_grows (user_id, guide_id) values
  ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000b1');

insert into storage.buckets (id, name, public) values ('rls-other', 'rls-other', true);
insert into storage.objects (bucket_id, name) values
  ('guide-images', 'c1370000-0000-4000-8000-00000000000a/a1/cover.jpg'),
  ('guide-images', 'c1370000-0000-4000-8000-00000000000b/b1/cover.jpg'),
  ('rls-other',    'c1370000-0000-4000-8000-00000000000a/a1/cover.jpg');

-- ---------------------------------------------------------------------------
-- profiles: readable by everyone, insert/update only your own row, no delete.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.profiles where username in ('rls_a', 'rls_b')),
  2, 'profiles_read: anon can read profiles');
select throws_ok(
  $$insert into public.profiles (id, username)
    values ('c1370000-0000-4000-8000-00000000000c', 'rls_c')$$,
  '42501', null, 'profiles_insert: anon cannot create a profile');
select is(rls_test.affected(
  $$update public.profiles set display_name = 'anon edit'
     where id = 'c1370000-0000-4000-8000-00000000000a'$$),
  0, 'profiles_update: anon cannot update a profile');
select is(rls_test.affected(
  $$delete from public.profiles where id = 'c1370000-0000-4000-8000-00000000000a'$$),
  0, 'profiles: anon cannot delete a profile');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000c","role":"authenticated"}';
select throws_ok(
  $$insert into public.profiles (id, username)
    values ('c1370000-0000-4000-8000-00000000000d', 'rls_d')$$,
  '42501', null, 'profiles_insert: C cannot create a profile for user D (id spoofing)');
select lives_ok(
  $$insert into public.profiles (id, username)
    values ('c1370000-0000-4000-8000-00000000000c', 'rls_c')$$,
  'profiles_insert: C can create their own profile');

set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is(rls_test.affected(
  $$update public.profiles set display_name = 'B edit'
     where id = 'c1370000-0000-4000-8000-00000000000a'$$),
  0, 'profiles_update: B cannot update A''s profile');
select is(rls_test.affected(
  $$delete from public.profiles where id = 'c1370000-0000-4000-8000-00000000000a'$$),
  0, 'profiles: B cannot delete A''s profile');

set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(rls_test.affected(
  $$update public.profiles set display_name = 'A edit'
     where id = 'c1370000-0000-4000-8000-00000000000a'$$),
  1, 'profiles_update: A can update their own profile');
reset role;
select is((select display_name from public.profiles
            where id = 'c1370000-0000-4000-8000-00000000000a'),
  'A edit', 'profiles: only A''s own edit reached A''s row');

-- ---------------------------------------------------------------------------
-- guides: published or own rows visible; insert/update only as yourself with
-- status draft/published; delete only your own.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.guides
            where id = 'c1370000-0000-4000-8000-0000000000a1'),
  1, 'guides_read: anon sees a published guide');
select is((select count(*)::int from public.guides
            where id = 'c1370000-0000-4000-8000-0000000000a2'),
  0, 'guides_read: anon cannot see a draft');
select is(rls_test.affected(
  $$delete from public.guides where id = 'c1370000-0000-4000-8000-0000000000a1'$$),
  0, 'guides_delete: anon cannot delete a guide');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is((select count(*)::int from public.guides
            where id = 'c1370000-0000-4000-8000-0000000000a2'),
  0, 'guides_read: B cannot see A''s draft');
select throws_ok(
  $$insert into public.guides (author_id, title, summary, difficulty, status)
    values ('c1370000-0000-4000-8000-00000000000a', 'Spoofed guide', 'Not by A.', 1, 'draft')$$,
  '42501', null, 'guides_insert: B cannot insert a guide authored as A (author_id spoofing)');
select throws_ok(
  $$insert into public.guides (author_id, title, summary, difficulty, status)
    values ('c1370000-0000-4000-8000-00000000000b', 'Pre-hidden guide', 'Hidden.', 1, 'hidden')$$,
  '42501', null, 'guides_insert: B cannot insert a guide with status hidden');
select lives_ok(
  $$insert into public.guides (author_id, title, summary, difficulty, status)
    values ('c1370000-0000-4000-8000-00000000000b', 'B second guide', 'By B.', 1, 'draft')$$,
  'guides_insert: B can insert a draft authored as B');

set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is((select count(*)::int from public.guides
            where id = 'c1370000-0000-4000-8000-0000000000a2'),
  1, 'guides_read: A sees their own draft');
select throws_ok(
  $$update public.guides set status = 'hidden'
     where id = 'c1370000-0000-4000-8000-0000000000a1'$$,
  '42501', null, 'guides_update: A cannot set their own guide to hidden');
select is(rls_test.affected(
  $$delete from public.guides where id = 'c1370000-0000-4000-8000-0000000000a2'$$),
  1, 'guides_delete: A can delete their own draft');
reset role;

-- ---------------------------------------------------------------------------
-- guide_stars / guide_grows: public reads; insert and delete only as yourself.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.guide_stars
            where guide_id = 'c1370000-0000-4000-8000-0000000000b1'),
  1, 'stars_read: anon can read stars');
select is((select count(*)::int from public.guide_grows
            where guide_id = 'c1370000-0000-4000-8000-0000000000b1'),
  1, 'grows_read: anon can read grows');
select throws_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000a1')$$,
  '42501', null, 'stars_insert: anon cannot star');
select throws_ok(
  $$insert into public.guide_grows (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000a1')$$,
  '42501', null, 'grows_insert: anon cannot record a grow');
select is(rls_test.affected(
  $$delete from public.guide_stars where guide_id = 'c1370000-0000-4000-8000-0000000000b1'$$),
  0, 'stars_delete: anon cannot delete a star');
select is(rls_test.affected(
  $$delete from public.guide_grows where guide_id = 'c1370000-0000-4000-8000-0000000000b1'$$),
  0, 'grows_delete: anon cannot delete a grow');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select throws_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000a1')$$,
  '42501', null, 'stars_insert: B cannot star as A (user_id spoofing)');
select lives_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000b', 'c1370000-0000-4000-8000-0000000000a1')$$,
  'stars_insert: B can star as B');
select throws_ok(
  $$insert into public.guide_grows (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000a', 'c1370000-0000-4000-8000-0000000000a1')$$,
  '42501', null, 'grows_insert: B cannot record a grow as A (user_id spoofing)');
select lives_ok(
  $$insert into public.guide_grows (user_id, guide_id)
    values ('c1370000-0000-4000-8000-00000000000b', 'c1370000-0000-4000-8000-0000000000a1')$$,
  'grows_insert: B can record a grow as B');
select is(rls_test.affected(
  $$delete from public.guide_grows
     where user_id = 'c1370000-0000-4000-8000-00000000000a'
       and guide_id = 'c1370000-0000-4000-8000-0000000000b1'$$),
  0, 'grows_delete: B cannot delete A''s grow');

set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(rls_test.affected(
  $$delete from public.guide_grows
     where user_id = 'c1370000-0000-4000-8000-00000000000a'
       and guide_id = 'c1370000-0000-4000-8000-0000000000b1'$$),
  1, 'grows_delete: A can delete their own grow');
reset role;

-- ---------------------------------------------------------------------------
-- guide_reports: insert only as yourself; no client role can read, change or
-- withdraw a report (moderation is done with the service role, plan/07).
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok(
  $$insert into public.guide_reports (guide_id, reporter_id, reason)
    values ('c1370000-0000-4000-8000-0000000000a1', 'c1370000-0000-4000-8000-00000000000b', 'spam')$$,
  '42501', null, 'reports_insert: anon cannot report');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select throws_ok(
  $$insert into public.guide_reports (guide_id, reporter_id, reason)
    values ('c1370000-0000-4000-8000-0000000000a1', 'c1370000-0000-4000-8000-00000000000c', 'spam')$$,
  '42501', null, 'reports_insert: B cannot report as C (reporter_id spoofing)');
select lives_ok(
  $$insert into public.guide_reports (guide_id, reporter_id, reason)
    values ('c1370000-0000-4000-8000-0000000000a1', 'c1370000-0000-4000-8000-00000000000b', 'spam')$$,
  'reports_insert: B can report A''s guide as B');
select is((select count(*)::int from public.guide_reports),
  0, 'guide_reports: the reporter cannot read reports');
select is(rls_test.affected(
  $$update public.guide_reports set reason = 'other'
     where guide_id = 'c1370000-0000-4000-8000-0000000000a1'$$),
  0, 'guide_reports: the reporter cannot change their report');
select is(rls_test.affected(
  $$delete from public.guide_reports
     where guide_id = 'c1370000-0000-4000-8000-0000000000a1'$$),
  0, 'guide_reports: the reporter cannot withdraw their report');

set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is((select count(*)::int from public.guide_reports),
  0, 'guide_reports: the reported guide''s author cannot read reports');

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.guide_reports),
  0, 'guide_reports: anon cannot read reports');
reset role;
select is((select count(*)::int from public.guide_reports
            where guide_id = 'c1370000-0000-4000-8000-0000000000a1'
              and reporter_id = 'c1370000-0000-4000-8000-00000000000b'
              and reason = 'spam'),
  1, 'guide_reports: B''s report is stored unchanged (control for the 0-row reads)');

-- ---------------------------------------------------------------------------
-- attribution_responses: insert-only for anon and authenticated.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select lives_ok(
  $$insert into public.attribution_responses (source) values ('rls_anon')$$,
  'attribution_insert: anon can submit a response');
select is((select count(*)::int from public.attribution_responses),
  0, 'attribution_responses: anon cannot read responses');
select is(rls_test.affected(
  $$update public.attribution_responses set source = 'edited'$$),
  0, 'attribution_responses: anon cannot update responses');
select is(rls_test.affected(
  $$delete from public.attribution_responses$$),
  0, 'attribution_responses: anon cannot delete responses');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select lives_ok(
  $$insert into public.attribution_responses (source) values ('rls_auth')$$,
  'attribution_insert: a signed-in user can submit a response');
select is((select count(*)::int from public.attribution_responses),
  0, 'attribution_responses: a signed-in user cannot read responses');
reset role;
select is((select count(*)::int from public.attribution_responses
            where source in ('rls_anon', 'rls_auth')),
  2, 'attribution_responses: both responses are stored (control for the 0-row reads)');

-- ---------------------------------------------------------------------------
-- storage.objects: authenticated users see and write only under "{uid}/" in
-- the guide-images bucket (plan/07 § Editor: "{uid}/{guideId}/{uuid}.jpg").
-- ---------------------------------------------------------------------------
-- storage.protect_delete blocks raw SQL deletes unless this is set; the
-- Storage API sets it for its own deletes.
set local storage.allow_delete_query = 'true';

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('guide-images', 'c1370000-0000-4000-8000-00000000000a/a1/anon.jpg')$$,
  '42501', null, 'guide_images_insert: anon cannot upload');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select lives_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('guide-images', 'c1370000-0000-4000-8000-00000000000a/a1/step1.jpg')$$,
  'guide_images_insert: A can upload under their own folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('guide-images', 'c1370000-0000-4000-8000-00000000000b/b1/step1.jpg')$$,
  '42501', null, 'guide_images_insert: A cannot upload into B''s folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name) values ('guide-images', 'loose.jpg')$$,
  '42501', null, 'guide_images_insert: A cannot upload outside any user folder');
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values ('rls-other', 'c1370000-0000-4000-8000-00000000000a/a1/step1.jpg')$$,
  '42501', null, 'guide_images_insert: A''s folder rule does not extend to other buckets');

-- guide_images_select: you see only your own "{uid}/" folder in guide-images.
-- The bucket is public, so images load by URL without a policy; this one is
-- for the Storage API's own queries (list, and the filtered delete below).
select set_eq(
  $$select bucket_id || ':' || name from storage.objects where name like 'c137%'$$,
  $$values ('guide-images:c1370000-0000-4000-8000-00000000000a/a1/cover.jpg'),
           ('guide-images:c1370000-0000-4000-8000-00000000000a/a1/step1.jpg')$$,
  'guide_images_select: A sees only their own guide images (not B''s, not other buckets)');

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from storage.objects where name like 'c137%'),
  0, 'guide_images_select: anon cannot list objects');

-- Unfiltered deletes: with no WHERE clause Postgres applies only the DELETE
-- policy, so these pin guide_images_delete on its own, apart from
-- guide_images_select.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is(rls_test.affected($$delete from storage.objects$$),
  1, 'guide_images_delete: B deletes only B''s own guide image');

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is(rls_test.affected($$delete from storage.objects$$),
  0, 'guide_images_delete: anon cannot delete objects');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(rls_test.affected($$delete from storage.objects$$),
  2, 'guide_images_delete: A deletes only A''s guide images');
reset role;
select set_eq(
  $$select bucket_id || ':' || name from storage.objects where name like 'c137%'$$,
  $$values ('rls-other:c1370000-0000-4000-8000-00000000000a/a1/cover.jpg')$$,
  'guide_images_delete: A''s object in another bucket survives');

-- Deletes filtered by name, which is what the Storage API's remove() runs.
-- Postgres also applies SELECT policies here, so the owner's delete needs
-- guide_images_select (bug #143). A's delete after B's attempt also shows the
-- object was still there, so B's 0 rows is a denial, not a missing row.
insert into storage.objects (bucket_id, name)
  values ('guide-images', 'c1370000-0000-4000-8000-00000000000a/a1/by-name.jpg');
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is(rls_test.affected(
  $$delete from storage.objects
     where bucket_id = 'guide-images'
       and name = 'c1370000-0000-4000-8000-00000000000a/a1/by-name.jpg'$$),
  0, 'guide_images_delete: B cannot delete A''s image by name');
set local request.jwt.claims = '{"sub":"c1370000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(rls_test.affected(
  $$delete from storage.objects
     where bucket_id = 'guide-images'
       and name = 'c1370000-0000-4000-8000-00000000000a/a1/by-name.jpg'$$),
  1, 'guide_images_delete: A can delete their own image by name');
reset role;

select * from finish();
rollback;
