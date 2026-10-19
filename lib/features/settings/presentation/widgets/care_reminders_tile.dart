import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../care/application/care_reminders.dart';
import '../../../care/application/care_schedule_provider.dart';
import '../../../care/domain/care_schedule.dart';
import '../../../onboarding/data/profile_providers.dart';

/// The Care reminders row on ST-01 Settings: a bell tile, the label, the
/// subtitle, and the switch that turns the reminders on or off.
class CareRemindersTile extends ConsumerWidget {
  const CareRemindersTile({super.key});

  static const double _tile = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(userProfileProvider).value?.notificationsEnabled ?? false;
    return GeauxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: _tile,
            height: _tile,
            decoration: BoxDecoration(
              color: AppColors.leaf100,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: const Icon(
              Symbols.notifications_rounded,
              color: AppColors.leaf700,
              size: AppIconSize.lg,
              fill: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care reminders',
                  style: AppText.body.copyWith(
                    color: AppColors.soil900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Only during your free times',
                  style: AppText.bodySm.copyWith(color: AppColors.soil600),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => _setEnabled(ref, value),
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.leaf500,
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(WidgetRef ref, bool enabled) async {
    // Turning on plans from the schedule. Turning off needs no tasks: every
    // care reminder is cancelled either way.
    final tasks = enabled
        ? await ref.read(careScheduleProvider.future)
        : const <ScheduledCareTask>[];
    await ref
        .read(careReminderSchedulerProvider)
        .setEnabled(enabled: enabled, tasks: tasks);
  }
}
