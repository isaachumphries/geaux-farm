# AGENTS.md

Instructions for AI coding agents and humans contributing to Geaux Farm.
The app repo is `geaux_farm/` (GitHub `isaachumphries/geaux-farm`). The planning set in `plan/` is the spec for behavior and copy. The team Figma is the spec for how the app looks (see "Design: match the Figma" below). If a plan doc and this file disagree on product behavior, the plan doc wins. If they disagree on process, this file wins.

## 0. Where the work comes from

- Every change starts from a GitHub issue on the **geaux-farm kanban** board (user project #2). Pick cards from **Ready**. Don't pick from **Backlog** until every issue listed under its "Depends on" is merged.
- Board flow: `Backlog` → `Ready` → `In progress` (when you open the branch) → `In review` (when the PR is up) → `Done` (when the PR merges and the issue closes). Move the card yourself at each step.
- Issues are grouped under epics: #12 shell & onboarding, #10 data layer, #9 climate & weather, #7 catalog & recommendations, #8 garden & care, #6 community, #13 polish & demo, #14 local (stretch). Milestones are the plan's gates: Gate 1 (Day 7), Gate 2 (Day 14), Gate 3 (demo).
- Read the issue's **Done when** and **References** before you write code. The issue body is the acceptance contract. If it's wrong or incomplete, comment on the issue. Don't silently build something else.
- Labels: `area: *` names the SME who reviews first (`plan/10-team-and-timeline.md` § SME areas). `contract` marks a Day-2 frozen contract (section 4). `cut-candidate` and `stretch` items get dropped first when a gate slips.

## Design: match the Figma

The team uses Figma for ideation and consistency. The shipped app should look as close to it as we can get:
**https://www.figma.com/design/wy6Rmfb70vvrmECIJDVmlH/design_1?node-id=0-1&p=f&t=b5VpQUqDwtGvkiYD-0**

- Any change that touches UI (screens, widgets, theme/tokens, components, layout, spacing, icons, imagery, copy placement) must match the matching Figma frame. Frames use the plan's codes (`OB-05 Availability/default`, `PD-01`, `CM-02`, ...; see `plan/01-layout-plan.md`).
- Open the frame before you build and match its layout, spacing, color and type tokens, radii, icons, and every drawn state (loading, empty, error, offline, selected, ...). Build from the design tokens and shared components in `lib/app/theme.dart` and the component widgets. Don't hard-code one-off colors, sizes, or fonts.
- Don't invent a new look. If the Figma frame is missing, out of date, or conflicts with the plan (behavior or copy), comment on the issue and resolve it with the design SME (area D) before building. If the decision changes the design, update the Figma first, then the code. Copy text still comes from the plan exactly.
- Agents working on a design or UI step must do the same: look up the frame in the Figma link above (or ask for an export or screenshot if you can't open Figma), name the frame(s) you matched in the PR, and flag every deviation you couldn't avoid.
- Every UI PR attaches a 360×800 screenshot next to the Figma frame it implements, and lists any known differences.

Frame deep links (same file; append the node id to `https://www.figma.com/design/wy6Rmfb70vvrmECIJDVmlH/design_1?node-id=`):

| Frame | Node | Frame | Node | Frame | Node |
|---|---|---|---|---|---|
| OB-00 Splash | `37-533` | HM-01b Home, picked later | `43-712` | CR-02 Reminder (Android / iOS) | `49-810` / `49-826` |
| OB-01 Welcome | `37-553` | RC-01 Recommendations | `43-775` | WX-01 Weather | `46-533` |
| OB-02 Location | `37-587` | PD-01 Plant detail | `44-882` | CM-01 Feed | `47-533` |
| OB-02b Climate reveal | `37-669` | PD-02 Grow this sheet | `44-1039` | CM-02 Guide detail (default / growing) | `47-643` / `53-1634` |
| OB-03 Space | `40-590` | PD-03 Added | `44-1112` | CM-03a–e Editor (basics, materials, steps, plants, preview) | `51-1041`, `51-1169`, `51-1235`, `51-1317`, `51-1393` |
| OB-04 Goals | `40-708` | HM-02 Home active | `44-1156` | CM-04 Sign-in (email / code / username) | `49-1065` / `49-1195` / `49-1329` |
| OB-05 Availability | `40-777` | GD-01 My Garden | `45-533` | ST-01 Settings | `47-787` |
| OB-06 Heard about us | `40-921` | GD-02 Planting detail | `45-648` | | |
| OB-07 Profile summary | `40-1002` | GD-03 Guide project | `49-700` | | |
| HM-01 Home first-run | `43-533` | CR-01 Care schedule | `45-764` | | |

No frame exists yet for CM-05 My profile, the report sheet, or LC-01–03 (Local). Build those from the components and tokens above, then ask the design SME to add the frame to Figma.

## 1. Surgical commits

- One logical change per commit. If you can't describe a commit in one sentence, split it.
- Stage deliberately. Use `git add -p` (or add specific files/hunks). Never `git add -A` or `git add .` blindly.
- No drive-by reformatting, renames, or refactors mixed into a functional change. If you notice something that needs cleanup while working, do it as its own commit, or note it instead (see Scope discipline).
- Generated code (`*.g.dart` from `drift_dev`/`build_runner`) goes in the same commit as the source change that produced it, never mixed with unrelated edits.
- Commit message format:
  - Subject: imperative mood, ≤72 chars, prefixed with the area and ending with the issue number, e.g. `care: add slotFor free-time scheduling (#42)`. Don't start the subject with `#`, because git treats lines starting with `#` as comments.
  - Body: explain *why*, not just what. Reference context a reviewer won't otherwise have (plan section, fixture, edge case).
- Each commit should build and pass tests where practical. Don't leave intermediate commits in a broken state on shared branches.
- Don't rewrite shared/pushed history that others may have based work on. Rebasing an open PR's branch onto `main` before it lands is fine (see section 9).
- Force-push only with `--force-with-lease` (never bare `--force`), and only to an unmerged branch that is yours or that you're landing as a maintainer (section 9).

## 2. One branch, one PR, per task

- One issue = one branch = one PR. Don't bundle unrelated issues.
- Branch naming: `<area>/<issue#>-<short-slug>`, e.g. `care/42-slot-for` or `onboarding/23-availability-grid`. Areas: `shell`, `onboarding`, `data`, `climate`, `weather`, `catalog`, `recs`, `garden`, `care`, `community`, `local`, `settings`, `ci`.
- Always branch from an up-to-date `origin/main`:
  ```
  git fetch origin
  git checkout -b <area>/<issue#>-<short-slug> origin/main
  ```
- Keep PRs small, roughly 400 changed lines as a guide (generated `*.g.dart` and `plants.json` data don't count). Split larger work into sequential PRs. Catalog authoring issues can land in batches of about 10 records.
- PR body references the issue (`Closes #N`) and includes test notes: what you tested, how (unit, widget, pgTAP, emulator/device), and what you didn't. UI PRs include a 360×800 screenshot side by side with the Figma frame it implements.
- To incorporate upstream changes, rebase on main; don't merge main into your branch.
  ```
  git fetch origin
  git rebase origin/main
  ```
- Never commit directly to `main`.
- Don't merge a PR until it has passed the pre-merge review in section 9 and CI is green (format, analyze, test, build; plus `supabase test db` once that job exists). After that, a maintainer may merge it with a merge commit, whether it's their own PR or a teammate's. Merges happen in the team's daily merge window.

## 3. Git worktrees for parallel work

When you have multiple independent tasks, give each its own worktree instead of stashing or switching branches in place.

A task is parallelizable when it:
- touches a disjoint set of files from other in-flight tasks (no shared files),
- has no dependency on another task's unmerged changes (check the issue's "Depends on"),
- doesn't require the same generated/build artifacts to be in a particular state at the same time.

Hot files in this repo: `pubspec.yaml`/`pubspec.lock`, `lib/app/router.dart`, `lib/core/db/` (Drift schema + generated code), `assets/plants/plants.json`, `supabase/migrations/`. If two tasks touch one of these, or one needs the other's output first, do them one after the other.

Rules:
- One agent (or one person) per worktree. Never edit another agent's worktree.
- Run `flutter pub get` (and `dart run build_runner build --delete-conflicting-outputs` when Drift is involved) separately in each worktree. Don't share `.dart_tool/` or `build/` between worktrees.
- Clean up after merge: remove the worktree and prune stale metadata.

Cheat-sheet:
```
# create a new worktree + branch for a task, based on up-to-date main
git fetch origin
git worktree add ../geaux_farm-wt/<branch> -b <branch> origin/main

# list active worktrees
git worktree list

# after the PR merges: remove the worktree, then prune bookkeeping
git worktree remove ../geaux_farm-wt/<branch>
git worktree prune

# force-remove a worktree with uncommitted changes (only if you're sure)
git worktree remove --force ../geaux_farm-wt/<branch>
```

## 4. Scope discipline and project rules

- Stay inside the issue you were given. Don't fix unrelated bugs, upgrade unrelated dependencies, or "improve while you're in there."
- If you spot an out-of-scope problem, note it on the relevant issue or PR (as a comment or a new issue on the board) instead of fixing it inline.
- If an issue turns out to need out-of-scope changes, stop and flag it rather than silently growing the diff.
- **Frozen contracts** (label `contract`): the `plants.json` schema (`plan/03`), the Dart contracts (`plan/09` § Dart contracts), `0001_init.sql` (`plan/07`), the route table (`plan/09` § Routes), and the design tokens (`plan/01`). They change only in a PR that also updates the owning plan doc, and the owning SME must review it.
- **Domain code is pure.** Functions in `lib/features/*/domain/` take explicit `today`/`now` and never read the clock, the network, or Flutter.
- **Backend portability:** only `lib/main.dart`, `lib/core/env.dart`, and `lib/features/{community,local}/data/` may import `supabase_flutter`. Everything else uses the repository interfaces.
- **Migrations:** Drift schema changes bump `schemaVersion` and add a migration step. Supabase changes go in a new numbered file in `supabase/migrations/`. Never edit a migration that has already been applied to the shared project.
- **Copy:** UI strings come from the plan exactly (`plan/02` wins over `plan/01` for onboarding copy). Don't paraphrase.

## 5. Attribution

- Do not add `Co-Authored-By` trailers to commits.
- Do not add "Generated with ..." or similar AI-attribution lines to commits, PR descriptions, or issue text.
- Commits, PRs, and issues should read as if written by the contributor, with no tooling byline.

## 6. Secrets and data

- Never commit secrets, API keys, tokens, credentials, `.env` files, HAR captures, database dumps, or personally identifiable information (PII).
- In this project that specifically means:
  - `env.json` stays gitignored. Only `env.example.json` with placeholder values is committed.
  - The Supabase **service-role key**, database password, access tokens, and SMTP credentials never go in the repo, the app, CI logs, issues, or PRs. The anon key is public by design (RLS protects data), but it still lives only in `env.json` and CI secrets.
  - Android signing material (`*.jks`, `*.keystore`, `key.properties`), `google-services.json`/`GoogleService-Info.plist` if added later, and any USDA Local Food Portal API key.
  - Real user data: emails, OTP codes, exact coordinates (store lat/lon rounded to 2 decimals; local posts to 0.1°), screenshots that show a real inbox. Seed data and fixtures use the `@geauxfarm` team account and made-up content only.
- Before committing, check `git status` and `git diff --staged` for anything that looks like a credential or capture file, even if the filename looks innocuous.
- If the repo has a secret scanner or pre-commit hook, run it before pushing. Don't bypass it with `--no-verify`.
- If a secret is committed by mistake, don't just delete it in a follow-up commit, because it stays in history. Flag it immediately so it can be rotated (Supabase dashboard → API settings) and purged properly.
- Third-party assets: plant photos need a filled-in `image.credit` and `image.license` (Wikimedia Commons or team-made). Fonts ship with their OFL license files. Keep the Open-Meteo (CC BY 4.0) and phzmapi/USDA attribution visible.

## 7. External services and tests

- Tests never hit the live network. Open-Meteo, phzmapi, Supabase, and Overpass are faked with provider overrides or recorded fixtures under `test/fixtures/`. The Baton Rouge fixture in `plan/04` is the canonical climate fixture.
- Respect free-tier limits during development. Open-Meteo is non-commercial and refreshes at most every 60 min per the weather cache rule. Supabase built-in email is heavily rate-limited, so use the demo accounts or custom SMTP. Overpass needs caching and no retry loops.
- pgTAP tests (`supabase test db`) run against the local Supabase stack only, never the shared hosted project.

## 8. Before opening a PR

Checklist:
- [ ] Branch is rebased on the latest `origin/main` (no merge commits from main into your branch).
- [ ] `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test` pass locally. If you touched `supabase/`, `supabase db reset && supabase test db` passes. If you touched `plants.json`, `test/catalog/plants_json_test.dart` passes.
- [ ] Generated Drift code is regenerated and committed if the schema changed.
- [ ] Every "Done when" box in the issue is satisfied, or the PR says which ones aren't and why.
- [ ] Full diff reviewed end-to-end for stray changes (formatting noise, leftover comments, unrelated files).
- [ ] No debug output, `print`/`debugPrint` scaffolding, or commented-out code left behind.
- [ ] Commit messages follow the format in section 1.
- [ ] PR description references the issue (`Closes #N`) and includes test notes.
- [ ] UI changes: 360×800 screenshot side by side with the matching Figma frame, the frame codes named, and any differences listed.
- [ ] No secrets, `env.json`, keystores, or PII in the diff.
- [ ] Board card moved to **In review**.

## 9. Pre-merge review and landing

A review subagent can do the pre-merge review; you don't have to wait for a human reviewer. The plan still asks for one human review, ideally by the SME of the touched area (`area:` label). The review counts when all of these hold:

- It covers the PR's own diff (`gh pr diff <n>`, which for a stacked PR is the diff against its parent) in separate passes:
  - correctness against the issue's "Done when" and the referenced plan sections (exact copy, formulas, thresholds, fixture values), and for UI changes, visual fidelity to the Figma frame (layout, tokens, type, icons, states). An unexplained visual deviation is a blocking finding;
  - test strength, including mutation probes. If the suite stays green when the guarded code is removed (e.g. delete the humidity multiplier, the rain-hint boundary, or an RLS policy), that's a blocking finding;
  - compatibility with current `main`: frozen contracts, route table, Drift `schemaVersion`, Supabase migration numbering, `pubspec.lock` conflicts, merge conflicts;
  - this file's rules plus safety: secrets, PII, live network access in tests, rate limits on Open-Meteo/Supabase/Overpass, RLS gaps (anon or another user able to write), `supabase_flutter` imports outside the allowed files.
- An adversarial pass tries to refute each blocking finding. A finding is dropped only when the refutation cites concrete evidence (code, a test, or a probe) and the review records it. A finding that isn't clearly refuted stays blocking.
- The review is posted on the PR.
- Each blocking finding is fixed (failing test first, each fix in its own commit) and re-verified by the reviewer before merging.

Landing a teammate's PR: a maintainer may rebase it onto `origin/main`, resolve conflicts, and push fix commits. When you do:

- comment on the PR first and again at merge, saying what changed;
- keep the author's commits with their authorship;
- before rebasing, note the branch's current remote SHA, and push with an explicit lease on it: `git push --force-with-lease=<branch>:<that-sha> origin <branch>`. A bare `--force-with-lease` checks against your remote-tracking ref, which a later fetch can move past the author's newest commit.
- never drop commits the author pushed in the meantime. If the lease fails, fetch, fold the new commits in, check they're all present, and push again with a lease on the new SHA.

If PRs are stacked (a branch cut from another open PR's branch), land them bottom-up. Retarget each child to `main` before merging it, so its `Closes #N` closes the issue. After merge, move the card to **Done**. A human post-merge review is still welcome; file follow-ups as issues on the board.

## 10. Gates and cut order

- Before each gate, the integration captain runs the gate statement (`plan/10-team-and-timeline.md` § Milestones and gates) on a device. A failure is filed as a P0/P1 bug issue (§ Bug severity) and goes ahead of feature work.
- If a gate slips, cut from the top of the cut order: Local tab → Remix → Journal photos → Step images → Trending tab → Frost-date display. Never cut onboarding, recommendations + first-plant flow, Grow this, watering reminders, the weather card, or community read/star/post/Grow this.
