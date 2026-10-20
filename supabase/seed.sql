-- Seed data for local development: the @geauxfarm team account and its 10 guides.
-- `supabase db reset` runs this after the migrations. Made-up content only.
--
-- Team account: guides.author_id references profiles, which references auth.users,
-- so the seed inserts an auth user for @geauxfarm directly. The row has no email,
-- no password, and no identity, so nobody can sign in as it; it only owns the
-- seed guides. The token columns are empty strings, not NULL: GoTrue fails to
-- read auth.users rows that have NULL there. The shared hosted project is never
-- seeded from here (db reset is local-only); the team account there is created
-- by hand in the dashboard.
--
-- Each column value carries a `-- <column>` label so test/community/seed_sql_test.dart
-- can read plant_ids without parsing SQL. Keep the labels when editing.
--
-- Idempotent: fixed ids, and every insert is `on conflict ... do nothing`.

insert into auth.users (
  id, instance_id, aud, role, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token
) values (
  '9e1a0000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', now(), now(),
  '', '', '', '', '', '', '', ''
)
on conflict (id) do nothing;

insert into public.profiles (id, username, display_name, city, zone)
values ('9e1a0000-0000-4000-8000-000000000001', 'geauxfarm', 'Geaux Farm', 'Baton Rouge', '9a')
on conflict (username) do nothing;

