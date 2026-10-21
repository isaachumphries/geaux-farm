-- Local board schema, grants and RLS (plan/08 § Schema, 0002_local.sql).
-- Every deny check has a matching allow check for the same role and table,
-- so a deny-all policy, or RLS left off, fails the suite instead of
-- passing it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

-- Runs a statement under the current role and returns how many rows it
-- touched. RLS filters UPDATE/DELETE silently (0 rows, no error), so row
-- counts are what tell "denied" apart from "allowed".
create schema local_test;
grant usage on schema local_test to anon, authenticated;
create function local_test.affected(q text) returns int
language plpgsql as $$
declare n int;
begin
  execute q;
  get diagnostics n = row_count;
  return n;
end $$;

-- Fixtures, inserted as postgres (bypasses RLS). A owns the posts, B is a
-- neighbour, C and D only report.
insert into auth.users (id, email) values
  ('10ca1000-0000-4000-8000-00000000000a', 'local_a@example.test'),
  ('10ca1000-0000-4000-8000-00000000000b', 'local_b@example.test'),
  ('10ca1000-0000-4000-8000-00000000000c', 'local_c@example.test'),
  ('10ca1000-0000-4000-8000-00000000000d', 'local_d@example.test');

insert into public.profiles (id, username) values
  ('10ca1000-0000-4000-8000-00000000000a', 'local_a'),
  ('10ca1000-0000-4000-8000-00000000000b', 'local_b'),
  ('10ca1000-0000-4000-8000-00000000000c', 'local_c'),
  ('10ca1000-0000-4000-8000-00000000000d', 'local_d');

insert into public.local_posts
  (id, author_id, kind, title, body, lat_round, lon_round, area_label, status)
values
  ('10ca1000-0000-4000-8000-0000000000a1',
   '10ca1000-0000-4000-8000-00000000000a', 'offer_seeds',
   'Okra seeds to share', 'Plenty spare.', 30.5, -91.2, 'Baton Rouge', 'open'),
  ('10ca1000-0000-4000-8000-0000000000a2',
   '10ca1000-0000-4000-8000-00000000000a', 'question',
   'Will be reported', 'Three reports hide this.', 30.5, -91.2, 'Baton Rouge',
   'open'),
  ('10ca1000-0000-4000-8000-0000000000a3',
   '10ca1000-0000-4000-8000-00000000000a', 'tip',
   'A closed post', 'Already taken.', 30.5, -91.2, 'Baton Rouge', 'closed'),
  ('10ca1000-0000-4000-8000-0000000000a4',
   '10ca1000-0000-4000-8000-00000000000a', 'tip',
   'A post to delete', 'Deleted by its author.', 30.5, -91.2, 'Baton Rouge',
   'open');

insert into public.local_replies (id, post_id, author_id, body) values
  ('10ca1000-0000-4000-8000-0000000000e1',
   '10ca1000-0000-4000-8000-0000000000a1',
   '10ca1000-0000-4000-8000-00000000000a', 'A''s own reply.');

-- ---------------------------------------------------------------------------
-- local_posts: open posts are public; writing needs to be you.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok(
  $$insert into public.local_posts
      (author_id, kind, title, body, lat_round, lon_round, area_label)
    values ('10ca1000-0000-4000-8000-00000000000a', 'tip', 'Anon post',
            'No account.', 30.5, -91.2, 'Baton Rouge')$$,
  '42501', null, 'local_posts_insert: anon cannot post');
