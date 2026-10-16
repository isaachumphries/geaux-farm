import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geaux_farm/features/onboarding/domain/onboarding_draft.dart';
import 'package:geaux_farm/features/onboarding/domain/space.dart';
import 'package:geaux_farm/features/onboarding/domain/user_profile.dart';
import 'package:geaux_farm/features/onboarding/presentation/onboarding_draft_provider.dart';

void _expectEmpty(OnboardingDraft d) {
  expect(d.city, isNull);
  expect(d.admin1, isNull);
  expect(d.countryCode, isNull);
  expect(d.postcode, isNull);
  expect(d.lat, isNull);
  expect(d.lon, isNull);
  expect(d.timezone, isNull);
  expect(d.spaceType, isNull);
  expect(d.areaSqFt, isNull);
  expect(d.sun, isNull);
  expect(d.sunUnsure, isFalse);
  expect(d.rainExposed, isNull);
  expect(d.goals, isEmpty);
  expect(d.goalOtherText, isNull);
  expect(d.experience, isNull);
  expect(d.availability, [0, 0, 0, 0, 0, 0, 0]);
  expect(d.heardFrom, isNull);
  expect(d.heardOtherText, isNull);
}

void main() {
  test('a fresh notifier holds an empty draft', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    _expectEmpty(c.read(onboardingDraftProvider));
  });

  test('a new container after dispose starts empty again', () {
    final first = ProviderContainer();
    first.read(onboardingDraftProvider.notifier).state = const OnboardingDraft(
      city: 'Baton Rouge',
      goals: {Goal.food},
    );
    expect(first.read(onboardingDraftProvider).city, 'Baton Rouge');
    first.dispose();

    final relaunch = ProviderContainer();
    addTearDown(relaunch.dispose);
    _expectEmpty(relaunch.read(onboardingDraftProvider));
  });

  test('reset() empties the draft', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final notifier = c.read(onboardingDraftProvider.notifier);
    notifier.state = const OnboardingDraft(
      city: 'Baton Rouge',
      spaceType: SpaceType.balcony,
      sunUnsure: true,
      availability: [64, 0, 64, 0, 0, 2, 2],
    );
    notifier.reset();
    _expectEmpty(c.read(onboardingDraftProvider));
  });

  test('copyWith replaces given fields and keeps the rest', () {
    const draft = OnboardingDraft(city: 'Baton Rouge', lat: 30.45);
    final next = draft.copyWith(
      sun: SunLevel.partial,
      sunUnsure: true,
      goals: {Goal.hobby},
    );
    expect(next.city, 'Baton Rouge');
    expect(next.lat, 30.45);
    expect(next.sun, SunLevel.partial);
    expect(next.sunUnsure, isTrue);
    expect(next.goals, {Goal.hobby});
  });

  test('copyWith clears a nullable field passed as null', () {
    const draft = OnboardingDraft(
      goals: {Goal.other},
      goalOtherText: 'Pollinators',
    );
    final next = draft.copyWith(goals: {Goal.food}, goalOtherText: null);
    expect(next.goalOtherText, isNull);
    expect(next.goals, {Goal.food});
  });
}
