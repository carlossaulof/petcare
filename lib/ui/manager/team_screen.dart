import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../client/booking_screen.dart';
import '../client/pet_form_screen.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/navigation.dart';
import '../shared/pet_profile_screen.dart';

/// Equipe e clientes: cadastro e permissões (somente gerente).
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final staff = data.staffMembers;
    final clients = data.clients;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Equipe e clientes'),
          bottom: TabBar(
            labelColor: AppColors.sageDark,
            indicatorColor: AppColors.sage,
            tabs: [Tab(text: 'Equipe (${staff.length})'), Tab(text: 'Clientes (${clients.length})')],
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton.extended(
            backgroundColor: AppColors.sage,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Cadastrar'),
            onPressed: () {
              final tab = DefaultTabController.of(ctx).index;
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => UserFormScreen(defaultRole: tab == 0 ? UserRole.funcionario : UserRole.cliente)));
            },
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: staff.map((s) {
                final done = data.appointments
                    .where((a) => a.funcionarioId == s.id && a.status == AppointmentStatus.concluido)
                    .length;
                final nota = data.averageRating(funcionarioId: s.id);
                return AppCard(
                  color: s.ativo ? Colors.white : AppColors.beige.withOpacity(0.5),
                  onTap: () => _editStaff(context, data, me, s),
                  child: Row(
                    children: [
                      UserAvatar(user: s),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(s.roleDescription, style: const TextStyle(fontSize: 12, color: AppColors.sageDark)),
                            Text('${s.email} · ${s.telefone}',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            if (s.isFuncionario)
                              Text('$done concluídos · nota ${nota == null ? '—' : formatDecimal(nota)}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!s.ativo) const StatusChip(label: 'Inativo', color: AppColors.danger),
                    ],
                  ),
                );
              }).toList(),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: clients.map((c) {
                final pets = data.petsOf(c.id);
                return AppCard(
                  color: c.ativo ? Colors.white : AppColors.beige.withOpacity(0.5),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id))),
                  child: Row(
                    children: [
                      UserAvatar(user: c),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${c.telefone} · ${c.email}',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            Text(pets.isEmpty ? 'Sem pets' : pets.map((p) => p.nome).join(', '),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!c.ativo) const StatusChip(label: 'Inativo', color: AppColors.danger),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editStaff(BuildContext context, AppData data, UserModel me, UserModel s) async {
    var role = s.role;
    var esp = s.especialidade ?? StaffSpecialty.banhoTosa;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(s.nome),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Perfil de acesso', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(value: UserRole.funcionario, label: Text('Funcionário')),
                  ButtonSegment(value: UserRole.gerente, label: Text('Gerente')),
                ],
                selected: {role},
                onSelectionChanged: (v) => setLocal(() => role = v.first),
              ),
              if (role == UserRole.funcionario) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<StaffSpecialty>(
                  value: esp,
                  decoration: const InputDecoration(labelText: 'Especialidade'),
                  items: StaffSpecialty.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (v) => setLocal(() => esp = v ?? esp),
                ),
              ],
            ],
          ),
          actions: [
            if (s.id != me.id)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'toggle'),
                child: Text(s.ativo ? 'Desativar' : 'Reativar',
                    style: TextStyle(color: s.ativo ? AppColors.danger : AppColors.sage)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == 'save') {
      await runAction(context, () => data.updateStaffRole(me, s.id, role: role, especialidade: esp),
          success: 'Permissões atualizadas.');
    } else if (result == 'toggle') {
      await runAction(context, () => data.setUserActive(me, s.id, !s.ativo),
          success: s.ativo ? 'Conta desativada.' : 'Conta reativada.');
    }
  }
}

/// Cadastro de usuário pelo gerente (cliente, funcionário ou gerente).
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.defaultRole = UserRole.funcionario});
  final UserRole defaultRole;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _senha = TextEditingController();
  late UserRole _role = widget.defaultRole;
  StaffSpecialty _esp = StaffSpecialty.banhoTosa;

  @override
  void dispose() {
    for (final c in [_nome, _email, _tel, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = context.read<AppData>();
    final ok = await runAction(
      context,
      () => data.createUserByManager(
        currentUser(context),
        nome: _nome.text,
        email: _email.text,
        telefone: _tel.text,
        senha: _senha.text,
        role: _role,
        especialidade: _role == UserRole.funcionario ? _esp : null,
      ),
      success: '${_role.label} cadastrado. Informe a senha inicial ao usuário.',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo usuário')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SegmentedButton<UserRole>(
              segments: UserRole.values.map((r) => ButtonSegment(value: r, label: Text(r.label))).toList(),
              selected: {_role},
              onSelectionChanged: (v) => setState(() => _role = v.first),
            ),
            if (_role == UserRole.funcionario) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffSpecialty>(
                value: _esp,
                decoration: const InputDecoration(labelText: 'Especialidade'),
                items: StaffSpecialty.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                onChanged: (v) => setState(() => _esp = v ?? _esp),
              ),
            ],
            const SizedBox(height: 12),
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
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              decoration: const InputDecoration(labelText: 'Senha inicial'),
              validator: Validators.password,
            ),
            const SizedBox(height: 8),
            const Text('O usuário pode trocar a senha depois em Perfil › Alterar senha.',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Cadastrar')),
          ],
        ),
      ),
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final c = data.userById(clientId);
    if (c == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.person_off, title: 'Cliente não encontrado'));
    final pets = data.petsOf(c.id);
    final appts = data.appointmentsOfClient(c.id).reversed.toList();
    final gasto = data.paymentsOfClient(c.id)
        .where((p) => p.status == PaymentStatus.pago)
        .fold<double>(0, (s, p) => s + p.valor);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.firstName),
        actions: [
          IconButton(
            tooltip: c.ativo ? 'Desativar conta' : 'Reativar conta',
            icon: Icon(c.ativo ? Icons.block : Icons.check_circle_outline),
            onPressed: () => runAction(context, () => data.setUserActive(me, c.id, !c.ativo),
                success: c.ativo ? 'Conta desativada.' : 'Conta reativada.'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            color: AppColors.sageLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: c.telefone),
                InfoRow(icon: Icons.mail_outline, label: 'E-mail', value: c.email),
                InfoRow(icon: Icons.event, label: 'Cliente desde', value: formatDate(c.criadoEm)),
                InfoRow(icon: Icons.payments_outlined, label: 'Total pago', value: formatMoney(gasto)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.pets),
                  label: const Text('Novo pet'),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PetFormScreen(tutorId: c.id))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.event),
                  label: const Text('Agendar'),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(clienteId: c.id))),
                ),
              ),
            ],
          ),
          const SectionHeader('Pets'),
          if (pets.isEmpty) const Text('Nenhum pet cadastrado.', style: TextStyle(color: AppColors.muted)),
          ...pets.map((p) => AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: p.id))),
                child: Row(
                  children: [
                    PetAvatar(pet: p, size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${p.nome} · ${p.raca} · ${ageText(p.nascimento)}')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              )),
          const SectionHeader('Atendimentos'),
          if (appts.isEmpty) const Text('Nenhum atendimento.', style: TextStyle(color: AppColors.muted)),
          ...appts.map((a) => AppointmentCard(
                appointment: a,
                showStaff: true,
                onTap: () => openAppointment(context, a.id),
              )),
        ],
      ),
    );
  }
}
