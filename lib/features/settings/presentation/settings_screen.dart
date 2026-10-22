import 'package:flutter/material.dart';

import '../../../app/theme.dart';
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
        children: [
          Text(
            'Preferences'.toUpperCase(),
            style: AppText.overline.copyWith(color: AppColors.soil600),
          ),
          const SizedBox(height: AppSpacing.sm),
          const UnitsTile(),
          const SizedBox(height: AppSpacing.sm),
          const CareRemindersTile(),
        ],
      ),
    );
  }
}