select is((select count(*)::int from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a1'),
  1, 'local_posts_read: anon sees an open post');
select is((select count(*)::int from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a3'),
  0, 'local_posts_read: anon cannot see a closed post');

set local role authenticated;
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000b","role":"authenticated"}';
select lives_ok(
  $$insert into public.local_posts
      (author_id, kind, title, body, lat_round, lon_round, area_label)
    values ('10ca1000-0000-4000-8000-00000000000b', 'want_seeds',
            'Looking for okra', 'Happy to swap.', 30.5, -91.2, 'Baton Rouge')$$,
  'local_posts_insert: B can post as themselves');
select throws_ok(
  $$insert into public.local_posts
      (author_id, kind, title, body, lat_round, lon_round, area_label)
    values ('10ca1000-0000-4000-8000-00000000000a', 'tip', 'Posted as A',
            'Id spoofing.', 30.5, -91.2, 'Baton Rouge')$$,
  '42501', null, 'local_posts_insert: B cannot post as A');
select throws_ok(
  $$insert into public.local_posts
      (author_id, kind, title, body, lat_round, lon_round, area_label, status)
    values ('10ca1000-0000-4000-8000-00000000000b', 'tip', 'Born hidden',
            'Clients cannot hide.', 30.5, -91.2, 'Baton Rouge', 'hidden')$$,
  '42501', null, 'local_posts_insert: a client cannot insert status hidden');
select throws_ok(
  $$update public.local_posts set report_count = 99
     where id = '10ca1000-0000-4000-8000-0000000000a1'$$,
  '42501', null, 'local_posts: a client cannot write report_count');

-- B against A's post.
select is(local_test.affected(
  $$update public.local_posts set title = 'Hijacked'
     where id = '10ca1000-0000-4000-8000-0000000000a1'$$),
  0, 'local_posts_update: B cannot update A''s post');
select is(local_test.affected(
  $$delete from public.local_posts
     where id = '10ca1000-0000-4000-8000-0000000000a1'$$),
  0, 'local_posts_delete: B cannot delete A''s post');

-- A against their own.
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(local_test.affected(
  $$update public.local_posts set title = 'Okra seeds to share (updated)'
     where id = '10ca1000-0000-4000-8000-0000000000a1'$$),
  1, 'local_posts_update: A can update their own post');
select is(local_test.affected(
  $$delete from public.local_posts
     where id = '10ca1000-0000-4000-8000-0000000000a4'$$),
  1, 'local_posts_delete: A can delete their own post');
select is((select count(*)::int from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a3'),
  1, 'local_posts_read: A sees their own closed post');
reset role;
select is((select title from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a1'),
  'Okra seeds to share (updated)',
  'local_posts: only A''s own edit reached A''s row');

-- ---------------------------------------------------------------------------
-- local_reports: the third distinct report hides the post.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok(
  $$insert into public.local_reports (post_id, reporter_id, reason)
    values ('10ca1000-0000-4000-8000-0000000000a2',
            '10ca1000-0000-4000-8000-00000000000c', 'spam')$$,
  '42501', null, 'local_reports_insert: anon cannot report');

set local role authenticated;
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000c","role":"authenticated"}';
insert into public.local_reports (post_id, reporter_id, reason)
  values ('10ca1000-0000-4000-8000-0000000000a2',
          '10ca1000-0000-4000-8000-00000000000c', 'spam');
select throws_ok(
  $$insert into public.local_reports (post_id, reporter_id, reason)
    values ('10ca1000-0000-4000-8000-0000000000a2',
            '10ca1000-0000-4000-8000-00000000000d', 'spam')$$,
  '42501', null, 'local_reports_insert: C cannot report as D');
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000d","role":"authenticated"}';
insert into public.local_reports (post_id, reporter_id, reason)
  values ('10ca1000-0000-4000-8000-0000000000a2',
          '10ca1000-0000-4000-8000-00000000000d', 'spam');
reset role;
select is((select report_count from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a2'),
  2, 'apply_local_report: two reports count');
select is((select status from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a2'),
  'open', 'apply_local_report: two reports leave the post open');

set local role authenticated;
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000b","role":"authenticated"}';
insert into public.local_reports (post_id, reporter_id, reason)
  values ('10ca1000-0000-4000-8000-0000000000a2',
          '10ca1000-0000-4000-8000-00000000000b', 'spam');
select throws_ok(
  $$insert into public.local_reports (post_id, reporter_id, reason)
    values ('10ca1000-0000-4000-8000-0000000000a2',
            '10ca1000-0000-4000-8000-00000000000b', 'offensive')$$,
  '23505', null, 'local_reports: one report per user per post');
reset role;
select is((select report_count from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a2'),
  3, 'apply_local_report: the third report counts');
select is((select status from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a2'),
  'hidden', 'apply_local_report: three reports hide the post');

-- The author cannot bring a hidden post back.
set local role authenticated;
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(local_test.affected(
  $$update public.local_posts set status = 'open'
     where id = '10ca1000-0000-4000-8000-0000000000a2'$$),
  0, 'local_posts_update: the author cannot reopen a hidden post');
reset role;
select is((select status from public.local_posts
            where id = '10ca1000-0000-4000-8000-0000000000a2'),
  'hidden', 'local_posts: the post stays hidden');

-- ---------------------------------------------------------------------------
-- local_replies: readable by everyone, written only as yourself.
-- ---------------------------------------------------------------------------
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select is((select count(*)::int from public.local_replies
            where id = '10ca1000-0000-4000-8000-0000000000e1'),
  1, 'local_replies_read: anon can read replies');
select throws_ok(
  $$insert into public.local_replies (post_id, author_id, body)
    values ('10ca1000-0000-4000-8000-0000000000a1',
            '10ca1000-0000-4000-8000-00000000000a', 'Anon reply.')$$,
  '42501', null, 'local_replies_insert: anon cannot reply');

set local role authenticated;
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000b","role":"authenticated"}';
select lives_ok(
  $$insert into public.local_replies (post_id, author_id, body)
    values ('10ca1000-0000-4000-8000-0000000000a1',
            '10ca1000-0000-4000-8000-00000000000b', 'B''s reply.')$$,
  'local_replies_insert: B can reply as themselves');
select throws_ok(
  $$insert into public.local_replies (post_id, author_id, body)
    values ('10ca1000-0000-4000-8000-0000000000a1',
            '10ca1000-0000-4000-8000-00000000000a', 'Reply as A.')$$,
  '42501', null, 'local_replies_insert: B cannot reply as A');
select is(local_test.affected(
  $$delete from public.local_replies
     where id = '10ca1000-0000-4000-8000-0000000000e1'$$),
  0, 'local_replies_delete: B cannot delete A''s reply');
set local request.jwt.claims = '{"sub":"10ca1000-0000-4000-8000-00000000000a","role":"authenticated"}';
select is(local_test.affected(
  $$delete from public.local_replies
     where id = '10ca1000-0000-4000-8000-0000000000e1'$$),
  1, 'local_replies_delete: A can delete their own reply');
reset role;

select * from finish();
rollback;
