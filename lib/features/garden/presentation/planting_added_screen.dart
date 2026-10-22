import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/widgets.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../care/presentation/widgets/task_row.dart';
import '../../onboarding/data/profile_providers.dart';
import 'reminder_pre_prompt.dart';

/// PD-03 Added: confirms the new planting, shows its first task, and asks
/// for reminders in context when the OS prompt has never been shown
/// (plan/01 § PD-03, plan/05 § Grow this flow). Pops when the user moves
/// on; the caller then opens Home (HM-02).
class PlantingAddedScreen extends ConsumerStatefulWidget {
  const PlantingAddedScreen({super.key, required this.name});

  /// The planting's nickname, or the plant's common name.
  final String name;

  @override
  ConsumerState<PlantingAddedScreen> createState() =>
      _PlantingAddedScreenState();
}

class _PlantingAddedScreenState extends ConsumerState<PlantingAddedScreen> {
  bool _saving = false;

  Future<void> _answer({required bool turnOn}) async {
    setState(() => _saving = true);
    final service = ref.read(notificationServiceProvider);
    try {
      if (turnOn) {
        await service.requestPermission();
      } else {
        await service.markPermissionAsked();
      }
    } on Exception {
      // No notification plugin on this platform, or the OS request failed:
      // record the answer only, so PD-03 never asks again.
      await service.markPermissionAsked();
    } finally {
      // The answer is the user's way out of PD-03, even if saving it failed.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the profile so the pre-prompt never flashes for a user who
    // has already answered it.
    final asked = ref
        .watch(userProfileProvider)
        .value
        ?.notificationPermissionAsked;
    return Scaffold(
      backgroundColor: AppColors.cream50,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.leaf100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.check_circle_rounded,
                  size: 44,
                  color: AppColors.leaf700,
                  fill: 1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${widget.name} is in your garden!',
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(color: AppColors.soil900),
            ),
            const SizedBox(height: AppSpacing.xl),
            TaskRow(
              type: TaskRowType.water,
              state: TaskRowState.due,
              plantName: widget.name,
              title: 'Water it in today',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (asked == false)
              ReminderPrePrompt(
                onTurnOn: _saving ? null : () => _answer(turnOn: true),
                onNotNow: _saving ? null : () => _answer(turnOn: false),
              )
            else if (asked == true)
              GeauxButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
