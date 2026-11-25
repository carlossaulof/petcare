import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/charts.dart';
import '../common/widgets.dart';

/// Relatórios: produtividade, cancelamentos, serviços e avaliações.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final end = dateOnly(DateTime.now()).add(const Duration(days: 1));
    final start = end.subtract(Duration(days: _days));
    final inPeriod = data.appointments.where((a) => !a.inicio.isBefore(start) && a.inicio.isBefore(end)).toList();
    final concluidos = inPeriod.where((a) => a.status == AppointmentStatus.concluido).toList();
    final cancelados = inPeriod.where((a) => a.status == AppointmentStatus.cancelado).length;
    final reagendados = inPeriod.where((a) => a.reagendamentos > 0).length;
    final taxaCanc = inPeriod.isEmpty ? 0 : cancelados / inPeriod.length * 100;
    final reviews = data.reviews.where((r) => !r.data.isBefore(start)).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final nota = data.averageRating(since: start);

    // Produtividade por funcionário.
    final staff = data.staffMembers.where((s) => s.isFuncionario).toList();
    final prod = staff.map((s) {
      final done = concluidos.where((a) => a.funcionarioId == s.id).toList();
      final receita = done.fold<double>(0, (sum, a) => sum + a.valorTotal);
      final mins = done.fold<int>(0, (sum, a) {
        if (a.iniciadoEm == null || a.concluidoEm == null) return sum;
        return sum + a.concluidoEm!.difference(a.iniciadoEm!).inMinutes;
      });
      return (staff: s, count: done.length, receita: receita, mins: mins, nota: data.averageRating(funcionarioId: s.id, since: start));
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Serviços mais realizados.
    final bySvc = <String, int>{};
    for (final a in concluidos) {
      bySvc[a.servicoNome] = (bySvc[a.servicoNome] ?? 0) + 1;
    }
    final svcEntries = bySvc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Distribuição de notas.
    final dist = List.generate(5, (i) => reviews.where((r) => r.nota == 5 - i).length);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
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
          Row(children: [
            Expanded(child: KpiTile(label: 'Concluídos', value: '${concluidos.length}', color: AppColors.sageLight)),
            const SizedBox(width: 12),
            Expanded(
                child: KpiTile(
                    label: 'Cancelamentos',
                    value: '$cancelados',
                    subtitle: '${formatDecimal(taxaCanc.toDouble())}% do período',
                    color: AppColors.beige)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: KpiTile(label: 'Reagendados', value: '$reagendados', color: AppColors.sageSoft)),
            const SizedBox(width: 12),
            Expanded(
                child: KpiTile(
                    label: 'Nota média',
                    value: nota == null ? '—' : formatDecimal(nota),
                    subtitle: '${reviews.length} avaliações',
                    color: AppColors.lilac)),
          ]),
          const SectionHeader('Produtividade da equipe'),
          ...prod.map((p) => AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    UserAvatar(user: p.staff, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.staff.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${p.count} atendimento(s) · ${formatMoney(p.receita)}'
                            '${p.count > 0 ? ' · média ${formatDuration((p.mins / p.count).round())}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (p.nota != null) ...[
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                      Text(formatDecimal(p.nota!)),
                    ],
                  ],
                ),
              )),
          const SectionHeader('Atendimentos por profissional'),
          AppCard(
            child: HorizontalBars(
              points: prod.where((p) => p.count > 0).map((p) => ChartPoint(p.staff.firstName, p.count.toDouble())).toList(),
            ),
          ),
          const SectionHeader('Serviços mais realizados'),
          AppCard(
            child: HorizontalBars(
              points: svcEntries.map((e) => ChartPoint(e.key, e.value.toDouble())).toList(),
              colors: const [AppColors.beigeDark],
            ),
          ),
          const SectionHeader('Distribuição das notas'),
          AppCard(
            child: HorizontalBars(
              points: List.generate(5, (i) => ChartPoint('${5 - i} estrela${i == 4 ? '' : 's'}', dist[i].toDouble())),
              colors: const [AppColors.warning],
            ),
          ),
          const SectionHeader('Avaliações recentes'),
          if (reviews.isEmpty)
            const Text('Nenhuma avaliação no período.', style: TextStyle(color: AppColors.muted))
          else
            ...reviews.take(20).map((r) {
              final a = data.appointmentById(r.agendamentoId);
              return AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StarRating(value: r.nota.toDouble()),
                        const Spacer(),
                        Text(formatDate(r.data), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${data.userById(r.clienteId)?.nome ?? '-'} · ${a?.servicoNome ?? ''} · '
                        'Prof.: ${data.userById(r.funcionarioId)?.firstName ?? '-'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    if (r.comentario.isNotEmpty) Text(r.comentario),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
