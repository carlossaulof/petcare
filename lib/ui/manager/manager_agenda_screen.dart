import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../client/booking_screen.dart';
import '../common/appointment_widgets.dart';
import '../common/widgets.dart';
import '../shared/navigation.dart';

/// Agenda geral: todos os atendimentos, filtros, atribuição, cancelamento e
/// reagendamento (pelo detalhe do atendimento).
class ManagerAgendaScreen extends StatefulWidget {
  const ManagerAgendaScreen({super.key});

  @override
  State<ManagerAgendaScreen> createState() => _ManagerAgendaScreenState();
}

class _ManagerAgendaScreenState extends State<ManagerAgendaScreen> {
  DateTime _day = dateOnly(DateTime.now());
  AppointmentStatus? _status;
  String? _staffId;

  Future<void> _newBooking(AppData data) async {
    final clients = data.clients.where((c) => c.ativo).toList();
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => ListView(
          controller: scroll,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Agendar para qual cliente?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ...clients.map((c) => ListTile(
                  leading: UserAvatar(user: c, size: 36),
                  title: Text(c.nome),
                  subtitle: Text('${data.petsOf(c.id).length} pet(s) · ${c.telefone}'),
                  onTap: () => Navigator.pop(ctx, c.id),
                )),
          ],
        ),
      ),
    );
    if (id == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(clienteId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final all = data.appointmentsOnDay(_day);
    final list = all
        .where((a) => _status == null || a.status == _status)
        .where((a) => _staffId == null || a.funcionarioId == _staffId)
        .toList();
    final staff = data.staffMembers.where((s) => s.isFuncionario && s.ativo).toList();
    final total = all
        .where((a) => a.status != AppointmentStatus.cancelado)
        .fold<double>(0, (s, a) => s + a.valorTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        onPressed: () => _newBooking(data),
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _day = dateOnly(d));
                    },
                    child: Column(
                      children: [
                        Text(relativeDay(_day), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(formatLongDate(_day), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Todos (${all.length})'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                ),
                ...AppointmentStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${s.label} (${all.where((a) => a.status == s).length})'),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _staffId,
            decoration: const InputDecoration(labelText: 'Profissional'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos os profissionais')),
              ...staff.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.nome))),
            ],
            onChanged: (v) => setState(() => _staffId = v),
          ),
          SectionHeader('${list.length} atendimento(s)',
              action: Text('Previsto: ${formatMoney(total)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          if (list.isEmpty)
            const EmptyState(icon: Icons.event_note, title: 'Nada por aqui', message: 'Nenhum atendimento com estes filtros.')
          else
            ...list.map((a) => AppointmentCard(
                  appointment: a,
                  showStaff: true,
                  showDate: false,
                  onTap: () => openAppointment(context, a.id),
                )),
        ],
      ),
    );
  }
}
