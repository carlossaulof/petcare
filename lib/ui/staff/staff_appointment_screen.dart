import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/pet_profile_screen.dart';
import '../shared/reschedule_screen.dart';
import 'vet/clinical_form_screen.dart';

/// Tela operacional do atendimento (funcionário responsável e gerente).
class StaffAppointmentScreen extends StatelessWidget {
  const StaffAppointmentScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final a = data.appointmentById(appointmentId);
    if (a == null || me.isCliente) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.event_busy, title: 'Atendimento indisponível'));
    }
    final pet = data.petById(a.petId);
    final tutor = data.userById(a.clienteId);
    final staff = data.userById(a.funcionarioId);
    final payment = data.paymentFor(a.id);
    final review = data.reviewFor(a.id);
    final canOperate = me.isGerente || (me.isFuncionario && a.funcionarioId == me.id);
    final open = a.status.isOpen;
    final running = a.etapas.any((e) => e.status == StepStatus.emAndamento);

    Widget? stepAction(int i, ProcedureStep s) {
      if (!canOperate || !open) return null;
      if (s.status == StepStatus.emAndamento) {
        return FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
          onPressed: () => runAction(context, () => data.completeStep(me, a.id, i)),
          child: const Text('Concluir'),
        );
      }
      if (s.status == StepStatus.pendente && !running) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
          onPressed: () => runAction(context, () => data.startStep(me, a.id, i)),
          child: const Text('Iniciar'),
        );
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimento'),
        actions: [
          if (me.isGerente && open)
            PopupMenuButton<String>(
              onSelected: (v) => _managerAction(context, data, me, a, v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'assign', child: Text('Atribuir funcionário')),
                if (a.status == AppointmentStatus.agendado)
                  const PopupMenuItem(value: 'reschedule', child: Text('Reagendar')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancelar atendimento')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            onTap: pet == null
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: pet.id))),
            child: Row(
              children: [
                PetAvatar(pet: pet, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pet?.nome} · ${a.servicoNome}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('${relativeDay(a.inicio)} ${formatTime(a.inicio)} · ${formatDuration(a.duracaoTotalMin)}',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Row(children: [
                        StatusChip.appointment(a.status),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('Resp.: ${staff?.nome ?? 'não atribuído'}',
                              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          if (pet != null && (pet.alergias.isNotEmpty || pet.condicoes.isNotEmpty || pet.medicacoes.isNotEmpty))
            AppCard(
              color: AppColors.warning.withOpacity(0.14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('Atenção à saúde', style: TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  if (pet.alergias.isNotEmpty) Text('Alergias: ${pet.alergias}'),
                  if (pet.condicoes.isNotEmpty) Text('Condições: ${pet.condicoes}'),
                  if (pet.medicacoes.isNotEmpty) Text('Medicações: ${pet.medicacoes}'),
                  if (pet.observacoes.isNotEmpty) Text('Comportamento: ${pet.observacoes}'),
                ],
              ),
            ),
          ForecastBanner(appointment: a),
          if (canOperate && open) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.more_time),
                    label: const Text('Ajustar previsão'),
                    onPressed: () => _adjustForecast(context, data, me, a),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(a.status == AppointmentStatus.agendado ? Icons.play_arrow : Icons.check),
                    label: Text(a.status == AppointmentStatus.agendado ? 'Iniciar' : 'Concluir'),
                    onPressed: () async {
                      if (a.status == AppointmentStatus.agendado) {
                        final first = a.etapas.indexWhere((e) => e.status == StepStatus.pendente);
                        await runAction(context, () => data.startStep(me, a.id, first < 0 ? 0 : first),
                            success: 'Atendimento iniciado. O tutor foi notificado.');
                      } else {
                        final ok = await confirmDialog(context,
                            title: 'Concluir atendimento?',
                            message: 'Etapas pendentes serão marcadas como concluídas e o pagamento '
                                'de ${formatMoney(a.valorTotal)} será gerado para o tutor.',
                            confirmLabel: 'Concluir');
                        if (!ok || !context.mounted) return;
                        await runAction(context, () => data.finishAppointment(me, a.id),
                            success: 'Atendimento concluído.');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          if (a.status != AppointmentStatus.cancelado) ...[
            const SectionHeader('Etapas do procedimento'),
            AppCard(child: ProcedureTimeline(appointment: a, trailingBuilder: stepAction)),
          ],
          const SectionHeader('Tutor'),
          AppCard(
            child: Column(
              children: [
                InfoRow(icon: Icons.person_outline, label: 'Nome', value: tutor?.nome ?? ''),
                InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: tutor?.telefone ?? ''),
                InfoRow(icon: Icons.mail_outline, label: 'E-mail', value: tutor?.email ?? ''),
                if (a.observacaoCliente.isNotEmpty)
                  InfoRow(icon: Icons.chat_bubble_outline, label: 'Observação', value: a.observacaoCliente),
              ],
            ),
          ),
          SectionHeader('Observações e ocorrências',
              action: canOperate && a.status != AppointmentStatus.cancelado
                  ? PopupMenuButton<NoteType>(
                      tooltip: 'Adicionar',
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.sage),
                      onSelected: (t) async {
                        final txt = await promptText(context,
                            title: t == NoteType.observacao ? 'Nova observação' : 'Registrar ocorrência',
                            label: t == NoteType.observacao
                                ? 'Ex.: pelagem com nós, comportamento'
                                : 'Ex.: pequeno corte na pata, tratado com antisséptico');
                        if (txt == null || !context.mounted) return;
                        await runAction(context, () => data.addNote(me, a.id, t, txt),
                            success: '${t.label} registrada e enviada ao tutor.');
                      },
                      itemBuilder: (_) => NoteType.values
                          .map((t) => PopupMenuItem(value: t, child: Text(t.label)))
                          .toList(),
                    )
                  : null),
          NotesList(notes: a.notas),
          SectionHeader('Serviços adicionais',
              action: canOperate && open
                  ? TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Solicitar'),
                      onPressed: () => _requestAdditional(context, data, me, a),
                    )
                  : null),
          if (a.adicionais.isEmpty)
            const Text('Nenhum adicional solicitado.', style: TextStyle(color: AppColors.muted))
          else
            ...a.adicionais.map((x) => AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${x.nome} · ${formatMoney(x.preco)}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(x.justificativa, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: x.status.label,
                        color: switch (x.status) {
                          AdditionalStatus.pendente => AppColors.warning,
                          AdditionalStatus.aprovado => AppColors.sage,
                          AdditionalStatus.recusado => AppColors.danger,
                        },
                      ),
                    ],
                  ),
                )),
          if (payment != null) ...[
            const SectionHeader('Pagamento'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(formatMoney(payment.valor),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      StatusChip.payment(payment.status),
                    ],
                  ),
                  if (payment.metodo != null) Text('Método: ${payment.metodo!.label}'),
                  if (payment.status == PaymentStatus.pendente ||
                      payment.status == PaymentStatus.aguardandoConfirmacao) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Confirmar recebimento'),
                      onPressed: () => confirmPaymentFlow(context, data, me, payment),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (review != null) ...[
            const SectionHeader('Avaliação do tutor'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(value: review.nota.toDouble(), size: 22),
                  if (review.comentario.isNotEmpty) Text(review.comentario),
                ],
              ),
            ),
          ],
          if (me.canAccessVetArea && a.categoria == ServiceCategory.veterinario && pet != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('Registrar consulta na ficha clínica'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ClinicalFormScreen(petId: pet.id, appointmentId: a.id))),
            ),
          ],
          const SectionHeader('Registro'),
          AppCard(child: EventLog(events: a.eventos)),
        ],
      ),
    );
  }

  Future<void> _adjustForecast(BuildContext context, AppData data, UserModel me, Appointment a) async {
    final base = a.previsaoConclusao;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: 'Nova previsão de conclusão',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null || !context.mounted) return;
    final now = DateTime.now();
    var dt = DateTime(base.year, base.month, base.day, t.hour, t.minute);
    if (dt.isBefore(now)) dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (dt.isBefore(now)) {
      showSnack(context, 'Escolha um horário futuro.', error: true);
      return;
    }
    await runAction(context, () => data.setForecast(me, a.id, dt), success: 'Previsão atualizada e enviada ao tutor.');
  }

  Future<void> _requestAdditional(BuildContext context, AppData data, UserModel me, Appointment a) async {
    final services = data.activeServices.where((s) => s.id != a.servicoId).toList();
    String? selected;
    final just = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Solicitar serviço adicional'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Serviço'),
                  items: services
                      .map((s) => DropdownMenuItem(
                          value: s.id, child: Text('${s.nome} · ${formatMoney(s.preco)}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setLocal(() => selected = v),
                  validator: (v) => v == null ? 'Escolha o serviço' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: just,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Motivo (enviado ao tutor)'),
                  validator: (v) => Validators.required(v, 'Motivo'),
                ),
                const SizedBox(height: 8),
                const Text('O serviço só será feito após autorização do tutor no app.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Enviar ao tutor'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && selected != null && context.mounted) {
      await runAction(context, () => data.requestAdditional(me, a.id, selected!, just.text),
          success: 'Solicitação enviada. Aguardando autorização do tutor.');
    }
  }

  Future<void> _managerAction(BuildContext context, AppData data, UserModel me, Appointment a, String action) async {
    switch (action) {
      case 'assign':
        await assignStaffFlow(context, data, me, a);
      case 'reschedule':
        Navigator.push(context, MaterialPageRoute(builder: (_) => RescheduleScreen(appointmentId: a.id)));
      case 'cancel':
        final motivo = await promptText(context,
            title: 'Cancelar atendimento', label: 'Motivo (enviado ao tutor)', confirmLabel: 'Cancelar atendimento');
        if (motivo == null || !context.mounted) return;
        await runAction(context, () => data.cancel(me, a.id, motivo), success: 'Atendimento cancelado.');
    }
  }
}

