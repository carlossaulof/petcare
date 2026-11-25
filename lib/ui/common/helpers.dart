import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../../services/integrations.dart';
import '../../state/auth_controller.dart';

/// Usuário logado (use dentro das áreas autenticadas). Durante a transição
/// de logout, devolve um usuário vazio e inativo para evitar falhas de build.
UserModel currentUser(BuildContext context) =>
    context.read<AuthController>().currentUser ??
    UserModel(
      id: '',
      nome: '',
      email: '',
      telefone: '',
      role: UserRole.cliente,
      ativo: false,
      senhaHash: '',
      salt: '',
      criadoEm: DateTime(2000),
    );

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.sageDark,
    ));
}

/// Executa uma ação de negócio exibindo erros de permissão/validação.
/// Retorna true se a ação terminou sem erro.
Future<bool> runAction(BuildContext context, FutureOr<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showSnack(context, success);
    return true;
  } on BusinessException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
  } on PermissionDenied catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
  } on IntegrationNotConfigured catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
  } catch (e) {
    if (context.mounted) showSnack(context, 'Erro inesperado: $e', error: true);
  }
  return false;
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Caixa de texto em diálogo (motivo de cancelamento, observação etc.).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String label = '',
  String confirmLabel = 'Salvar',
  bool required = true,
  int maxLines = 3,
}) {
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: (v) => required && (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, ctrl.text.trim());
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
