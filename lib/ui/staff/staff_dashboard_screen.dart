import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/navigation.dart';
import 'animals_screen.dart';
import 'staff_appointment_screen.dart';
import 'vet/vet_area_screen.dart';

/// Painel da equipe: atendimentos atribuídos por dia.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  DateTime _day = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final recepcao = me.especialidade == StaffSpecialty.recepcao;
    final dayList = (recepcao ? data.appointmentsOnDay(_day) : data.appointmentsOfStaff(me.id))
        .where((a) => isSameDay(a.inicio, _day) && a.status != AppointmentStatus.cancelado)
        .toList();
    // Atendimentos em andamento de dias anteriores também aparecem.
    final carry = data.inProgress
        .where((a) => (recepcao || a.funcionarioId == me.id) && !isSameDay(a.inicio, _day))
        .toList();
    final pendentes = dayList.where((a) => a.status.isOpen).length;
    final concluidos = dayList.where((a) => a.status == AppointmentStatus.concluido).length;
    final toConfirm = data.payments.where((p) => p.status == PaymentStatus.aguardandoConfirmacao).toList();
    final nota = data.averageRating(funcionarioId: recepcao ? null : me.id);
    final today = dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Painel da equipe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Olá, ${me.firstName} · ${me.especialidade?.label ?? ''}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: me.canAccessVetArea ? 'Área veterinária' : 'Animais',
                  value: me.canAccessVetArea ? 'Fichas' : '${data.activePets.length}',
                  icon: me.canAccessVetArea ? Icons.medical_services : Icons.pets,
                  color: AppColors.sageLight,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => me.canAccessVetArea ? const VetAreaScreen() : const AnimalsScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiTile(
                  label: 'Sua nota média',
                  value: nota == null ? '—' : formatDecimal(nota),
                  icon: Icons.star_rounded,
                  color: AppColors.beige,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = -1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(i == 0
                          ? 'Hoje'
                          : i == 1
                              ? 'Amanhã'
                              : i == -1
                                  ? 'Ontem'
                                  : '${weekdayShort[today.add(Duration(days: i)).weekday]} ${today.add(Duration(days: i)).day}'),
                      selected: isSameDay(_day, today.add(Duration(days: i))),
                      onSelected: (_) => setState(() => _day = today.add(Duration(days: i))),
                    ),
                  ),
              ],
            ),
          ),
          SectionHeader(recepcao ? 'Atendimentos do dia' : 'Atendimentos atribuídos',
              action: Text('$pendentes abertos · $concluidos concluídos',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          if (carry.isNotEmpty) ...[
            ...carry.map((a) => AppointmentCard(
                  appointment: a,
                  showTutor: true,
                  onTap: () => openAppointment(context, a.id),
                )),
          ],
          if (dayList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(icon: Icons.event_available, title: 'Nenhum atendimento neste dia'),
            )
          else
            ...dayList.map((a) => AppointmentCard(
                  appointment: a,
                  showTutor: true,
                  showStaff: recepcao,
                  showDate: false,
                  onTap: () => openAppointment(context, a.id),
                )),
          if (toConfirm.isNotEmpty) ...[
            const SectionHeader('Pagamentos a confirmar'),
            ...toConfirm.map((p) {
              final a = data.appointmentById(p.agendamentoId);
              return AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${data.userById(p.clienteId)?.nome ?? '-'} · ${a?.servicoNome ?? ''}\n'
                          '${formatMoney(p.valor)} via ${p.metodo?.label ?? '-'}'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => confirmPaymentFlow(context, data, me, p),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
