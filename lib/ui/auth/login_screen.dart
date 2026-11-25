import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/seed.dart';
import '../../state/auth_controller.dart';
import '../common/helpers.dart';
import 'forgot_password_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthController>();
    final ok = await runAction(context, () => auth.login(_email.text, _senha.text));
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      catSize: 200,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bem-vindo de volta',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Entre para cuidar dos seus pets no PetCare.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 22),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _senha,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text))),
                child: const Text('Esqueci minha senha', style: TextStyle(color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F3A30)),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contas de demonstração',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: demoAccounts
                        .map((d) => ActionChip(
                              label: Text(d.label, style: const TextStyle(fontSize: 12)),
                              onPressed: () => setState(() {
                                _email.text = d.email;
                                _senha.text = d.senha;
                              }),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
