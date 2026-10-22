import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../community/data/auth_providers.dart';
import '../../../community/domain/auth_user.dart';
import '../../../community/presentation/sign_in_sheet.dart';

/// The Account row on ST-01 Settings. Signed out, tapping it opens the
/// CM-04 sign-in sheet; signed in, it names the user and offers Sign out,
/// which clears the session (plan/01 § ST-01 states).
class AccountTile extends ConsumerWidget {
  const AccountTile({super.key});

  static const double _tile = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final signedIn = user != null && user.hasProfile;
    return GeauxCard(
      onTap: signedIn
          ? null
          : () => showSignInSheet(context, reason: SignInAction.account),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
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
                Symbols.person_rounded,
                color: AppColors.leaf700,
                size: AppIconSize.lg,
                fill: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: signedIn ? _SignedIn(user) : const _SignedOut()),
            if (signedIn)
              GeauxButton(
                label: 'Sign out',
                variant: GeauxButtonVariant.text,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              )
            else
              const Icon(
                Symbols.chevron_right_rounded,
                color: AppColors.soil600,
                size: AppIconSize.xl,
              ),
          ],
        ),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sign in',
      style: AppText.body.copyWith(color: AppColors.soil900),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn(this.user);

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body.copyWith(color: AppColors.soil900),
        ),
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: AppColors.soil600),
        ),
      ],
    );
  }
}
