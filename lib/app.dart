import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/app_data.dart';
import 'state/auth_controller.dart';
import 'ui/auth/welcome_screen.dart';
import 'ui/client/client_shell.dart';
import 'ui/manager/manager_shell.dart';
import 'ui/staff/staff_shell.dart';

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Em telas largas (web/desktop/tablet), mantém leitura confortável.
        return ColoredBox(
          color: AppColors.beige,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const RootGate(),
    );
  }
}

/// Decide a área do app de acordo com o perfil logado.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppData>(); // reage a desativação de conta, troca de perfil etc.
    final user = context.watch<AuthController>().currentUser;
    if (user == null) return const WelcomeScreen();
    return switch (user.role) {
      UserRole.cliente => ClientShell(key: ValueKey('c${user.id}')),
      UserRole.funcionario => StaffShell(key: ValueKey('f${user.id}')),
      UserRole.gerente => ManagerShell(key: ValueKey('g${user.id}')),
    };
  }
}
