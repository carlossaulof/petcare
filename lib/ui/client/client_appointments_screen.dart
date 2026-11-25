import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import 'booking_screen.dart';
import 'client_appointment_screen.dart';

class ClientAppointmentsScreen extends StatelessWidget {
  const ClientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final open = data.openAppointmentsOfClient(me.id);
    final history = data.historyOfClient(me.id);

    Widget list(List<Appointment> items, String empty) => items.isEmpty
        ? EmptyState(icon: Icons.event_available, title: empty)
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => AppointmentCard(
              appointment: items[i],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ClientAppointmentScreen(appointmentId: items[i].id))),
            ),
          );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agendamentos'),
          actions: [
            IconButton(
              tooltip: 'Novo agendamento',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.muted,
                tabs: [
                  Tab(text: 'Abertos (${open.length})'),
                  const Tab(text: 'Histórico'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            list(open, 'Nenhum agendamento aberto'),
            list(history, 'Sem histórico ainda'),
          ],
        ),
      ),
    );
  }
}
