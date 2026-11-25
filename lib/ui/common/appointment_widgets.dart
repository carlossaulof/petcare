import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import 'widgets.dart';

/// Card de atendimento usado pelos três perfis.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showTutor = false,
    this.showStaff = false,
    this.showDate = true,
  });

  final Appointment appointment;
  final VoidCallback? onTap;
  final bool showTutor;
  final bool showStaff;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final a = appointment;
    final pet = data.petById(a.petId);
    final tutor = data.userById(a.clienteId);
    final staff = data.userById(a.funcionarioId);
    final when = showDate ? '${relativeDay(a.inicio)} ${formatTime(a.inicio)}' : formatTime(a.inicio);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PetAvatar(pet: pet, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pet?.nome ?? 'Pet'} · ${a.servicoNome}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (showTutor) 'Tutor: ${tutor?.nome ?? '-'}',
                        if (showStaff) 'Prof.: ${staff?.nome ?? 'não atribuído'}',
                        if (!showTutor && !showStaff) a.status.label,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(when,
                      style: const TextStyle(color: AppColors.sageDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  if (a.temAdicionalPendente)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.notification_important_outlined, color: AppColors.warning, size: 18),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusChip.appointment(a.status),
              const SizedBox(width: 8),
              if (a.status == AppointmentStatus.emAndamento && a.etapaAtual != null)
                Expanded(
                  child: Text('Etapa: ${a.etapaAtual!.nome}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressLine(value: a.status == AppointmentStatus.cancelado ? 0.0 : a.progresso),
        ],
      ),
    );
  }
}

/// Linha do tempo das etapas do procedimento.
class ProcedureTimeline extends StatelessWidget {
  const ProcedureTimeline({super.key, required this.appointment, this.trailingBuilder});

  final Appointment appointment;

  /// Permite à equipe inserir botões de ação ao lado de cada etapa.
  final Widget? Function(int index, ProcedureStep step)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final steps = appointment.etapas;
    return Column(
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final isLast = i == steps.length - 1;
        final color = switch (s.status) {
          StepStatus.concluido => AppColors.sage,
          StepStatus.emAndamento => AppColors.warning,
          StepStatus.pendente => AppColors.beigeDark,
        };
        final icon = switch (s.status) {
          StepStatus.concluido => Icons.check,
          StepStatus.emAndamento => Icons.more_horiz,
          StepStatus.pendente => Icons.circle_outlined,
        };
        String detail;
        if (s.status == StepStatus.concluido) {
          detail = '${formatTime(s.inicio!)} – ${formatTime(s.fim!)}';
        } else if (s.status == StepStatus.emAndamento) {
          detail = 'Em andamento desde ${formatTime(s.inicio!)}';
        } else {
          detail = 'Aguardando';
        }
        if (s.responsavelNome != null) detail += ' · ${s.responsavelNome}';
        final trailing = trailingBuilder?.call(i, s);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: s.status == StepStatus.pendente ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(icon, size: 14, color: s.status == StepStatus.pendente ? color : Colors.white),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: s.status == StepStatus.concluido ? AppColors.sage : AppColors.beige,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: s.status == StepStatus.pendente ? AppColors.muted : AppColors.ink,
                          )),
                      Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              if (trailing != null) Center(child: trailing),
            ],
          ),
        );
      }),
    );
  }
}

/// Lista de observações e ocorrências.
class NotesList extends StatelessWidget {
  const NotesList({super.key, required this.notes});
  final List<AppointmentNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Text('Nenhuma observação registrada.', style: TextStyle(color: AppColors.muted));
    }
    final sorted = notes.toList()..sort((a, b) => b.data.compareTo(a.data));
    return Column(
      children: sorted.map((n) {
        final occ = n.tipo == NoteType.ocorrencia;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: occ ? AppColors.warning.withOpacity(0.12) : AppColors.cream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(occ ? Icons.report_gmailerrorred : Icons.sticky_note_2_outlined,
                      size: 16, color: occ ? AppColors.warning : AppColors.sage),
                  const SizedBox(width: 6),
                  Text(n.tipo.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  Text(formatDateTime(n.data), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 4),
              Text(n.texto),
              Text('por ${n.autorNome}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Registro de auditoria (quem fez o quê e quando).
class EventLog extends StatelessWidget {
  const EventLog({super.key, required this.events});
  final List<AppointmentEvent> events;

  @override
  Widget build(BuildContext context) {
    final sorted = events.toList()..sort((a, b) => b.data.compareTo(a.data));
    return Column(
      children: sorted
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(formatDateTime(e.data).substring(0, 16),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
                    Expanded(
                      child: Text('${e.descricao} — ${e.autorNome}', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// Previsão de conclusão em destaque.
class ForecastBanner extends StatelessWidget {
  const ForecastBanner({super.key, required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final String title;
    final String value;
    if (a.status == AppointmentStatus.concluido) {
      title = 'Concluído às';
      value = formatTime(a.concluidoEm ?? a.previsaoConclusao);
    } else if (a.status == AppointmentStatus.cancelado) {
      title = 'Cancelado';
      value = a.motivoCancelamento ?? '';
    } else {
      title = a.status == AppointmentStatus.emAndamento ? 'Previsão de conclusão' : 'Término previsto';
      value = '${relativeDay(a.previsaoConclusao)} às ${formatTime(a.previsaoConclusao)}';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sageLight, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.sageDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.sageDark)),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (a.status.isOpen)
            Text('${(a.progresso * 100).round()}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.sageDark)),
        ],
      ),
    );
  }
}
