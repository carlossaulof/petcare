import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import 'slot_picker.dart';

class RescheduleScreen extends StatefulWidget {
  const RescheduleScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  DateTime? _slot;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final a = data.appointmentById(widget.appointmentId);
    final service = data.serviceById(a?.servicoId);
    if (a == null || service == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.event_busy, title: 'Agendamento indisponível'));
    }
    // Usa a duração total (com adicionais) para calcular horários livres.
    final svc = ServiceModel(
      id: service.id,
      nome: service.nome,
      descricao: service.descricao,
      categoria: service.categoria,
      preco: a.preco,
      duracaoMin: a.duracaoTotalMin,
      etapas: service.etapas,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Reagendar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Text('${data.petById(a.petId)?.nome} · ${a.servicoNome}\n'
                'Horário atual: ${formatDate(a.inicio)} às ${formatTime(a.inicio)}'),
          ),
          const SectionHeader('Novo horário'),
          SlotPicker(
            service: svc,
            petId: a.petId,
            ignoreAppointmentId: a.id,
            selected: _slot,
            onChanged: (s) => setState(() => _slot = s),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _slot == null
                ? null
                : () async {
                    final ok = await runAction(context, () => data.reschedule(currentUser(context), a.id, _slot!),
                        success: 'Reagendado para ${formatDate(_slot!)} às ${formatTime(_slot!)}.');
                    if (ok && context.mounted) Navigator.pop(context);
                  },
            child: const Text('Confirmar novo horário'),
          ),
        ],
      ),
    );
  }
}
