begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

-- Runs against the data `supabase db reset` loaded from supabase/seed.sql.
-- Read-only: nothing here writes, and the transaction is rolled back anyway.

create temp view seed_guides as
select g.*
  from public.guides g
  join public.profiles p on p.id = g.author_id
 where p.username = 'geauxfarm';

-- Plant catalog ids (assets/plants/plants.json). test/community/seed_sql_test.dart
-- fails if this list drifts from the file.
create temp table catalog_ids (id text primary key);
insert into catalog_ids (id) values
    ('kale'),
    ('collard-greens'),
    ('swiss-chard'),
    ('spinach'),
    ('lettuce'),
    ('radish'),
    ('bell-pepper'),
    ('bush-bean'),
    ('carrot'),
    ('okra'),
    ('microgreens'),
    ('green-onion'),
    ('cherry-tomato'),
    ('sweet-basil'),
    ('english-lavender'),
    ('thyme'),
    ('oregano'),
    ('parsley'),
    ('mint'),
    ('rosemary'),
    ('marigold'),
    ('zinnia'),
    ('cosmos'),
    ('purple-coneflower'),
    ('black-eyed-susan'),
    ('strawberry'),
    ('satsuma'),
    ('azalea'),
    ('pothos'),
    ('snake-plant');;

select is((select count(*)::int from public.profiles where username = 'geauxfarm'), 1,
  'the geauxfarm profile exists once');

select is((select count(*)::int from seed_guides), 10,
  'exactly 10 guides are authored by geauxfarm');

select is((select count(*)::int from seed_guides where status = 'published'), 10,
  'all 10 seed guides are published');

select is((select count(*)::int from seed_guides where published_at is null), 0,
  'the insert trigger set published_at on every seed guide');

select set_eq(
  $$select title from seed_guides$$,
  $$values ('5-gallon bucket cherry tomatoes'),
           ('Pallet vertical herb wall'),
           ('Balcony salad box'),
           ('Windowsill microgreens tray'),
           ('4×4 square-foot raised bed'),
           ('Pollinator patch for small yards'),
           ('Kratky hydroponic lettuce (no pump)'),
           ('Self-watering bottle planters'),
           ('Fall greens for Louisiana'),
           ('Compost bin from a storage tote')$$,
  'seed guide titles match plan 07 exactly');

select is((select count(*)::int from seed_guides
            where char_length(title) not between 5 and 80
               or char_length(summary) not between 1 and 280
               or difficulty not between 1 and 3
               or est_cost_usd is null or est_cost_usd < 0
               or setup_minutes is null or setup_minutes < 0
               or forked_from is not null
               or cover_path is not null),
  0, 'scalar field rules hold (title, summary, difficulty, cost, minutes, forked_from, cover_path)');

select is((select count(*)::int from seed_guides
            where cardinality(space_types) < 1
               or not (space_types <@ array['windowsill','balcony','smallYard','largeYard','communityPlot'])),
  0, 'space_types: at least 1, all valid SpaceType names');

select is((select count(*)::int from seed_guides
            where cardinality(tags) > 5
               or not (tags <@ array['vertical','containers','raised-bed','hydroponic','budget',
                                     'kids','pollinators','upcycled','indoor','louisiana'])),
  0, 'tags: at most 5, all from the fixed list');

select is((select count(*)::int from seed_guides
            where jsonb_typeof(materials) is distinct from 'array'
               or jsonb_array_length(materials) not between 1 and 30),
  0, 'materials: an array of 1-30 items');

select is((select count(*)::int
             from seed_guides g, jsonb_array_elements(g.materials) m
            where jsonb_typeof(m) is distinct from 'object'
               or (select count(*) from jsonb_object_keys(m)) <> 4
               or not (m ?& array['name','qty','estCostUsd','url'])
               or jsonb_typeof(m->'name') is distinct from 'string'
               or char_length(m->>'name') = 0
               or jsonb_typeof(m->'qty') is distinct from 'string'
               or jsonb_typeof(m->'estCostUsd') not in ('number','null')
               or (jsonb_typeof(m->'estCostUsd') = 'number' and (m->>'estCostUsd') !~ '^[0-9]+$')
               or jsonb_typeof(m->'url') not in ('string','null')),
  0, 'materials items: {name, qty string, estCostUsd int|null, url string|null}');

select is((select count(*)::int from seed_guides
            where jsonb_typeof(steps) is distinct from 'array'
               or jsonb_array_length(steps) not between 1 and 20),
  0, 'steps: an array of 1-20 items');

select is((select count(*)::int
             from seed_guides g, jsonb_array_elements(g.steps) s
            where jsonb_typeof(s) is distinct from 'object'
               or (select count(*) from jsonb_object_keys(s)) <> 3
               or not (s ?& array['title','body','imagePath'])
               or jsonb_typeof(s->'title') is distinct from 'string'
               or char_length(s->>'title') = 0
               or jsonb_typeof(s->'body') is distinct from 'string'
               or char_length(s->>'body') not between 1 and 1000
               or jsonb_typeof(s->'imagePath') is distinct from 'null'),
  0, 'steps items: {title, body <= 1000 chars, imagePath null}');

select is((select count(*)::int from seed_guides where cardinality(plant_ids) > 10),
  0, 'plant_ids: at most 10');

select is((select count(*)::int
             from seed_guides g, unnest(g.plant_ids) pid
            where pid not in (select id from catalog_ids)),
  0, 'every plant_ids entry is a catalog id');

select is((select plant_ids from seed_guides where title = 'Fall greens for Louisiana'),
  array['kale','collard-greens','swiss-chard','spinach'],
  'Fall greens for Louisiana lists kale, collard-greens, swiss-chard, spinach');

select is((select count(*)::int from seed_guides where title = 'Compost bin from a storage tote'
              and plant_ids = '{}'),
  1, 'the compost bin guide has no plants');

select is((select count(*)::int from public.guide_feed where author_username = 'geauxfarm'), 10,
  'all 10 seed guides appear in guide_feed');

select * from finish();
rollback;
