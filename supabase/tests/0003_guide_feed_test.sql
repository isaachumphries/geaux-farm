-- guide_feed ranking inputs and visibility (plan/07 § Feed and ranking,
-- § Moderation). now() is fixed for the whole transaction, so stars dated
-- relative to it sit exactly on the 7-day Trending boundary.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

insert into auth.users (id, email) values
  ('f0000000-0000-0000-0000-000000000001', 'feed_author@example.test'),
  ('f0000000-0000-0000-0000-000000000002', 'feed_fan_a@example.test'),
  ('f0000000-0000-0000-0000-000000000003', 'feed_fan_b@example.test'),
  ('f0000000-0000-0000-0000-000000000004', 'feed_fan_c@example.test');

insert into public.profiles (id, username) values
  ('f0000000-0000-0000-0000-000000000001', 'feed_author'),
  ('f0000000-0000-0000-0000-000000000002', 'feed_fan_a'),
  ('f0000000-0000-0000-0000-000000000003', 'feed_fan_b'),
  ('f0000000-0000-0000-0000-000000000004', 'feed_fan_c');

-- g1 old favorite, g2 fresh pick, g3 starred 1 s inside the window,
-- g4 starred exactly 7 days ago, g5 reported, g6 a draft.
insert into public.guides (id, author_id, title, summary, difficulty, status) values
  ('f1000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001',
   'Old favorite planter', 'Starred long ago.', 1, 'published'),
  ('f1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001',
   'Fresh pick trellis', 'Starred this hour.', 1, 'published'),
  ('f1000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000001',
   'Edge inside bed', 'Starred just inside the window.', 1, 'published'),
  ('f1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000001',
   'Edge exact bed', 'Starred exactly 7 days ago.', 1, 'published'),
  ('f1000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000001',
   'Reported herb box', 'Gets reported.', 1, 'published'),
  ('f1000000-0000-0000-0000-000000000006', 'f0000000-0000-0000-0000-000000000001',
   'Unfinished draft bed', 'Not published yet.', 1, 'draft');

-- Distinct publish times so the Top and New tie-breaks are decided.
update public.guides set published_at = now() - (d || ' days')::interval
  from (values ('f1000000-0000-0000-0000-000000000001'::uuid, 60),
               ('f1000000-0000-0000-0000-000000000002'::uuid, 2),
               ('f1000000-0000-0000-0000-000000000003'::uuid, 10),
               ('f1000000-0000-0000-0000-000000000004'::uuid, 20)) as p(gid, d)
 where id = p.gid;

insert into public.guide_stars (user_id, guide_id, created_at) values
  ('f0000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000001', now() - interval '30 days'),
  ('f0000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000001', now() - interval '30 days'),
  ('f0000000-0000-0000-0000-000000000004', 'f1000000-0000-0000-0000-000000000001', now() - interval '30 days'),
  ('f0000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000002', now() - interval '1 hour'),
  ('f0000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000002', now() - interval '1 hour'),
  ('f0000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000003', now() - interval '7 days' + interval '1 second'),
  ('f0000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000004', now() - interval '7 days');

-- stars_7d: stars in the last 7 days only.
select is((select stars_7d from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000003'),
  1, 'stars_7d counts a star 7 days minus 1 second old');
select is((select stars_7d from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000004'),
  0, 'stars_7d excludes a star exactly 7 days old');
select is(
  (select array[star_count, stars_7d] from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000001'),
  array[3, 0], 'stars older than 7 days still count in star_count, not stars_7d');
select is((select stars_7d from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000005'),
  0, 'a guide with no stars has stars_7d 0, not null');

-- The three tabs, as guide_feed_request.dart orders them.
select results_eq(
  $$select id from public.guide_feed
     where author_id = 'f0000000-0000-0000-0000-000000000001' and star_count > 0
     order by star_count desc, published_at desc$$,
  $$values ('f1000000-0000-0000-0000-000000000001'::uuid),
           ('f1000000-0000-0000-0000-000000000002'::uuid),
           ('f1000000-0000-0000-0000-000000000003'::uuid),
           ('f1000000-0000-0000-0000-000000000004'::uuid)$$,
  'Top: most stars first, newer first on a tie');
select results_eq(
  $$select id from public.guide_feed
     where author_id = 'f0000000-0000-0000-0000-000000000001' and star_count > 0
     order by stars_7d desc, star_count desc$$,
  $$values ('f1000000-0000-0000-0000-000000000002'::uuid),
           ('f1000000-0000-0000-0000-000000000003'::uuid),
           ('f1000000-0000-0000-0000-000000000001'::uuid),
           ('f1000000-0000-0000-0000-000000000004'::uuid)$$,
  'Trending: this week''s stars first, all-time stars break ties');
select results_eq(
  $$select id from public.guide_feed
     where author_id = 'f0000000-0000-0000-0000-000000000001' and star_count > 0
     order by published_at desc$$,
  $$values ('f1000000-0000-0000-0000-000000000002'::uuid),
           ('f1000000-0000-0000-0000-000000000003'::uuid),
           ('f1000000-0000-0000-0000-000000000004'::uuid),
           ('f1000000-0000-0000-0000-000000000001'::uuid)$$,
  'New: latest published first');

-- Moderation: the 3rd distinct report hides the guide from the feed.
insert into public.guide_reports (guide_id, reporter_id, reason) values
  ('f1000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000002', 'spam'),
  ('f1000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000003', 'other');
set local role anon;
select is((select report_count from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000005'),
  2, 'two reports: the guide is still in guide_feed');
reset role;
insert into public.guide_reports (guide_id, reporter_id, reason) values
  ('f1000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000004', 'unsafe');
set local role anon;
select is((select count(*)::int from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000005'),
  0, 'the third report removes the guide from guide_feed');
reset role;

-- Signed in, the author still reads their hidden guide (to see "Hidden
-- pending review") and their draft, but neither through the feed; RLS alone
-- hides both from everyone else.
set local role authenticated;
set local request.jwt.claims = '{"sub":"f0000000-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select status from public.guides where id = 'f1000000-0000-0000-0000-000000000005'),
  'hidden', 'the author can still read their hidden guide');
select is((select count(*)::int from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000005'),
  0, 'the author''s own hidden guide is not in their feed either');
select is((select count(*)::int from public.guide_feed where id = 'f1000000-0000-0000-0000-000000000006'),
  0, 'the author''s own draft is not in their feed');
reset role;

select * from finish();
rollback;
