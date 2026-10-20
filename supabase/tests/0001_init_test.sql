-- pgTAP cases for 0001_init.sql: the six cases in issue #46 § Tests, as 12
-- assertions (case 5 also probes the two-report boundary).
-- No network access; everything runs against the local stack.
--
-- Cases are isolated by fixture, not by savepoint: each case owns the guide it
-- mutates and every assertion is scoped to that guide's id. Savepoints cannot
-- be used here, because `rollback to savepoint` also rewinds the temp tables
-- pgTAP keeps its test counter in, which leaves finish() reporting
-- "No tests run!" even when every assertion passed.

begin;

create extension if not exists pgtap with schema extensions;
set search_path = extensions, public, pg_catalog;

select plan(12);

-- -------------------------------------------------------------- fixture
-- Members A and B plus reporter C, and one guide per case that mutates one.

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'a@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'b@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'c@example.test');

insert into public.profiles (id, username, display_name) values
  ('11111111-1111-1111-1111-111111111111', 'member_a', 'Member A'),
  ('22222222-2222-2222-2222-222222222222', 'member_b', 'Member B'),
  ('33333333-3333-3333-3333-333333333333', 'member_c', 'Member C');

insert into public.guides (id, author_id, title, summary, status) values
  ('00000002-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Balcony herb box', 'A starter herb box for a sunny balcony.', 'published'),
  ('00000003-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Counter sprouts', 'A jar of sprouts by the sink.', 'published'),
  ('00000004-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Window lettuce', 'Cut-and-come-again in a sunny window.', 'published'),
  ('00000005-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Porch peppers', 'Two pots of peppers on a hot porch.', 'published'),
  ('00000060-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Draft bed plan', 'Still being written.', 'draft'),
  ('00000061-0000-4000-8000-000000000000',
   '11111111-1111-1111-1111-111111111111',
   'Pulled guide', 'Taken down by moderation.', 'published'),
  ('00000062-0000-4000-8000-000000000000',
   '22222222-2222-2222-2222-222222222222',
   'Patio tomatoes', 'Two pots and a stake.', 'published');

-- A stars their own case-2 guide, so case 2 has someone else's star to attack.
insert into public.guide_stars (user_id, guide_id) values
  ('11111111-1111-1111-1111-111111111111',
   '00000002-0000-4000-8000-000000000000');

create or replace function act_as(uid text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end;
$$;

-- ------------------------------------------- 1. anon cannot insert guides

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

-- --------------------------- 2. B cannot touch A's guide or A's star

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;

update public.guides set title = 'hijacked by B'
 where id = '00000002-0000-4000-8000-000000000000';
delete from public.guides
 where id = '00000002-0000-4000-8000-000000000000';
delete from public.guide_stars
 where user_id = '11111111-1111-1111-1111-111111111111'
   and guide_id = '00000002-0000-4000-8000-000000000000';

reset role;

select is(
  (select title from public.guides
    where id = '00000002-0000-4000-8000-000000000000'),
  'Balcony herb box',
  'case 2: B''s update of A''s guide changed nothing'
);
select is(
  (select count(*)::int from public.guides
    where id = '00000002-0000-4000-8000-000000000000'),
  1,
  'case 2: B''s delete of A''s guide removed nothing'
);
select is(
  (select count(*)::int from public.guide_stars
    where user_id = '11111111-1111-1111-1111-111111111111'
      and guide_id = '00000002-0000-4000-8000-000000000000'),
  1,
  'case 2: B''s delete of A''s star removed nothing'
);

-- ------------------------------ 3. a client cannot write star_count

select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;

select throws_ok(
  $$update public.guides set star_count = 999
     where id = '00000003-0000-4000-8000-000000000000'$$,
  '42501',
  null,
  'case 3: authenticated has no column grant on star_count'
);

reset role;

-- --------------------------- 4. star insert / delete move the counter

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;

insert into public.guide_stars (user_id, guide_id)
values ('22222222-2222-2222-2222-222222222222',
        '00000004-0000-4000-8000-000000000000');
reset role;

select is(
  (select star_count from public.guides
    where id = '00000004-0000-4000-8000-000000000000'),
  1,
  'case 4: star insert moved star_count +1'
);

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;
delete from public.guide_stars
 where user_id = '22222222-2222-2222-2222-222222222222'
   and guide_id = '00000004-0000-4000-8000-000000000000';
reset role;

select is(
  (select star_count from public.guides
    where id = '00000004-0000-4000-8000-000000000000'),
  0,
  'case 4: star delete moved star_count -1'
);

-- ------------- 5. three reports hide the guide, and the author is stuck

select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('00000005-0000-4000-8000-000000000000',
        '11111111-1111-1111-1111-111111111111', 'spam');
reset role;

select act_as('22222222-2222-2222-2222-222222222222');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('00000005-0000-4000-8000-000000000000',
        '22222222-2222-2222-2222-222222222222', 'unsafe');
reset role;

-- Still two reports: the guide must not be hidden yet.
select is(
  (select status from public.guides
    where id = '00000005-0000-4000-8000-000000000000'),
  'published',
  'case 5: two reports leave the guide published'
);

select act_as('33333333-3333-3333-3333-333333333333');
set local role authenticated;
insert into public.guide_reports (guide_id, reporter_id, reason)
values ('00000005-0000-4000-8000-000000000000',
        '33333333-3333-3333-3333-333333333333', 'offensive');
reset role;

select is(
  (select status from public.guides
    where id = '00000005-0000-4000-8000-000000000000'),
  'hidden',
  'case 5: the third report hid the guide'
);

-- The author tries to publish it again; the update policy excludes hidden rows.
select act_as('11111111-1111-1111-1111-111111111111');
set local role authenticated;
update public.guides set status = 'published'
 where id = '00000005-0000-4000-8000-000000000000';
reset role;

select is(
  (select status from public.guides
    where id = '00000005-0000-4000-8000-000000000000'),
  'hidden',
  'case 5: the author cannot lift the hidden status'
);

-- ------------------------ 6. guide_feed shows published rows only

update public.guides set status = 'hidden'
 where id = '00000061-0000-4000-8000-000000000000';

select is(
  (select count(*)::int from public.guide_feed
    where id in ('00000060-0000-4000-8000-000000000000',
                 '00000061-0000-4000-8000-000000000000')),
  0,
  'case 6: guide_feed hides drafts and hidden guides'
);
select is(
  (select count(*)::int from public.guide_feed
    where id = '00000062-0000-4000-8000-000000000000'),
  1,
  'case 6: guide_feed still shows published guides'
);

select * from finish();
rollback;
