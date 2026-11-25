import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../client/pet_form_screen.dart';
import '../common/appointment_widgets.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../staff/vet/clinical_form_screen.dart';
import 'navigation.dart';

/// Ficha do animal: dados, saúde, vacinas, histórico e (quando permitido)
/// registros clínicos. Usada por tutor, equipe, veterinária e gerência.
class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final pet = data.petById(petId);
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.pets, title: 'Pet não encontrado'));
    }
    final tutor = data.userById(pet.tutorId);
    final history = data.petHistory(pet.id);
    final clinical = data.canViewClinical(me, pet) ? data.clinicalOf(pet.id) : <ClinicalEntry>[];
    final isTutor = me.id == pet.tutorId;
    final canEdit = isTutor || me.isStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.nome),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PetFormScreen(tutorId: pet.tutorId, petId: pet.id))),
            ),
          if (isTutor || me.isGerente)
            IconButton(
              tooltip: 'Remover pet',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: 'Remover ${pet.nome}?',
                    message: 'O histórico é mantido, mas o pet não aparecerá mais para novos agendamentos.',
                    destructive: true,
                    confirmLabel: 'Remover');
                if (!ok || !context.mounted) return;
                final done = await runAction(context, () => data.archivePet(me, pet.id), success: 'Pet removido.');
                if (done && context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      floatingActionButton: me.canAccessVetArea
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.sage,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('Nova consulta'),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ClinicalFormScreen(petId: pet.id))),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          AppCard(
            color: AppColors.sageSoft,
            child: Row(
              children: [
                PetAvatar(pet: pet, size: 96, radius: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      Text('${pet.especie.label} · ${pet.raca}', style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(label: ageText(pet.nascimento), color: AppColors.sageDark),
                          StatusChip(label: '${formatDecimal(pet.peso)} kg', color: AppColors.sageDark),
                          StatusChip(label: pet.sexo.label, color: AppColors.sageDark),
                          StatusChip(label: 'Porte ${pet.porte.label.toLowerCase()}', color: AppColors.sageDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isTutor && tutor != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tutor', style: TextStyle(fontWeight: FontWeight.w600)),
                  InfoRow(icon: Icons.person_outline, label: 'Nome', value: tutor.nome),
                  InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: tutor.telefone),
                  InfoRow(icon: Icons.mail_outline, label: 'E-mail', value: tutor.email),
                ],
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saúde', style: TextStyle(fontWeight: FontWeight.w600)),
                InfoRow(icon: Icons.cake_outlined, label: 'Nascimento',
                    value: pet.nascimento == null ? '' : formatDate(pet.nascimento!)),
                InfoRow(icon: Icons.health_and_safety_outlined, label: 'Castrado(a)', value: pet.castrado ? 'Sim' : 'Não'),
                InfoRow(icon: Icons.warning_amber_outlined, label: 'Alergias', value: pet.alergias),
                InfoRow(icon: Icons.monitor_heart_outlined, label: 'Condições', value: pet.condicoes),
                InfoRow(icon: Icons.medication_outlined, label: 'Medicações', value: pet.medicacoes),
                InfoRow(icon: Icons.notes, label: 'Observações', value: pet.observacoes),
              ],
            ),
          ),
          const SectionHeader('Vacinas'),
          if (pet.vacinas.isEmpty)
            const Text('Nenhuma vacina registrada.', style: TextStyle(color: AppColors.muted))
          else
            ...pet.vacinas.map((v) {
              final vencida = v.proxima != null && v.proxima!.isBefore(DateTime.now());
              return AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.vaccines_outlined, color: vencida ? AppColors.danger : AppColors.sage),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${v.nome} · aplicada em ${formatDate(v.data)}')),
                    if (v.proxima != null)
                      StatusChip(
                          label: '${vencida ? 'Venceu' : 'Próx.'} ${formatDate(v.proxima!)}',
                          color: vencida ? AppColors.danger : AppColors.info),
                  ],
                ),
              );
            }),
          if (data.canViewClinical(me, pet)) ...[
            SectionHeader(me.canAccessVetArea ? 'Ficha clínica' : 'Orientações veterinárias'),
            if (clinical.isEmpty)
              const Text('Nenhuma consulta registrada.', style: TextStyle(color: AppColors.muted))
            else
              ...clinical.map((c) => ClinicalEntryCard(entry: c, full: me.canAccessVetArea)),
          ],
          const SectionHeader('Histórico de atendimentos'),
          if (history.isEmpty)
            const Text('Nenhum atendimento ainda.', style: TextStyle(color: AppColors.muted))
          else
            ...history.map((a) => AppointmentCard(
                  appointment: a,
                  showStaff: !isTutor,
                  onTap: () => openAppointment(context, a.id),
                )),
        ],
      ),
    );
  }
}

class ClinicalEntryCard extends StatelessWidget {
  const ClinicalEntryCard({super.key, required this.entry, required this.full});
  final ClinicalEntry entry;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final c = entry;
    return AppCard(
      color: AppColors.lilac.withOpacity(0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.sageDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${formatDateTime(c.data)} · ${c.veterinarioNome}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (full && c.queixa.isNotEmpty) _line('Queixa', c.queixa),
          if (full && c.anamnese.isNotEmpty) _line('Anamnese', c.anamnese),
          _line('Diagnóstico', c.diagnostico),
          if (c.prescricao.isNotEmpty) _line('Prescrição', c.prescricao),
          if (full && (c.peso != null || c.temperatura != null))
            _line('Sinais',
                '${c.peso != null ? 'Peso ${formatDecimal(c.peso!)} kg' : ''}'
                '${c.peso != null && c.temperatura != null ? ' · ' : ''}'
                '${c.temperatura != null ? 'Temp. ${formatDecimal(c.temperatura!)} °C' : ''}'),
          if (c.retorno != null) _line('Retorno', formatDate(c.retorno!)),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: AppColors.ink, fontSize: 13),
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ],
          ),
        ),
      );
}
