import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import 'booking_screen.dart';
import 'client_appointment_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  void _book(BuildContext context, {String? serviceId}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(initialServiceId: serviceId)));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final pets = data.petsOf(me.id);
    final open = data.openAppointmentsOfClient(me.id);
    final today = open.where((a) => isSameDay(a.inicio, DateTime.now()) || a.status == AppointmentStatus.emAndamento).toList();
    final upcoming = open.where((a) => !today.contains(a)).toList();
    final toReview = data
        .historyOfClient(me.id)
        .where((a) => a.status == AppointmentStatus.concluido && data.reviewFor(a.id) == null)
        .take(2)
        .toList();
    final pendingPayments = data
        .paymentsOfClient(me.id)
        .where((p) => p.status == PaymentStatus.pendente)
        .toList();
    final pendingAdditional = open.where((a) => a.temAdicionalPendente).toList();
    final cols = responsiveColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare'),
        actions: [
          IconButton(tooltip: 'Agendar serviço', icon: const Icon(Icons.add), onPressed: () => _book(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AppCard(
            color: AppColors.sageSoft,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá, ${me.firstName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${today.length} atendimento(s) em foco hoje.',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                        onPressed: pets.isEmpty ? () => onNavigate(1) : () => _book(context),
                        child: Text(pets.isEmpty ? 'Cadastrar pet' : 'Agendar serviço'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PetAvatar(pet: pets.isEmpty ? null : pets.first, size: 96, radius: 20),
              ],
            ),
          ),
          for (final a in pendingAdditional)
            AppCard(
              color: AppColors.warning.withOpacity(0.15),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ClientAppointmentScreen(appointmentId: a.id))),
              child: Row(
                children: [
                  const Icon(Icons.notification_important_outlined, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A equipe sugeriu um serviço adicional para ${data.petById(a.petId)?.nome}. Toque para responder.',
                    ),
                  ),
                ],
              ),
            ),
          if (pendingPayments.isNotEmpty)
            AppCard(
              color: AppColors.beige,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClientAppointmentScreen(appointmentId: pendingPayments.first.agendamentoId))),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppColors.sageDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Pagamento pendente: '
                        '${formatMoney(pendingPayments.fold<double>(0, (s, p) => s + p.valor))}'),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          if (today.isNotEmpty) ...[
            const SectionHeader('Hoje no salão'),
            ...today.map((a) => AppointmentCard(
                  appointment: a,
                  showDate: false,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ClientAppointmentScreen(appointmentId: a.id))),
                )),
          ],
          if (upcoming.isNotEmpty) ...[
            SectionHeader('Próximos',
                action: TextButton(onPressed: () => onNavigate(2), child: const Text('Ver agenda'))),
            ...upcoming.take(3).map((a) => AppointmentCard(
                  appointment: a,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ClientAppointmentScreen(appointmentId: a.id))),
                )),
          ],
          if (toReview.isNotEmpty) ...[
            const SectionHeader('Avalie seus atendimentos'),
            ...toReview.map((a) => AppCard(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ClientAppointmentScreen(appointmentId: a.id))),
                  child: Row(
                    children: [
                      PetAvatar(pet: data.petById(a.petId), size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data.petById(a.petId)?.nome} · ${a.servicoNome}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(formatDate(a.inicio), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const StarRating(value: 0),
                    ],
                  ),
                )),
          ],
          const SectionHeader('Áreas do petshop'),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: data.activeServices.map((s) => _ServiceTile(service: s, onTap: () => _book(context, serviceId: s.id))).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});
  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = service.categoria;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: cat.color,
                child: Stack(
                  children: [
                    Center(child: Icon(cat.icon, size: 52, color: AppColors.sageDark.withOpacity(0.75))),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.pets, size: 14, color: AppColors.sageDark.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: cat.color.withOpacity(0.55),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.nome,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${formatMoney(service.preco)} · ${formatDuration(service.duracaoMin)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
