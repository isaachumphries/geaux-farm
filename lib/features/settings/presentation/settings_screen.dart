import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'widgets/care_reminders_tile.dart';

/// ST-01 Settings. Only the Care reminders row is built here. The other
/// Figma rows (Units, Account, Weather alerts, About) belong to their own
/// tickets.
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
          const CareRemindersTile(),
        ],
      ),
    );
  }
}