Future<void> assignStaffFlow(BuildContext context, AppData data, UserModel me, Appointment a) async {
  final options = data.qualifiedStaff(a.categoria);
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Atribuir funcionário', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          if (options.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Nenhum profissional habilitado.')),
          ...options.map((s) {
            final free = data.freeStaffFor(a.inicio, a.duracaoTotalMin, a.categoria, ignoreId: a.id).contains(s);
            return ListTile(
              leading: UserAvatar(user: s, size: 36),
              title: Text(s.nome),
              subtitle: Text(free ? 'Disponível neste horário' : 'Ocupado neste horário'),
              trailing: s.id == a.funcionarioId ? const Icon(Icons.check, color: AppColors.sage) : null,
              enabled: free || s.id == a.funcionarioId,
              onTap: () => Navigator.pop(ctx, s.id),
            );
          }),
        ],
      ),
    ),
  );
  if (chosen == null || chosen == a.funcionarioId || !context.mounted) return;
  await runAction(context, () => data.assignStaff(me, a.id, chosen), success: 'Funcionário atribuído.');
}

Future<void> confirmPaymentFlow(BuildContext context, AppData data, UserModel me, Payment p) async {
  final m = await showModalBottomSheet<PaymentMethod>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Recebido ${formatMoney(p.valor)} via:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          ...PaymentMethod.values.map((x) => ListTile(
                leading: Icon(x.icon),
                title: Text(x.label),
                trailing: x == p.metodo ? const Text('informado pelo tutor', style: TextStyle(fontSize: 11)) : null,
                onTap: () => Navigator.pop(ctx, x),
              )),
        ],
      ),
    ),
  );
  if (m == null || !context.mounted) return;
  await runAction(context, () => data.confirmPayment(me, p.id, m), success: 'Pagamento confirmado.');
}
