import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';
import '../shared/slot_picker.dart';
import 'pet_form_screen.dart';

/// Agendamento: animal → serviço → data → horário disponível → confirmação.
/// O gerente pode usar a mesma tela para agendar em nome de um cliente.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.initialServiceId, this.clienteId});
  final String? initialServiceId;
  final String? clienteId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _petId;
  String? _serviceId;
  DateTime? _slot;
  final _obs = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.initialServiceId;
  }

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  Future<void> _confirm(AppData data, UserModel me, Pet pet, ServiceModel service) async {
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => data.book(me, petId: pet.id, servicoId: service.id, inicio: _slot!, observacao: _obs.text),
      success: 'Agendamento confirmado para ${formatDate(_slot!)} às ${formatTime(_slot!)}.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final tutorId = widget.clienteId ?? me.id;
    final pets = data.petsOf(tutorId);
    final services = data.activeServices;
    if (_petId == null && pets.length == 1) _petId = pets.first.id;
    final pet = data.petById(_petId);
    final service = data.serviceById(_serviceId);

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar serviço')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (widget.clienteId != null)
            AppCard(
              color: AppColors.beige,
              child: Text('Agendando para: ${data.userById(widget.clienteId)?.nome ?? '-'}'),
            ),
          const SectionHeader('1. Qual pet?'),
          if (pets.isEmpty)
            AppCard(
              child: Row(
                children: [
                  const Expanded(child: Text('Nenhum pet cadastrado.')),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => PetFormScreen(tutorId: tutorId))),
                    child: const Text('Cadastrar'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final p = pets[i];
                  final sel = p.id == _petId;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _petId = p.id;
                      _slot = null;
                    }),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.sageLight : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sel ? AppColors.sage : AppColors.beige, width: sel ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          PetAvatar(pet: p, size: 60),
                          const SizedBox(height: 6),
                          Text(p.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SectionHeader('2. Qual serviço?'),
          ...services.map((s) {
            final sel = s.id == _serviceId;
            return AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              color: sel ? AppColors.sageLight : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => setState(() {
                _serviceId = s.id;
                _slot = null;
              }),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: s.categoria.color, shape: BoxShape.circle),
                    child: Icon(s.categoria.icon, size: 20, color: AppColors.sageDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(s.descricao,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMoney(s.preco), style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(formatDuration(s.duracaoMin), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  if (sel) const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: AppColors.sage),
                  ),
                ],
              ),
            );
          }),
          const SectionHeader('3. Data e horário'),
          if (service == null || pet == null)
            const Text('Escolha o pet e o serviço para ver os horários livres.',
                style: TextStyle(color: AppColors.muted))
          else
            SlotPicker(
              key: ValueKey('${service.id}-${pet.id}'),
              service: service,
              petId: pet.id,
              selected: _slot,
              onChanged: (s) => setState(() => _slot = s),
            ),
          const SectionHeader('4. Observações (opcional)'),
          TextField(
            controller: _obs,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(hintText: 'Ex.: está com a pata sensível; usar shampoo hipoalergênico'),
          ),
          if (pet != null && service != null && _slot != null) ...[
            const SizedBox(height: 8),
            AppCard(
              color: AppColors.sageSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  InfoRow(icon: Icons.pets, label: 'Pet', value: pet.nome),
                  InfoRow(icon: service.categoria.icon, label: 'Serviço', value: service.nome),
                  InfoRow(icon: Icons.event, label: 'Data', value: formatLongDate(_slot!)),
                  InfoRow(
                      icon: Icons.schedule,
                      label: 'Horário',
                      value: '${formatTime(_slot!)} – ${formatTime(_slot!.add(Duration(minutes: service.duracaoMin)))}'),
                  InfoRow(icon: Icons.payments_outlined, label: 'Valor', value: formatMoney(service.preco)),
                  const SizedBox(height: 4),
                  const Text('O pagamento é feito após o atendimento.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: pet == null || service == null || _slot == null || _saving
                ? null
                : () => _confirm(data, me, pet, service),
            child: Text(_saving ? 'Agendando...' : 'Confirmar agendamento'),
          ),
        ],
      ),
    );
  }
}
