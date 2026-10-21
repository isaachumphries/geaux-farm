-- Gate 2 star check (issue #32): a star from user A shows in the count user B
-- reads, and un-starring takes it back. The count is owned by the
-- guide_stars_count trigger; the client can never write it (plan/07 § Star).
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email) values
  ('c1320000-0000-4000-8000-00000000000a', 'star_a@example.test'),
  ('c1320000-0000-4000-8000-00000000000b', 'star_b@example.test');

insert into public.profiles (id, username) values
  ('c1320000-0000-4000-8000-00000000000a', 'star_a'),
  ('c1320000-0000-4000-8000-00000000000b', 'star_b');

insert into public.guides (id, author_id, title, summary, difficulty, status) values
  ('c1320000-0000-4000-8000-0000000000a1', 'c1320000-0000-4000-8000-00000000000b',
   'Star count guide', 'Starred by A, read by B.', 1, 'published');

-- A stars the guide.
set local role authenticated;
set local request.jwt.claims = '{"sub":"c1320000-0000-4000-8000-00000000000a","role":"authenticated"}';
select lives_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1320000-0000-4000-8000-00000000000a', 'c1320000-0000-4000-8000-0000000000a1')$$,
  'A can star the guide');
select throws_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1320000-0000-4000-8000-00000000000a', 'c1320000-0000-4000-8000-0000000000a1')$$,
  '23505', null, 'A cannot star the same guide twice');
select throws_ok(
  $$update public.guides set star_count = 99
     where id = 'c1320000-0000-4000-8000-0000000000a1'$$,
  '42501', null, 'A cannot write star_count');

-- B's device reads the count (and A's star) through guide_feed.
set local request.jwt.claims = '{"sub":"c1320000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is(
  (select star_count from public.guide_feed where id = 'c1320000-0000-4000-8000-0000000000a1'),
  1, 'B reads star_count 1 after A starred');
select is(
  (select count(*)::int from public.guide_stars
    where guide_id = 'c1320000-0000-4000-8000-0000000000a1'
      and user_id = 'c1320000-0000-4000-8000-00000000000a'),
  1, 'B can see A''s guide_stars row');

-- B stars too: the count follows both rows.
select lives_ok(
  $$insert into public.guide_stars (user_id, guide_id)
    values ('c1320000-0000-4000-8000-00000000000b', 'c1320000-0000-4000-8000-0000000000a1')$$,
  'B can star the guide');
select is(
  (select star_count from public.guide_feed where id = 'c1320000-0000-4000-8000-0000000000a1'),
  2, 'star_count is 2 after B starred too');

-- A un-stars: back to B's own star only, then to 0 once B un-stars.
set local request.jwt.claims = '{"sub":"c1320000-0000-4000-8000-00000000000a","role":"authenticated"}';
delete from public.guide_stars
 where user_id = 'c1320000-0000-4000-8000-00000000000a'
   and guide_id = 'c1320000-0000-4000-8000-0000000000a1';
set local request.jwt.claims = '{"sub":"c1320000-0000-4000-8000-00000000000b","role":"authenticated"}';
select is(
  (select star_count from public.guide_feed where id = 'c1320000-0000-4000-8000-0000000000a1'),
  1, 'star_count is 1 after A un-starred');
delete from public.guide_stars
 where user_id = 'c1320000-0000-4000-8000-00000000000b'
   and guide_id = 'c1320000-0000-4000-8000-0000000000a1';
select is(
  (select star_count from public.guide_feed where id = 'c1320000-0000-4000-8000-0000000000a1'),
  0, 'star_count is back to 0 after both un-starred');

select * from finish();
rollback;
