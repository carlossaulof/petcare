import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../state/auth_controller.dart';
import '../common/helpers.dart';
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _aceite = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_nome, _email, _tel, _senha, _confirma]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_aceite) {
      showSnack(context, 'Aceite os termos de uso para continuar.', error: true);
      return;
    }
    final auth = context.read<AuthController>();
    final ok = await runAction(
      context,
      () => auth.register(nome: _nome.text, email: _email.text, telefone: _tel.text, senha: _senha.text),
    );
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      catSize: 150,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Criar conta', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Cadastre-se como tutor para agendar serviços.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: Validators.name,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular com DDD', hintText: '(86) 99999-9999'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha (mín. 6 caracteres)',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirma,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
              validator: (v) => v != _senha.text ? 'As senhas não conferem' : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _aceite,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _aceite = v ?? false),
              title: const Text('Li e aceito os termos de uso e a política de privacidade.',
                  style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2F3A30)),
                onPressed: _submit,
                child: const Text('Criar conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