-- 1. 5-gallon bucket cherry tomatoes
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a1', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  '5-gallon bucket cherry tomatoes', -- title
  'Grow a heavy-bearing cherry tomato in one food-safe bucket on a patio or balcony, with a basil plant tucked in beside it.', -- summary
  2, -- difficulty
  '{balcony,smallYard}', -- space_types
  38, -- est_cost_usd
  45, -- setup_minutes
  '[
    {"name": "5-gallon food-grade bucket", "qty": "1", "estCostUsd": 5, "url": null},
    {"name": "Potting mix", "qty": "1 bag (20 qt)", "estCostUsd": 10, "url": null},
    {"name": "Cherry tomato transplant", "qty": "1", "estCostUsd": 4, "url": null},
    {"name": "Sweet basil transplant", "qty": "1", "estCostUsd": 3, "url": null},
    {"name": "Tomato cage or 5 ft stake", "qty": "1", "estCostUsd": 8, "url": null},
    {"name": "Slow-release vegetable fertilizer", "qty": "1 small bag", "estCostUsd": 8, "url": null},
    {"name": "Drill with 1/2 inch bit", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Drill drainage holes", "body": "Drill six 1/2 inch holes in the bottom of the bucket and a few more low on the sides. Tomatoes rot quickly in standing water, so do not skip this step.", "imagePath": null},
    {"title": "Fill with potting mix", "body": "Fill the bucket to within 2 inches of the rim with moist potting mix. Mix in the slow-release fertilizer following the bag directions. Use potting mix, not garden soil, which packs down in containers.", "imagePath": null},
    {"title": "Plant the tomato deep", "body": "Pinch off the lowest leaves and set the transplant so that about two thirds of the stem is buried. Tomato stems grow roots, so deep planting gives a sturdier plant. Plant after the last frost.", "imagePath": null},
    {"title": "Add the basil and a support", "body": "Plant the basil near the edge of the bucket. Push the cage or stake in beside the tomato now, before the roots fill the bucket, and tie the stem loosely as it grows.", "imagePath": null},
    {"title": "Water and feed", "body": "Water deeply whenever the top inch of mix feels dry, which in summer heat can be every day. Aim for even moisture to avoid split fruit. Place the bucket where it gets at least 6 hours of direct sun.", "imagePath": null},
    {"title": "Harvest", "body": "Pick the cherry tomatoes when they are fully colored and slightly soft. Harvest often, since picking encourages the plant to keep fruiting, and pinch basil tips to keep it bushy.", "imagePath": null}
  ]'::jsonb, -- steps
  '{cherry-tomato,sweet-basil}', -- plant_ids
  '{containers,budget}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 2. Pallet vertical herb wall
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a2', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Pallet vertical herb wall', -- title
  'Turn a heat-treated wooden pallet into a leaning herb garden that fits against a sunny fence or wall.', -- summary
  2, -- difficulty
  '{balcony,smallYard}', -- space_types
  40, -- est_cost_usd
  150, -- setup_minutes
  '[
    {"name": "Heat-treated wooden pallet (stamped HT)", "qty": "1", "estCostUsd": 0, "url": null},
    {"name": "Landscape fabric", "qty": "1 roll (3 ft wide)", "estCostUsd": 10, "url": null},
    {"name": "Heavy-duty staple gun and staples", "qty": "1", "estCostUsd": null, "url": null},
    {"name": "Potting mix", "qty": "2 bags (20 qt each)", "estCostUsd": 20, "url": null},
    {"name": "Herb transplants", "qty": "5", "estCostUsd": 10, "url": null},
    {"name": "Work gloves and sandpaper", "qty": "1 set", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Choose a safe pallet", "body": "Look for the HT stamp, which means the wood was heat treated. Skip pallets stamped MB, which were treated with a chemical fumigant, and any that are stained or smell of chemicals. Sand rough edges.", "imagePath": null},
    {"title": "Line the back and bottom", "body": "Lay the pallet face down. Staple landscape fabric over the back and across the bottom so soil cannot fall out, folding the fabric into each slot to form a pocket.", "imagePath": null},
    {"title": "Fill the pockets", "body": "Stand the pallet upright against a wall and fill each pocket with potting mix, pressing it in gently. Leave the top boards open so the water can reach every pocket.", "imagePath": null},
    {"title": "Plant by thirst", "body": "Put thirsty herbs such as basil, parsley, and mint in the lower pockets, where water collects. Put thyme and oregano near the top, where the mix drains fastest. Give mint its own pocket, because it spreads aggressively.", "imagePath": null},
    {"title": "Lean it up and water", "body": "Lay the pallet flat for a week so roots settle, watering gently, then stand it in a spot with 6 or more hours of sun. Water from the top until it drips out the bottom, and check daily in summer.", "imagePath": null},
    {"title": "Harvest and trim", "body": "Snip herbs just above a pair of leaves, taking no more than a third at a time. Trim basil flower buds to keep it producing leaves.", "imagePath": null}
  ]'::jsonb, -- steps
  '{sweet-basil,thyme,oregano,parsley,mint}', -- plant_ids
  '{vertical,upcycled,budget}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 3. Balcony salad box
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a3', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Balcony salad box', -- title
  'A shallow window box of quick salad greens, radishes, and green onions that fits a balcony railing and gives harvests within weeks.', -- summary
  1, -- difficulty
  '{balcony,smallYard}', -- space_types
  34, -- est_cost_usd
  40, -- setup_minutes
  '[
    {"name": "Planter box with drainage holes (24 in long, 8 in deep)", "qty": "1", "estCostUsd": 15, "url": null},
    {"name": "Potting mix", "qty": "1 bag (20 qt)", "estCostUsd": 10, "url": null},
    {"name": "Seed packets: lettuce, spinach, radish", "qty": "3", "estCostUsd": 6, "url": null},
    {"name": "Green onion sets or store-bought green onions with roots", "qty": "6", "estCostUsd": 3, "url": null},
    {"name": "Watering can with a rose head", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Pick the season", "body": "These are cool-season crops. In Louisiana, sow them from October through February. Salad greens bolt and turn bitter once highs stay above the low 80s.", "imagePath": null},
    {"title": "Fill the box", "body": "Make sure the drainage holes are open, then fill the box with moist potting mix to about an inch below the rim.", "imagePath": null},
    {"title": "Sow in rows", "body": "Sow lettuce and spinach thinly in two shallow rows, and cover with a quarter inch of mix. Sow radish seeds an inch apart in a third row, and push the green onions in along the front edge, roots down, 2 inches apart.", "imagePath": null},
    {"title": "Keep it moist", "body": "Water gently every day until seedlings sprout in about a week, then whenever the top of the mix feels dry. Put the box where it gets 4 to 6 hours of sun.", "imagePath": null},
    {"title": "Thin the seedlings", "body": "When lettuce and spinach have a few true leaves, thin them to about 3 inches apart and eat the thinnings. Thin radishes to 2 inches apart so the roots have room to swell.", "imagePath": null},
    {"title": "Harvest as you go", "body": "Pick outer leaves of lettuce and spinach and leave the center to keep growing. Pull radishes when they are about the size of a large marble, usually within a month, and snip green onion tops as needed.", "imagePath": null}
  ]'::jsonb, -- steps
  '{lettuce,spinach,radish,green-onion}', -- plant_ids
  '{containers,budget,kids}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 4. Windowsill microgreens tray
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a4', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Windowsill microgreens tray', -- title
  'Grow a tray of fresh microgreens indoors in under two weeks with a shallow tray, a little soil, and a sunny window.', -- summary
  1, -- difficulty
  '{windowsill}', -- space_types
  15, -- est_cost_usd
  20, -- setup_minutes
  '[
    {"name": "Shallow tray with drainage holes (about 10x20 in)", "qty": "1", "estCostUsd": 5, "url": null},
    {"name": "Solid tray or saucer to catch water", "qty": "1", "estCostUsd": 2, "url": null},
    {"name": "Seed-starting mix", "qty": "1 small bag", "estCostUsd": 5, "url": null},
    {"name": "Microgreen seeds (for example radish or broccoli)", "qty": "1 packet", "estCostUsd": 3, "url": null},
    {"name": "Spray bottle", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Fill the tray", "body": "Set the tray with holes inside the solid tray. Fill it with about an inch of seed-starting mix and press it level and firm. Mist until the mix is evenly damp but not soggy.", "imagePath": null},
    {"title": "Sow thickly", "body": "Scatter the seeds densely over the surface so they almost touch. Microgreens are cut young, so crowding is fine. Press the seeds lightly into the mix without burying them.", "imagePath": null},
    {"title": "Cover and wait", "body": "Mist the seeds, then cover the tray with an upside-down second tray or a plate for 2 to 3 days. Darkness helps the seeds sprout evenly. Check once a day and mist if the surface looks dry.", "imagePath": null},
    {"title": "Uncover and give light", "body": "When most seeds have sprouted, remove the cover and set the tray in a bright window. Turn it every day so the stems grow straight.", "imagePath": null},
    {"title": "Water from below", "body": "Pour a little water into the bottom tray once a day rather than watering the leaves, which helps prevent mold. Pour out any water left after an hour.", "imagePath": null},
    {"title": "Harvest", "body": "Most microgreens are ready 7 to 14 days after sowing, when the first true leaves appear. Cut the stems with clean scissors just above the soil, rinse, and eat them the same day.", "imagePath": null}
  ]'::jsonb, -- steps
  '{microgreens}', -- plant_ids
  '{indoor,budget,kids}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 5. 4×4 square-foot raised bed
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a5', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  '4×4 square-foot raised bed', -- title
  'Build a 4 by 4 foot raised bed and plan it in 16 one-foot squares, with tomatoes, peppers, beans, marigolds, and carrots.', -- summary
  2, -- difficulty
  '{smallYard,largeYard,communityPlot}', -- space_types
  150, -- est_cost_usd
  180, -- setup_minutes
  '[
    {"name": "Untreated 2x8 boards, 4 ft long", "qty": "4", "estCostUsd": 45, "url": null},
    {"name": "Exterior screws and 4x4 corner posts", "qty": "1 set", "estCostUsd": 20, "url": null},
    {"name": "Raised-bed soil mix", "qty": "11 cubic feet", "estCostUsd": 55, "url": null},
    {"name": "Cherry tomato transplant and cage", "qty": "1", "estCostUsd": 12, "url": null},
    {"name": "Bell pepper transplant", "qty": "1", "estCostUsd": 4, "url": null},
    {"name": "Seeds: bush bean, marigold, carrot", "qty": "3 packets", "estCostUsd": 9, "url": null},
    {"name": "String or thin lath for grid lines", "qty": "1", "estCostUsd": 5, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Pick the site", "body": "Choose a level spot with 6 to 8 hours of direct sun and a water spout nearby. Lay the boards in a 4 by 4 foot square and screw the corners to the posts. One board high gives about 7 inches of soil depth.", "imagePath": null},
    {"title": "Fill with soil", "body": "Fill the bed with raised-bed soil mix, about 11 cubic feet, and rake it level. Water it well and let it settle for a day before planting.", "imagePath": null},
    {"title": "Mark the grid", "body": "Lay string or lath across the top at one-foot intervals to divide the bed into 16 squares. The grid keeps spacing honest and makes it easy to track what is planted where.", "imagePath": null},
    {"title": "Plan the squares", "body": "Put the cherry tomato with its cage in two squares along the north edge so it will not shade the rest. Add the pepper next to it. Plant 9 bush beans in one square, 16 carrots in another, and a marigold in each of two squares as pest-deterring companions.", "imagePath": null},
    {"title": "Plant at the right time", "body": "Sow carrots in late winter so they mature before summer heat. After the last frost, set out the tomato and pepper transplants and sow beans and marigolds. Water deeply after planting.", "imagePath": null},
    {"title": "Maintain", "body": "Water at the base two or three times a week, more in July and August. Mulch with straw to hold moisture, tie the tomato to its cage as it grows, and pick beans often to keep them coming.", "imagePath": null}
  ]'::jsonb, -- steps
  '{cherry-tomato,bell-pepper,bush-bean,marigold,carrot}', -- plant_ids
  '{raised-bed,louisiana}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 6. Pollinator patch for small yards
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a6', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Pollinator patch for small yards', -- title
  'Replace a 4 by 6 foot patch of lawn with zinnias, cosmos, coneflowers, and black-eyed Susans that feed bees and butterflies from spring to fall.', -- summary
  1, -- difficulty
  '{smallYard,largeYard}', -- space_types
  35, -- est_cost_usd
  120, -- setup_minutes
  '[
    {"name": "Seed packets: zinnia, cosmos", "qty": "2", "estCostUsd": 6, "url": null},
    {"name": "Purple coneflower transplants", "qty": "3", "estCostUsd": 12, "url": null},
    {"name": "Black-eyed Susan transplants", "qty": "3", "estCostUsd": 9, "url": null},
    {"name": "Shredded bark or leaf mulch", "qty": "1 bag", "estCostUsd": 8, "url": null},
    {"name": "Shovel and garden rake", "qty": "1 each", "estCostUsd": null, "url": null},
    {"name": "Shallow dish with pebbles", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Mark and clear the patch", "body": "Pick a spot with at least 6 hours of sun and mark out a 4 by 6 foot rectangle. Remove the grass with a shovel, or smother it with cardboard and mulch for a few weeks first.", "imagePath": null},
    {"title": "Loosen the soil", "body": "Loosen the top 6 inches of soil and rake it smooth. These flowers like average soil, so you do not need a lot of fertilizer, and too much leads to leaves instead of blooms.", "imagePath": null},
    {"title": "Plant the perennials", "body": "Set the coneflower and black-eyed Susan transplants in the back half of the patch, about 18 inches apart, at the same depth they grew in their pots. Water them in well.", "imagePath": null},
    {"title": "Sow the annuals", "body": "After the last frost, scatter zinnia and cosmos seeds in the front half and rake them in lightly. Cosmos are the taller of the two, so keep them toward the middle.", "imagePath": null},
    {"title": "Mulch and water", "body": "Spread a thin layer of mulch between plants, keeping it off the seeds. Water every couple of days until seedlings are up, then weekly during dry spells.", "imagePath": null},
    {"title": "Keep it pollinator-friendly", "body": "Skip pesticides, which harm bees. Set out a shallow dish of water with pebbles for them to land on. Deadhead zinnias to extend the bloom season, and leave coneflower seed heads in fall for the birds.", "imagePath": null}
  ]'::jsonb, -- steps
  '{zinnia,cosmos,purple-coneflower,black-eyed-susan}', -- plant_ids
  '{pollinators,budget,louisiana}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 7. Kratky hydroponic lettuce (no pump)
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a7', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Kratky hydroponic lettuce (no pump)', -- title
  'Grow lettuce in a jar of nutrient water with no pump, no electricity, and almost no maintenance.', -- summary
  2, -- difficulty
  '{windowsill,balcony}', -- space_types
  22, -- est_cost_usd
  60, -- setup_minutes
  '[
    {"name": "Opaque container with a lid (about 1 gallon)", "qty": "1", "estCostUsd": 4, "url": null},
    {"name": "2 inch net cup", "qty": "1", "estCostUsd": 1, "url": null},
    {"name": "Starter plug or coconut coir cube", "qty": "1", "estCostUsd": 2, "url": null},
    {"name": "Leafy-green hydroponic nutrient solution", "qty": "1 small bottle", "estCostUsd": 12, "url": null},
    {"name": "Lettuce seeds", "qty": "1 packet", "estCostUsd": 3, "url": null},
    {"name": "Hole saw or utility knife", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Prepare the container", "body": "Make sure the container is opaque, which keeps light out and slows algae. If it is clear, wrap it in foil or paint it. Cut a hole in the lid that holds the net cup snugly at its rim.", "imagePath": null},
    {"title": "Start the seedling", "body": "Press two or three lettuce seeds into the starter plug, keep it damp, and place it in a bright spot. Once the seeds sprout and roots show at the bottom, thin to the strongest seedling.", "imagePath": null},
    {"title": "Mix the nutrient water", "body": "Fill the container with water and add the nutrient solution at the strength on the label, usually diluted for leafy greens. Use room-temperature water.", "imagePath": null},
    {"title": "Set the water level", "body": "Place the plug in the net cup, set the cup in the lid, and adjust the water so it just touches the bottom of the cup at first. This is the key to a pumpless system, because roots grow down into the water while the upper roots stay in the air.", "imagePath": null},
    {"title": "Give light and leave it alone", "body": "Put it in a bright window or under a grow light for 12 to 14 hours a day. As the plant drinks, the water level falls and leaves an air gap that the roots use. Do not top it off, which would drown the air roots.", "imagePath": null},
    {"title": "Harvest", "body": "Lettuce is usually ready in 4 to 6 weeks. Harvest the outer leaves or cut the whole head. In Louisiana summers keep the jar indoors, since water warmer than about 75 degrees F stresses lettuce.", "imagePath": null}
  ]'::jsonb, -- steps
  '{lettuce}', -- plant_ids
  '{hydroponic,indoor,budget}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 8. Self-watering bottle planters
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a8', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Self-watering bottle planters', -- title
  'Upcycle 2-liter soda bottles into wicking planters that keep basil and strawberries evenly watered for days.', -- summary
  1, -- difficulty
  '{windowsill,balcony}', -- space_types
  13, -- est_cost_usd
  45, -- setup_minutes
  '[
    {"name": "Clean 2-liter plastic bottles", "qty": "2", "estCostUsd": 0, "url": null},
    {"name": "Cotton cord or strip of old t-shirt", "qty": "2 pieces (8 in each)", "estCostUsd": 0, "url": null},
    {"name": "Potting mix", "qty": "1 small bag", "estCostUsd": 6, "url": null},
    {"name": "Sweet basil transplant", "qty": "1", "estCostUsd": 3, "url": null},
    {"name": "Strawberry transplant", "qty": "1", "estCostUsd": 4, "url": null},
    {"name": "Scissors or utility knife", "qty": "1", "estCostUsd": null, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Cut the bottle", "body": "Have an adult cut each bottle in half with a utility knife, about one third of the way down from the top. Poke a small hole in the cap and thread the cotton cord through it so about 3 inches hang out each side.", "imagePath": null},
    {"title": "Build the reservoir", "body": "Fill the bottom half of the bottle with water. Turn the top half upside down and set it in the bottom half, so the cap and wick hang into the water.", "imagePath": null},
    {"title": "Fill with mix", "body": "Fill the top half with damp potting mix, packing it gently around the wick. The wick pulls water up into the soil as the mix dries.", "imagePath": null},
    {"title": "Plant", "body": "Plant one basil or one strawberry in each bottle. Water from the top once to settle the soil, and make sure the wick is wet.", "imagePath": null},
    {"title": "Reduce algae", "body": "Wrap the water reservoir in paper or foil to block light, which keeps algae from growing. Put the planters in a spot with 6 hours of sun for strawberries or bright light for basil.", "imagePath": null},
    {"title": "Refill the reservoir", "body": "Check the water level every few days and top it up through the gap at the rim. In summer heat, you may need to refill it every other day.", "imagePath": null}
  ]'::jsonb, -- steps
  '{sweet-basil,strawberry}', -- plant_ids
  '{upcycled,budget,kids,containers}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 9. Fall greens for Louisiana
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000a9', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Fall greens for Louisiana', -- title
  'Plant kale, collards, Swiss chard, and spinach in October for cool-weather harvests that last through the Louisiana winter.', -- summary
  1, -- difficulty
  '{balcony,smallYard,largeYard,communityPlot}', -- space_types
  40, -- est_cost_usd
  90, -- setup_minutes
  '[
    {"name": "Raised bed or large containers (5 gallons or more)", "qty": "4 sq ft of space", "estCostUsd": null, "url": null},
    {"name": "Compost", "qty": "2 cubic feet", "estCostUsd": 10, "url": null},
    {"name": "Kale and collard transplants", "qty": "2 of each", "estCostUsd": 10, "url": null},
    {"name": "Swiss chard transplants", "qty": "2", "estCostUsd": 5, "url": null},
    {"name": "Spinach seeds", "qty": "1 packet", "estCostUsd": 3, "url": null},
    {"name": "Straw or shredded leaf mulch", "qty": "1 bale or bag", "estCostUsd": 10, "url": null},
    {"name": "Frost cloth", "qty": "1 piece", "estCostUsd": 2, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Wait for cooler weather", "body": "In south Louisiana, wait until daytime highs settle into the low 80s or cooler, usually in October, before planting. Spinach seed will not sprout well in warm soil. Planting greens in September heat tends to stress them.", "imagePath": null},
    {"title": "Prepare the bed", "body": "Pick a spot with at least 6 hours of sun. Work 2 inches of compost into the top 6 inches of soil, or into container mix. Greens are heavy feeders and like rich, well-drained soil.", "imagePath": null},
    {"title": "Set out the transplants", "body": "Plant kale, collards, and chard transplants 12 to 18 inches apart, at the same depth they grew in their pots. Water each plant in well. Transplants give you a head start over seeds.", "imagePath": null},
    {"title": "Sow spinach", "body": "Sow spinach seeds a half inch deep in rows between the larger plants, 2 inches apart, and thin later to 4 inches. Keep the soil evenly moist until the seeds sprout in about a week.", "imagePath": null},
    {"title": "Mulch and water", "body": "Spread 2 inches of mulch around the plants to hold moisture and moderate soil temperature. Water about once a week, or two or three times in dry weather, so the soil stays damp an inch down.", "imagePath": null},
    {"title": "Harvest and protect", "body": "Pick the outer leaves from the bottom of each plant and leave the center growing. Kale and collards handle freezes and taste sweeter after a light frost. Cover chard and spinach with frost cloth on nights forecast below 28 degrees F.", "imagePath": null}
  ]'::jsonb, -- steps
  '{kale,collard-greens,swiss-chard,spinach}', -- plant_ids
  '{louisiana,raised-bed,budget}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;

