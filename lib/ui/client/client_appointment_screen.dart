import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/reschedule_screen.dart';

/// Acompanhamento em tempo real de um atendimento pelo tutor.
class ClientAppointmentScreen extends StatelessWidget {
  const ClientAppointmentScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final a = data.appointmentById(appointmentId);
    if (a == null || a.clienteId != me.id) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.event_busy, title: 'Agendamento indisponível'));
    }
    final pet = data.petById(a.petId);
    final staff = data.userById(a.funcionarioId);
    final payment = data.paymentFor(a.id);
    final review = data.reviewFor(a.id);
    final canChange = data.clientCanChange(a);
    final pendentes = a.adicionais.where((x) => x.status == AdditionalStatus.pendente).toList();
    final aprovados = a.adicionais.where((x) => x.status == AdditionalStatus.aprovado).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Atendimento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              PetAvatar(pet: pet, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pet?.nome} · ${a.servicoNome}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('${formatLongDate(a.inicio)}, ${formatTime(a.inicio)}',
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 4),
                    StatusChip.appointment(a.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ForecastBanner(appointment: a),
          const SizedBox(height: 12),
          for (final add in pendentes)
            AppCard(
              color: AppColors.warning.withOpacity(0.14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Autorização necessária', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${add.solicitadoPorNome} sugere "${add.nome}" '
                      '(${formatMoney(add.preco)} · +${formatDuration(add.duracaoMin)}).'),
                  const SizedBox(height: 4),
                  Text('Motivo: ${add.justificativa}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => runAction(context, () => data.respondAdditional(me, a.id, add.id, false),
                              success: 'Adicional recusado.'),
                          child: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => runAction(context, () => data.respondAdditional(me, a.id, add.id, true),
                              success: 'Adicional aprovado.'),
                          child: const Text('Autorizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (a.status != AppointmentStatus.cancelado) ...[
            const SectionHeader('Linha do tempo'),
            AppCard(child: ProcedureTimeline(appointment: a)),
          ],
          const SectionHeader('Detalhes'),
          AppCard(
            child: Column(
              children: [
                InfoRow(icon: Icons.person_outline, label: 'Profissional', value: staff?.nome ?? 'A definir'),
                InfoRow(icon: Icons.timer_outlined, label: 'Duração', value: formatDuration(a.duracaoTotalMin)),
                InfoRow(icon: Icons.sell_outlined, label: a.servicoNome, value: formatMoney(a.preco)),
                for (final x in aprovados) InfoRow(icon: Icons.add, label: x.nome, value: formatMoney(x.preco)),
                const Divider(),
                InfoRow(icon: Icons.payments_outlined, label: 'Total', value: formatMoney(a.valorTotal)),
                if (a.observacaoCliente.isNotEmpty)
                  InfoRow(icon: Icons.chat_bubble_outline, label: 'Sua observação', value: a.observacaoCliente),
              ],
            ),
          ),
          const SectionHeader('Recados da equipe'),
          NotesList(notes: a.notas),
          if (payment != null) ...[
            const SectionHeader('Pagamento'),
            _PaymentCard(payment: payment),
          ],
          if (a.status == AppointmentStatus.concluido) ...[
            const SectionHeader('Avaliação'),
            review == null
                ? _ReviewForm(appointmentId: a.id)
                : AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRating(value: review.nota.toDouble(), size: 24),
                        if (review.comentario.isNotEmpty) ...[const SizedBox(height: 6), Text(review.comentario)],
                        Text('Avaliado em ${formatDate(review.data)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
          ],
          if (a.status.isOpen) ...[
            const SizedBox(height: 16),
            if (canChange)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: const Text('Reagendar'),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => RescheduleScreen(appointmentId: a.id))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      onPressed: () async {
                        final motivo = await promptText(context,
                            title: 'Cancelar agendamento',
                            label: 'Motivo do cancelamento',
                            confirmLabel: 'Cancelar agendamento');
                        if (motivo == null || !context.mounted) return;
                        await runAction(context, () => data.cancel(me, a.id, motivo),
                            success: 'Agendamento cancelado.');
                      },
                    ),
                  ),
                ],
              )
            else if (a.status == AppointmentStatus.agendado)
              Text(
                'Alterações pelo app só até ${data.hours.antecedenciaCancelamentoHoras}h antes. '
                'Para mudanças, fale com o petshop.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
          ],
          const SectionHeader('Registro'),
          AppCard(child: EventLog(events: a.eventos)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final Payment payment;

  Future<PaymentMethod?> _chooseMethod(BuildContext context, String title) {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ...PaymentMethod.values.map((m) => ListTile(
                  leading: Icon(m.icon),
                  title: Text(m.label),
                  onTap: () => Navigator.pop(ctx, m),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final p = payment;
    final online = data.paymentGateway.isConfigured;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(formatMoney(p.valor), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip.payment(p.status),
            ],
          ),
          if (p.metodo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${p.metodo!.label} · ${p.canal == PaymentChannel.online ? 'online' : 'no balcão'}'
                  '${p.pagoEm != null ? ' · pago em ${formatDateTime(p.pagoEm!)}' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ),
          if (p.status == PaymentStatus.pendente || p.status == PaymentStatus.aguardandoConfirmacao) ...[
            const SizedBox(height: 12),
            if (p.status == PaymentStatus.aguardandoConfirmacao)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('A equipe vai confirmar o recebimento no balcão.', style: TextStyle(fontSize: 13)),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final m = await _chooseMethod(context, 'Como vai pagar no balcão?');
                      if (m == null || !context.mounted) return;
                      await runAction(context, () => data.declareCounterPayment(me, p.id, m),
                          success: 'Ótimo! Apresente-se no balcão para concluir.');
                    },
                    child: const Text('Pagar no balcão'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: online
                        ? () async {
                            final m = await _chooseMethod(context, 'Pagar online');
                            if (m == null || !context.mounted) return;
                            await runAction(context, () => data.payOnline(me, p.id, m),
                                success: 'Pagamento aprovado.');
                          }
                        : null,
                    child: const Text('Pagar online'),
                  ),
                ),
              ],
            ),
            if (!online)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pagamento online indisponível: o petshop ainda não conectou um provedor de pagamentos.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.appointmentId});
  final String appointmentId;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  int _nota = 0;
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Text('Como foi o atendimento?', style: TextStyle(fontWeight: FontWeight.w600)),
          StarInput(value: _nota, onChanged: (v) => setState(() => _nota = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _comentario,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(hintText: 'Comentário (opcional)'),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nota == 0
                  ? null
                  : () => runAction(
                        context,
                        () => context
                            .read<AppData>()
                            .addReview(currentUser(context), widget.appointmentId, _nota, _comentario.text),
                        success: 'Obrigado pela avaliação!',
                      ),
              child: const Text('Enviar avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}
