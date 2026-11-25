import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/charts.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/navigation.dart';
import '../staff/staff_appointment_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _days = 30;
  PaymentStatus? _status;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final today = dateOnly(DateTime.now());
    final end = today.add(const Duration(days: 1));
    final start = end.subtract(Duration(days: _days));
    final total = data.revenueBetween(start, end);
    final byMethod = data.revenueByMethod(start, end);
    final paidCount = data.payments
        .where((p) => p.status == PaymentStatus.pago && p.pagoEm != null && !p.pagoEm!.isBefore(start))
        .length;
    final ticket = paidCount == 0 ? 0.0 : total / paidCount;
    final payments = data.allPaymentsSorted.where((p) => _status == null || p.status == _status).toList();
    final daily = data.revenueByDay(_days > 14 ? 14 : _days);

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 dias')),
              ButtonSegment(value: 30, label: Text('30 dias')),
              ButtonSegment(value: 90, label: Text('90 dias')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: KpiTile(label: 'Faturamento', value: formatMoney(total), color: AppColors.sageLight)),
              const SizedBox(width: 12),
              Expanded(child: KpiTile(label: 'A receber', value: formatMoney(data.pendingAmount), color: AppColors.beige)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: KpiTile(label: 'Pagamentos', value: '$paidCount', color: AppColors.sageSoft)),
              const SizedBox(width: 12),
              Expanded(child: KpiTile(label: 'Ticket médio', value: formatMoney(ticket), color: AppColors.lilac)),
            ],
          ),
          SectionHeader('Receita diária (${daily.length} dias)'),
          AppCard(
            child: SimpleBarChart(
              points: daily
                  .map((e) => ChartPoint('${e.key.day}', e.value,
                      valueLabel: e.value == 0 ? '' : e.value.toStringAsFixed(0)))
                  .toList(),
            ),
          ),
          const SectionHeader('Por forma de pagamento'),
          AppCard(
            child: HorizontalBars(
              points: byMethod.entries
                  .map((e) => ChartPoint(e.key.label, e.value, valueLabel: formatMoney(e.value)))
                  .toList(),
              colors: const [AppColors.sage, AppColors.beigeDark, Color(0xFFA48BB5), AppColors.info],
            ),
          ),
          const SectionHeader('Pagamentos'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: const Text('Todos'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
                ),
                ...PaymentStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const Text('Nenhum pagamento.', style: TextStyle(color: AppColors.muted))
          else
            ...payments.map((p) {
              final a = data.appointmentById(p.agendamentoId);
              final pet = data.petById(a?.petId);
              return AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: a == null ? null : () => openAppointment(context, a.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${data.userById(p.clienteId)?.nome ?? '-'} · ${pet?.nome ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text(formatMoney(p.valor), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('${a?.servicoNome ?? ''} · ${formatDate(p.criadoEm)}'
                        '${p.metodo != null ? ' · ${p.metodo!.label}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip.payment(p.status),
                        const Spacer(),
                        if (p.status == PaymentStatus.pendente || p.status == PaymentStatus.aguardandoConfirmacao)
                          TextButton(
                            onPressed: () => confirmPaymentFlow(context, data, me, p),
                            child: const Text('Confirmar'),
                          ),
                        if (p.status == PaymentStatus.pago)
                          TextButton(
                            onPressed: () async {
                              final ok = await confirmDialog(context,
                                  title: 'Estornar pagamento?',
                                  message: 'Registra o estorno de ${formatMoney(p.valor)}. '
                                      'A devolução do dinheiro deve ser feita pelo meio original.',
                                  destructive: true,
                                  confirmLabel: 'Estornar');
                              if (ok && context.mounted) {
                                await runAction(context, () => data.refundPayment(me, p.id), success: 'Estorno registrado.');
                              }
                            },
                            child: const Text('Estornar', style: TextStyle(color: AppColors.danger)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
