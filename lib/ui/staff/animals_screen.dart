import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/widgets.dart';
import '../shared/pet_profile_screen.dart';

/// Consulta de animais e seus históricos (equipe e gerência).
class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final q = _q.trim().toLowerCase();
    final pets = data.activePets.where((p) {
      if (q.isEmpty) return true;
      final tutor = data.userById(p.tutorId);
      return p.nome.toLowerCase().contains(q) ||
          p.raca.toLowerCase().contains(q) ||
          (tutor?.nome.toLowerCase().contains(q) ?? false) ||
          (tutor?.telefone.contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Animais')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por pet, raça, tutor ou telefone',
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: pets.isEmpty
                ? const EmptyState(icon: Icons.search_off, title: 'Nenhum animal encontrado')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: pets.length,
                    itemBuilder: (_, i) {
                      final p = pets[i];
                      final tutor = data.userById(p.tutorId);
                      final last = data.petHistory(p.id).where((a) => a.status == AppointmentStatus.concluido);
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: p.id))),
                        child: Row(
                          children: [
                            PetAvatar(pet: p, size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${p.nome} · ${p.raca}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Tutor: ${tutor?.nome ?? '-'} · ${tutor?.telefone ?? ''}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                  Text(
                                    last.isEmpty
                                        ? 'Sem atendimentos concluídos'
                                        : 'Último: ${last.first.servicoNome} em ${formatDate(last.first.inicio)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (p.alergias.isNotEmpty)
                              const Tooltip(
                                message: 'Possui alergias',
                                child: Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
