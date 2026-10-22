import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'widgets/account_tile.dart';
import 'widgets/care_reminders_tile.dart';
import 'widgets/units_tile.dart';

/// ST-01 Settings, in the plan/01 row order: Units, notifications (Care
/// reminders), account, about. The onboarding-answer rows and Weather
/// alerts are not built yet.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: const [
          _SectionLabel('Preferences'),
          UnitsTile(),
          SizedBox(height: AppSpacing.sm),
          CareRemindersTile(),
          SizedBox(height: AppSpacing.xl),
          _SectionLabel('Account'),
          AccountTile(),
        ],
      ),
    );
  }
}

/// The uppercase caps line over each ST-01 group.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppText.overline.copyWith(color: AppColors.soil600),
        ),
      ),
    );
  }
}
