import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/charts.dart';
import '../common/widgets.dart';
import '../shared/navigation.dart';
import 'finance_screen.dart';
import 'reports_screen.dart';
import 'team_screen.dart';

/// Dashboard do gerente: todos os números vêm dos dados reais do sistema.
class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));
    final inProgress = data.inProgress;
    final todayList = data.appointmentsOnDay(today).where((a) => a.status != AppointmentStatus.cancelado).toList();
    final upcoming = data.appointments
        .where((a) => a.status == AppointmentStatus.agendado && !a.inicio.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final faturamentoHoje = data.revenueBetween(today, tomorrow);
    final faturamentoSemana = data.revenueBetween(weekStart, tomorrow);
    final nota = data.averageRating();
    final revenue = data.revenueByDay(7);
    final cols = MediaQuery.of(context).size.width > 700 ? 4 : 2;

    // Atendimentos concluídos por categoria (30 dias).
    final since = today.subtract(const Duration(days: 30));
    final byCat = <ServiceCategory, int>{};
    for (final a in data.appointments) {
      if (a.status == AppointmentStatus.concluido && !a.inicio.isBefore(since)) {
        byCat[a.categoria] = (byCat[a.categoria] ?? 0) + 1;
      }
    }
    final pendentesAdic = data.appointments.where((a) => a.temAdicionalPendente).length;
    final aConfirmar = data.payments.where((p) => p.status == PaymentStatus.aguardandoConfirmacao).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Gerência')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              KpiTile(
                label: 'Em andamento',
                value: '${inProgress.length}',
                subtitle: '${todayList.length} atendimentos hoje',
                color: AppColors.sageLight,
                onTap: () => onNavigate(1),
              ),
              KpiTile(
                label: 'Faturamento hoje',
                value: formatMoney(faturamentoHoje),
                subtitle: '7 dias: ${formatMoney(faturamentoSemana)}',
                color: AppColors.beige,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
              ),
              KpiTile(
                label: 'Clientes',
                value: '${data.clients.where((c) => c.ativo).length}',
                subtitle: '${data.activePets.length} pets cadastrados',
                color: AppColors.sageSoft,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const PeopleScreen(initialTab: 1))),
              ),
              KpiTile(
                label: 'Nota média',
                value: nota == null ? '—' : formatDecimal(nota),
                subtitle: '${data.reviews.length} avaliações',
                color: AppColors.lilac,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
            ],
          ),
          if (pendentesAdic > 0 || aConfirmar > 0) ...[
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.warning.withOpacity(0.14),
              child: Text([
                if (aConfirmar > 0) '$aConfirmar pagamento(s) aguardando confirmação',
                if (pendentesAdic > 0) '$pendentesAdic adicional(is) aguardando o tutor',
              ].join(' · ')),
            ),
          ],
          const SectionHeader('Faturamento — últimos 7 dias'),
          AppCard(
            child: SimpleBarChart(
              points: revenue
                  .map((e) => ChartPoint(weekdayShort[e.key.weekday]!, e.value,
                      valueLabel: e.value == 0 ? '0' : formatMoney(e.value).replaceAll('R\$ ', '').split(',').first))
                  .toList(),
            ),
          ),
          const SectionHeader('Atendimentos por área (30 dias)'),
          AppCard(
            child: HorizontalBars(
              points: ServiceCategory.values
                  .where((c) => (byCat[c] ?? 0) > 0)
                  .map((c) => ChartPoint(c.label, (byCat[c] ?? 0).toDouble()))
                  .toList(),
              colors: const [AppColors.sage, AppColors.beigeDark, Color(0xFFA48BB5), AppColors.info],
            ),
          ),
          SectionHeader('Em andamento',
              action: TextButton(onPressed: () => onNavigate(1), child: const Text('Agenda'))),
          if (inProgress.isEmpty)
            const Text('Nenhum atendimento em andamento.', style: TextStyle(color: AppColors.muted))
          else
            ...inProgress.map((a) => AppointmentCard(
                  appointment: a,
                  showStaff: true,
                  showDate: false,
                  onTap: () => openAppointment(context, a.id),
                )),
          const SectionHeader('Próximos agendamentos'),
          if (upcoming.isEmpty)
            const Text('Nenhum agendamento futuro.', style: TextStyle(color: AppColors.muted))
          else
            ...upcoming.take(5).map((a) => AppointmentCard(
                  appointment: a,
                  showStaff: true,
                  onTap: () => openAppointment(context, a.id),
                )),
        ],
      ),
    );
  }
}
