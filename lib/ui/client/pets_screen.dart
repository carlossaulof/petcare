import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/pet_profile_screen.dart';
import 'pet_form_screen.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final pets = data.petsOf(me.id);
    final cols = responsiveColumns(context);

    void add() => Navigator.push(context, MaterialPageRoute(builder: (_) => PetFormScreen(tutorId: me.id)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
        actions: [IconButton(tooltip: 'Cadastrar pet', icon: const Icon(Icons.add), onPressed: add)],
      ),
      body: pets.isEmpty
          ? EmptyState(
              icon: Icons.pets,
              title: 'Nenhum pet cadastrado',
              message: 'Cadastre seu primeiro pet para agendar serviços.',
              action: FilledButton(onPressed: add, child: const Text('Cadastrar pet')),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: pets.length,
              itemBuilder: (_, i) => PetGridCard(
                pet: pets[i],
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => PetProfileScreen(petId: pets[i].id))),
              ),
            ),
    );
  }
}

class PetGridCard extends StatelessWidget {
  const PetGridCard({super.key, required this.pet, required this.onTap});
  final Pet pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = pet.especie == Species.gato ? AppColors.beige : AppColors.sageLight;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (_, c) => PetAvatar(pet: pet, size: c.maxWidth, radius: 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('${pet.raca.isEmpty ? pet.especie.label : pet.raca} · ${ageText(pet.nascimento)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text('${formatDecimal(pet.peso)} kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
