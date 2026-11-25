import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../../state/auth_controller.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.extraTiles = const []});

  /// Atalhos específicos do perfil (ex.: "Ver como cliente", "Área veterinária").
  final List<Widget> extraTiles;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            color: AppColors.sageLight,
            child: Row(
              children: [
                UserAvatar(user: me, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(me.email, style: const TextStyle(color: AppColors.muted)),
                      Text(me.telefone, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(me.roleDescription,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.sageDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...extraTiles,
          MenuTile(
            icon: Icons.person_outline,
            title: 'Editar dados',
            subtitle: 'Nome e telefone',
            onTap: () => _editProfile(context, data, me),
          ),
          MenuTile(
            icon: Icons.lock_outline,
            title: 'Alterar senha',
            onTap: () => _changePassword(context, data, me),
          ),
          if (me.isGerente)
            MenuTile(
              icon: Icons.restart_alt,
              title: 'Restaurar dados de demonstração',
              subtitle: 'Apaga a base local e recria os exemplos',
              onTap: () async {
                final ok = await confirmDialog(context,
                    title: 'Restaurar demonstração?',
                    message: 'Todos os dados locais serão substituídos pelos dados de exemplo.',
                    destructive: true,
                    confirmLabel: 'Restaurar');
                if (!ok || !context.mounted) return;
                final auth = context.read<AuthController>();
                await data.resetDemoData();
                await auth.logout();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          MenuTile(
            icon: Icons.logout,
            title: 'Sair',
            danger: true,
            onTap: () async {
              await context.read<AuthController>().logout();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 8),
          _IntegrationStatus(data: data),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, AppData data, UserModel me) async {
    final form = GlobalKey<FormState>();
    final nome = TextEditingController(text: me.nome);
    final tel = TextEditingController(text: me.telefone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar dados'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: Validators.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tel,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: Validators.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await runAction(context, () => data.updateProfile(me, me.id, nome: nome.text, telefone: tel.text),
          success: 'Dados atualizados.');
    }
  }

  Future<void> _changePassword(BuildContext context, AppData data, UserModel me) async {
    final form = GlobalKey<FormState>();
    final atual = TextEditingController();
    final nova = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) => (v ?? '').isEmpty ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nova,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: Validators.password,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await runAction(context, () => data.changePassword(me, atual: atual.text, nova: nova.text),
          success: 'Senha alterada.');
    }
  }
}

class _IntegrationStatus extends StatelessWidget {
  const _IntegrationStatus({required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, bool ok, String detail) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.info_outline,
                  size: 16, color: ok ? AppColors.sage : AppColors.warning),
              const SizedBox(width: 8),
              Expanded(child: Text('$label: $detail', style: const TextStyle(fontSize: 12))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.beige.withOpacity(0.6), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status das integrações', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          row('Dados', true, 'armazenados localmente neste aparelho'),
          row('Pagamento online', data.paymentGateway.isConfigured, data.paymentGateway.providerName),
          row('Push', data.pushGateway.isConfigured,
              data.pushGateway.isConfigured ? data.pushGateway.providerName : 'somente notificações no app'),
          row('E-mail', data.emailGateway.isConfigured,
              data.emailGateway.isConfigured ? 'configurado' : 'não configurado (recuperação em modo local)'),
        ],
      ),
    );
  }
}