-- 10. Compost bin from a storage tote
insert into public.guides (
  id, author_id, title, summary, difficulty, space_types, est_cost_usd, setup_minutes,
  materials, steps, plant_ids, tags, forked_from, cover_path, status
) values (
  '9e1a0000-0000-4000-8000-0000000000aa', -- id
  (select id from public.profiles where username = 'geauxfarm'), -- author_id
  'Compost bin from a storage tote', -- title
  'Turn an opaque plastic storage tote into a small, tidy compost bin for kitchen scraps and yard waste.', -- summary
  1, -- difficulty
  '{balcony,smallYard,largeYard,communityPlot}', -- space_types
  25, -- est_cost_usd
  60, -- setup_minutes
  '[
    {"name": "Opaque storage tote with a snap-on lid (about 18 gallons)", "qty": "1", "estCostUsd": 12, "url": null},
    {"name": "Drill with 1/2 inch bit", "qty": "1", "estCostUsd": null, "url": null},
    {"name": "Bricks or wood blocks", "qty": "4", "estCostUsd": 0, "url": null},
    {"name": "Drip tray or old baking sheet", "qty": "1", "estCostUsd": 5, "url": null},
    {"name": "Shredded newspaper, dry leaves, or cardboard (browns)", "qty": "1 bag", "estCostUsd": 0, "url": null},
    {"name": "Garden trowel for turning", "qty": "1", "estCostUsd": 8, "url": null}
  ]'::jsonb, -- materials
  '[
    {"title": "Drill ventilation holes", "body": "Drill 1/2 inch holes across the bottom, along the sides, and in the lid, about 3 inches apart. Compost needs air and drainage, otherwise it turns slimy and smells.", "imagePath": null},
    {"title": "Set up the stand", "body": "Place the tote on four bricks or blocks in a shaded spot, over a drip tray, so air moves under it and any liquid is caught. Shade keeps it from drying out in the Louisiana summer.", "imagePath": null},
    {"title": "Start with browns", "body": "Add a 3-inch layer of browns, such as shredded newspaper, dry leaves, or torn cardboard, to the bottom. Browns supply carbon and keep the pile from getting soggy.", "imagePath": null},
    {"title": "Add scraps", "body": "Add fruit and vegetable scraps, coffee grounds, and eggshells, and bury them under a handful of browns each time. Aim for about two or three parts browns to one part scraps by volume. Do not add meat, dairy, oils, or pet waste.", "imagePath": null},
    {"title": "Keep it damp and turn it", "body": "The pile should feel like a wrung-out sponge. Sprinkle water if it is dry, or add more browns if it is wet. Stir with a trowel about once a week to add air.", "imagePath": null},
    {"title": "Use the finished compost", "body": "In warm weather compost can be ready in 2 to 4 months, when it is dark, crumbly, and smells like earth. Spread it on garden beds or mix it into potting soil, and start a new batch in the tote.", "imagePath": null}
  ]'::jsonb, -- steps
  '{}', -- plant_ids
  '{upcycled,budget}', -- tags
  null, -- forked_from
  null, -- cover_path
  'published' -- status
) on conflict (id) do nothing;
