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

Hosted email delivery, device acceptance, and final sign-in copy approval remain
unverified; this branch is not ready to integrate until those checks are complete.
