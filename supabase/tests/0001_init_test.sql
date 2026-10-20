begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

-- Fixtures. Inserted as postgres (bypasses RLS); triggers still run.
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'author@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'user_b@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'user_c@example.test'),
  ('44444444-4444-4444-4444-444444444444', 'user_d@example.test');

insert into public.profiles (id, username) values
  ('11111111-1111-1111-1111-111111111111', 'author_a'),
  ('22222222-2222-2222-2222-222222222222', 'user_b'),
  ('33333333-3333-3333-3333-333333333333', 'user_c'),
  ('44444444-4444-4444-4444-444444444444', 'user_d');

insert into public.guides (id, author_id, title, summary, difficulty, status) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'Kale starter bed', 'A simple kale bed.', 1, 'published'),
  ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   'Draft herb wall', 'Still drafting.', 2, 'draft'),
  ('aaaaaaaa-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'Reported bean trellis', 'Will be reported.', 2, 'published');

-- Case 1: anon cannot insert guides.
set local role anon;
select throws_ok(
  $$insert into public.guides (author_id, title, summary, difficulty)
    values ('11111111-1111-1111-1111-111111111111', 'Anon guide', 'Anon summary.', 1)$$,
  '42501', 'permission denied for table guides',
  'Case 1: anon cannot insert guides');
reset role;

-- Case 2: user B cannot update or delete author A's guide (0 rows, no error).
-- Positive control: author A can update their own published guide (1 row),
-- so the 0-row checks cannot pass by accident under deny-all policies.
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
do $$
declare n int;
begin
  update public.guides set title = 'Hijacked title'
   where id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
select is(current_setting('test.rows')::int, 0, 'Case 2: user B cannot update A''s guide');
do $$
declare n int;
begin
  delete from public.guides
   where id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
select is(current_setting('test.rows')::int, 0, 'Case 2: user B cannot delete A''s guide');
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
do $$
declare n int;
begin
  update public.guides set summary = 'Updated kale summary.'
   where id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
reset role;
select is(current_setting('test.rows')::int, 1, 'Case 2: author can update own published guide');
select is((select title from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'Kale starter bed', 'Case 2: A''s title is unchanged');
select is((select count(*)::int from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1, 'Case 2: A''s guide still exists');

-- Case 2 (stars): user B cannot delete author A's star (0 rows, no error).
-- A then deletes that star again, so Case 4 still starts from star_count 0.
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
insert into public.guide_stars (user_id, guide_id)
  values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001');
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
do $$
declare n int;
begin
  delete from public.guide_stars
   where user_id = '11111111-1111-1111-1111-111111111111'
     and guide_id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
select is(current_setting('test.rows')::int, 0, 'Case 2: user B cannot delete A''s star');
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
do $$
declare n int;
begin
  delete from public.guide_stars
   where user_id = '11111111-1111-1111-1111-111111111111'
     and guide_id = 'aaaaaaaa-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
reset role;
select is(current_setting('test.rows')::int, 1, 'Case 2: author can delete own star (positive control)');

-- Case 3: authenticated cannot write star_count (column grant).
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok(
  $$update public.guides set star_count = 99 where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  '42501', 'permission denied for table guides',
  'Case 3: authenticated cannot set star_count');
reset role;

-- Case 4: star insert gives +1; star delete gives -1.
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
insert into public.guide_stars (user_id, guide_id)
  values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000001');
reset role;
select is((select star_count from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1, 'Case 4: star insert raises star_count to 1');
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
delete from public.guide_stars
  where user_id = '22222222-2222-2222-2222-222222222222'
    and guide_id = 'aaaaaaaa-0000-0000-0000-000000000001';
reset role;
select is((select star_count from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  0, 'Case 4: star delete lowers star_count to 0');

-- Case 5: three distinct reports hide the guide; author cannot republish it.
set local role authenticated;
set local request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
insert into public.guide_reports (guide_id, reporter_id, reason)
  values ('aaaaaaaa-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'spam');
set local request.jwt.claims = '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}';
insert into public.guide_reports (guide_id, reporter_id, reason)
  values ('aaaaaaaa-0000-0000-0000-000000000003', '44444444-4444-4444-4444-444444444444', 'spam');
reset role;
-- Two reports are below apply_report's threshold, so the guide must still be
-- published here. Without this the suite only proves three reports are enough,
-- never that fewer are not: lowering the threshold to 2, or even 1, left every
-- assertion green.
select is((select status from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000003'),
  'published', 'Case 5: two reports leave the guide published');
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
insert into public.guide_reports (guide_id, reporter_id, reason)
  values ('aaaaaaaa-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'spam');
reset role;
select is((select status from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000003'),
  'hidden', 'Case 5: three reports hide the guide');
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
do $$
declare n int;
begin
  update public.guides set status = 'published'
   where id = 'aaaaaaaa-0000-0000-0000-000000000003';
  get diagnostics n = row_count;
  perform set_config('test.rows', n::text, true);
end $$;
reset role;
select is(current_setting('test.rows')::int, 0, 'Case 5: author cannot republish a hidden guide');
select is((select status from public.guides where id = 'aaaaaaaa-0000-0000-0000-000000000003'),
  'hidden', 'Case 5: guide status stays hidden');

-- Case 6: guide_feed shows published guides only.
set local role anon;
select is((select count(*)::int from public.guide_feed
            where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1, 'Case 6: published guide appears in guide_feed');
select is((select count(*)::int from public.guide_feed
            where id in ('aaaaaaaa-0000-0000-0000-000000000002',
                         'aaaaaaaa-0000-0000-0000-000000000003')),
  0, 'Case 6: drafts and hidden guides are excluded from guide_feed');
reset role;

select * from finish();
rollback;
