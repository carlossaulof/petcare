import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/app_data.dart';
import '../../common/appointment_widgets.dart';
import '../../common/helpers.dart';
import '../../common/widgets.dart';
import '../../shared/navigation.dart';
import '../../shared/pet_profile_screen.dart';

/// Área veterinária restrita: consultas do dia, retornos e fichas clínicas.
class VetAreaScreen extends StatefulWidget {
  const VetAreaScreen({super.key});

  @override
  State<VetAreaScreen> createState() => _VetAreaScreenState();
}

class _VetAreaScreenState extends State<VetAreaScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    if (!me.canAccessVetArea) {
      return Scaffold(
        appBar: AppBar(title: const Text('Área veterinária')),
        body: const EmptyState(icon: Icons.lock_outline, title: 'Acesso restrito', message: 'Somente veterinários e gerentes.'),
      );
    }
    final consultas = data.appointments
        .where((a) => a.categoria == ServiceCategory.veterinario && a.status.isOpen)
        .where((a) => me.isGerente || a.funcionarioId == me.id)
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final today = dateOnly(DateTime.now());
    final retornos = data.clinicalEntries
        .where((c) => c.retorno != null && !c.retorno!.isBefore(today))
        .toList()
      ..sort((a, b) => a.retorno!.compareTo(b.retorno!));
    final q = _query.trim().toLowerCase();
    final pets = data.activePets.where((p) {
      if (q.isEmpty) return true;
      final tutor = data.userById(p.tutorId)?.nome.toLowerCase() ?? '';
      return p.nome.toLowerCase().contains(q) || tutor.contains(q) || p.raca.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Área veterinária')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionHeader('Consultas abertas'),
          if (consultas.isEmpty)
            const Text('Nenhuma consulta agendada.', style: TextStyle(color: AppColors.muted))
          else
            ...consultas.map((a) => AppointmentCard(
                  appointment: a,
                  showTutor: true,
                  onTap: () => openAppointment(context, a.id),
                )),
          const SectionHeader('Retornos previstos'),
          if (retornos.isEmpty)
            const Text('Nenhum retorno pendente.', style: TextStyle(color: AppColors.muted))
          else
            ...retornos.map((c) {
              final pet = data.petById(c.petId);
              return AppCard(
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: c.petId))),
                child: Row(
                  children: [
                    PetAvatar(pet: pet, size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${pet?.nome ?? '-'} · ${c.diagnostico}')),
                    StatusChip(label: formatDate(c.retorno!), color: AppColors.info),
                  ],
                ),
              );
            }),
          const SectionHeader('Fichas clínicas'),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar pet, raça ou tutor'),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          ...pets.map((p) {
            final count = data.clinicalOf(p.id).length;
            return AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: p.id))),
              child: Row(
                children: [
                  PetAvatar(pet: p, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${p.raca} · Tutor: ${data.userById(p.tutorId)?.nome ?? '-'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text('$count registro(s)', style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
