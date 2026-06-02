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
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
          ),
        );
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
