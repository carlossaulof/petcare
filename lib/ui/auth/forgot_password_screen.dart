import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import 'welcome_screen.dart';

/// Recuperação de senha em duas etapas: solicitar código e redefinir.
/// Sem servidor de e-mail configurado, o código é exibido na tela com aviso
/// explícito de "modo local" — nada é simulado como envio real.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _senha = TextEditingController();
  bool _codeSent = false;
  String? _localCode;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!_form1.currentState!.validate()) return;
    final data = context.read<AppData>();
    final code = data.createPasswordResetCode(_email.text);
    String? local;
    if (code != null) {
      if (data.emailGateway.isConfigured) {
        final ok = await runAction(
            context, () => data.emailGateway.sendPasswordReset(email: _email.text.trim(), code: code));
        if (!ok) return;
      } else {
        local = code;
      }
    }
    if (!mounted) return;
    setState(() {
      _codeSent = true;
      _localCode = local;
    });
  }

  Future<void> _reset() async {
    if (!_form2.currentState!.validate()) return;
    final data = context.read<AppData>();
    final ok = await runAction(
      context,
      () => data.resetPassword(email: _email.text, code: _code.text, nova: _senha.text),
      success: 'Senha redefinida. Entre com a nova senha.',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      catSize: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recuperar senha', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            _codeSent
                ? 'Se o e-mail estiver cadastrado, um código de 6 dígitos foi gerado (válido por 15 minutos).'
                : 'Informe o e-mail da sua conta para receber um código.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          if (!_codeSent)
            Form(
              key: _form1,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _request, child: const Text('Enviar código')),
                  ),
                ],
              ),
            )
          else
            Form(
              key: _form2,
              child: Column(
                children: [
                  if (_localCode != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modo local — e-mail não configurado',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text(
                            'Nenhum servidor de e-mail foi configurado, então o código é mostrado aqui. '
                            'Em produção ele é enviado só para o e-mail do usuário.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(_localCode!,
                              style: const TextStyle(fontSize: 26, letterSpacing: 6, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Código', counterText: ''),
                    validator: (v) => (v ?? '').trim().length != 6 ? 'O código tem 6 dígitos' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _reset, child: const Text('Redefinir senha')),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _codeSent = false;
                      _localCode = null;
                    }),
                    child: const Text('Usar outro e-mail'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
