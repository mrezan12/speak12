import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/progress_providers.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/shell/main_shell.dart';
import '../theme/app_colors.dart';

/// Routes by auth + onboarding completion.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const _Splash(),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Auth error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const OnboardingScreen();
        }

        final progressAsync = ref.watch(userProgressProvider);
        return progressAsync.when(
          loading: () => const _Splash(),
          error: (error, _) => Scaffold(
            body: Center(child: Text('Progress error: $error')),
          ),
          data: (progress) {
            if (progress == null || !progress.onboardingCompleted) {
              return const OnboardingScreen();
            }
            return const MainShell();
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
