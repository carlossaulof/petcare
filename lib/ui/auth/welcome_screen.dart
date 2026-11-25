import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'sleeping_cat.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false, this.catSize = 220});
  final Widget child;
  final bool showBack;
  final double catSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F0EE),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            if (showBack)
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                onPressed: () => Navigator.pop(context),
                              )
                            else
                              const SizedBox(width: 48),
                            const Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pets, size: 20, color: AppColors.ink),
                                  SizedBox(width: 6),
                                  Text('PetCare',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SleepingCat(size: catSize),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      catSize: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuidados com carinho',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('Banho, tosa e veterinário — tudo no mesmo lugar.',
              style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F3A30)),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Criar conta'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Já tenho conta · Entrar'),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Contas de funcionários e gerentes são criadas pela gerência.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
