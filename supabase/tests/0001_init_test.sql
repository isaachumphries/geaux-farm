-- pgTAP cases for 0001_init.sql: the six cases in issue #46 § Tests.
-- Each case runs inside its own savepoint so the cases stay independent.
-- No network access; everything runs against the local stack.

begin;

create extension if not exists pgtap with schema extensions;
set search_path = extensions, public, pg_catalog;

select plan(11);

-- -------------------------------------------------------------- fixture
-- Members A and B, reporter C, and one published guide written by A.

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'c@example.test');

insert into public.profiles (id, username, display_name) values
  ('11111111-1111-1111-1111-111111111111', 'member_a', 'Member A'),
  ('22222222-2222-2222-2222-222222222222', 'member_b', 'Member B'),
  ('33333333-3333-3333-3333-333333333333', 'member_c', 'Member C');

insert into public.guides (id, author_id, title, summary, status) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '11111111-1111-1111-1111-111111111111',
   'Balcony herb box', 'A starter herb box for a sunny balcony.', 'published');

-- A stars their own guide, so case 2 has someone else's star to attack.
insert into public.guide_stars (user_id, guide_id) values
  ('11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

create or replace function act_as(uid text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end;
$$;

-- ------------------------------------------- 1. anon cannot insert guides

savepoint case_1;
select set_config('request.jwt.claims', '', true);
set local role anon;

select throws_ok(
  $$insert into public.guides (author_id, title, summary)
    values ('11111111-1111-1111-1111-111111111111', 'Anon guide', 'nope')$$,
  '42501',
  null,
  'case 1: anon is refused insert on guides'
);

reset role;
rollback to savepoint case_1;

-- --------------------------- 2. B cannot touch A's guide or A's star

savepoint case_2;
select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;

update public.guides set title = 'hijacked by B'
 where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
delete from public.guides
 where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
delete from public.guide_stars
 where user_id = '11111111-1111-1111-1111-111111111111'
   and guide_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

reset role;

select is(
  (select title from public.guides where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Balcony herb box',
  'case 2: B''s update of A''s guide changed nothing'
);
select is(
  (select count(*)::int from public.guides
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  'case 2: B''s delete of A''s guide removed nothing'
);
select is(
  (select count(*)::int from public.guide_stars
    where user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'case 2: B''s delete of A''s star removed nothing'
);

rollback to savepoint case_2;

-- ------------------------------ 3. a client cannot write star_count

savepoint case_3;
select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;

select throws_ok(
  $$update public.guides set star_count = 999
     where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  '42501',
  null,
  'case 3: authenticated has no column grant on star_count'
);

reset role;
rollback to savepoint case_3;

-- --------------------------- 4. star insert / delete move the counter

savepoint case_4;
select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;

insert into public.guide_stars (user_id, guide_id)
values ('22222222-2222-2222-2222-222222222222',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
reset role;

select is(
  (select star_count from public.guides
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  2,
  'case 4: star insert moved star_count +1'
);

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;
delete from public.guide_stars
 where user_id = '22222222-2222-2222-2222-222222222222'
   and guide_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
reset role;

select is(
  (select star_count from public.guides
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  'case 4: star delete moved star_count -1'
);

rollback to savepoint case_4;

-- ------------- 5. three reports hide the guide, and the author is stuck

savepoint case_5;

select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111', 'spam');
reset role;

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '22222222-2222-2222-2222-222222222222', 'unsafe');
reset role;

select act_as('33333333-3333-3333-3333-333333333333');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '33333333-3333-3333-3333-333333333333', 'offensive');
reset role;

select is(
  (select status from public.guides
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'hidden',
  'case 5: the third report hid the guide'
);

-- The author tries to publish it again; the update policy excludes hidden rows.
select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;
update public.guides set status = 'published'
 where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
reset role;

select is(
  (select status from public.guides
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'hidden',
  'case 5: the author cannot lift the hidden status'
);

rollback to savepoint case_5;

-- ------------------------ 6. guide_feed shows published rows only

savepoint case_6;

insert into public.guides (id, author_id, title, summary, status) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   '11111111-1111-1111-1111-111111111111',
   'Draft bed plan', 'Still being written.', 'draft');

update public.guides set status = 'hidden'
 where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

insert into public.guides (id, author_id, title, summary, status) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc',
   '22222222-2222-2222-2222-222222222222',
   'Patio tomatoes', 'Two pots and a stake.', 'published');

select is(
  (select count(*)::int from public.guide_feed
    where id in ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
                 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')),
  0,
  'case 6: guide_feed hides drafts and hidden guides'
);
select is(
  (select count(*)::int from public.guide_feed
    where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  1,
  'case 6: guide_feed still shows published guides'
);

rollback to savepoint case_6;

select * from finish();
rollback;
