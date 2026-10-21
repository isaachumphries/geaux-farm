# geaux_farm

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Community authentication

The email-OTP flow uses the Supabase SDK's persisted session, then loads the
matching `profiles` row before exposing a ready `AuthUser`. A stored SDK session
alone does not mean the profile has loaded; an offline cold start can fail that
lookup.

Signing out clears the repository user. Pending profile reads, OTP verification,
and profile creation must not restore that user or complete the sign-in sheet
after logout. These races are covered in
`test/community/supabase_auth_repository_test.dart`.

CM-04 opens on the root navigator so its modal barrier also blocks bottom-tab
navigation. Dismissing it returns to the current tab without resuming a gated
action; the nested-navigator interaction is covered in
`test/community/sign_in_sheet_test.dart`.

Hosted email delivery and device/restart acceptance remain open on issue #20.
The maintainer approved partial integration of the tested implementation,
including the documented sign-in copy and visual deviations; that approval
does not stand in for a hosted OTP or device test.

## Auth setup

Sign-in is an email code (`plan/07-community.md` § Auth), so the project's
auth emails must show a 6-digit code, and they must actually arrive. Supabase's
built-in sender is heavily rate-limited, so the hosted project uses custom SMTP
and the demo uses two pre-made accounts. This section names where each value
lives; the values themselves never go in the repo, a PR, or an issue.

**Local stack** (`supabase start`): already configured. `supabase/config.toml`
sets a 6-digit code and points the `magic_link` and `confirmation` templates at
`supabase/templates/magic_link.html`. Request a code from the app (or
`signInWithOtp`) and read it in the local Mailpit inbox (URL printed by
`supabase start`; no real mail is sent). Restart the stack after editing the
config or the template.

**Hosted project** (Supabase dashboard, done once by a team member with access):

1. Authentication → Email Templates → **Magic Link**: paste the body of
   `supabase/templates/magic_link.html`, set the subject to the one in
   `supabase/config.toml`, and save. The body must contain `{{ .Token }}`;
   a link-only template sends no code.
2. Same page → **Confirm signup**: paste the same body. With "Confirm email"
   on, a first-time sign-in sends this template instead of Magic Link, so it
   needs `{{ .Token }}` too.
3. Authentication → Sign In / Providers → Email: set the OTP length to 6
   (the app only accepts 6 digits).
4. Authentication → SMTP Settings: enable custom SMTP. The sender name and
   address are chosen by the team. The SMTP host, username, and password are
   typed into the dashboard only; the team password manager holds the copy.
   Save, then raise the email rate limit above the built-in default if the
   dashboard allows it.
5. Demo accounts: pick two team-inbox addresses from the team password
   manager. On a device, sign in once with each (email, then the code from
   that inbox, then a username) so each gets an `auth.users` row and a
   `profiles` row. Check Authentication → Users and the `profiles` table in
   the Table Editor. The accounts have no passwords; sign in with a fresh code
   each time.
6. Test: sign in with one of the team inboxes and confirm the code email
   arrives from the custom sender.

| Secret | Where it lives |
|---|---|
| SMTP host, username, password | Supabase dashboard → SMTP Settings; team password manager |
| Demo account addresses and inbox logins | Team password manager |
| Service-role key, database password | Supabase dashboard → Project Settings; team password manager |
| Anon (publishable) key and project URL | `env.json` (gitignored) and CI secrets; template in `env.example.json` |

## Plant detail

PD-01 shows the six compatibility factors, care and first-start growth
window, all season tags, monthly planting windows, and tips in catalog order.
The bottom **Grow this** action stays visible while scrolling and opens the
real PD-02 setup sheet. The image credit includes its license; tapping it
opens the catalog record's source URL when one is present.

## Garden weather alerts

Home and Weather use the same typed `AlertBanner` adapter and shared
`GeauxAlertBanner` visual container. Frost, heat, heavy rain, and high UV retain
the exact plan/06 copy; offline weather says “Showing saved weather”.

Alert evaluation reads only active outdoor plantings and today through two days
ahead. Forecast/cache values stay in °F and inches even when Settings displays
metric units. UV additionally requires an outdoor planting in the Sprouting
stage and today's UV maximum.

Frost notices run at 18:00 local on the preceding day, skip elapsed evenings,
and replace the pending weather set after refresh or planting changes. Weather
owns IDs 1000–1002, separate from care's future-slot epoch-minute IDs, with at
most three pending notices. Scheduling follows the notification Settings toggle.
There is no background forecast refresh.

The rules, display-unit independence, planting filters, and replacement behavior
are covered under `test/weather/`; screen placement and saved-weather age states
are covered by `test/features/weather/weather_screen_test.dart`.
