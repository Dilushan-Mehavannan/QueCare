import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/config/theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/features/auth/screens/phone_input_screen.dart';
import 'package:mobile/features/auth/screens/role_selection_screen.dart';
import 'package:mobile/screens/home/main_navigation_shell.dart';

class QueueCareApp extends ConsumerWidget {
  const QueueCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'QueueCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveHomeWidget(authState),
    );
  }

  Widget _resolveHomeWidget(AuthState state) {
    // Dynamically route core home states
    switch (state.status) {
      case AuthStatus.loading:
        // Only show full-screen loader if we already have a user/mock user (e.g. startup auto-login check or role saving)
        final hasUser = state.user != null || (state.isMock && state.mockUid != null);
        if (hasUser) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }
        // Otherwise, if we are loading but don't have a user yet (e.g. sending OTP or verifying OTP),
        // we keep the PhoneInputScreen mounted so the local loading indicators show and navigation works.
        return const PhoneInputScreen();
      case AuthStatus.roleSelectionRequired:
        return const RoleSelectionScreen();
      case AuthStatus.success:
        return const MainNavigationShell();
      case AuthStatus.initial:
      case AuthStatus.codeSent:
      case AuthStatus.failure:
        return const PhoneInputScreen();
    }
  }
}
