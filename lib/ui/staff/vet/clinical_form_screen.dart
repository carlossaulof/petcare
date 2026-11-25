import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatters.dart';
import '../../../core/ids.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../data/app_data.dart';
import '../../common/helpers.dart';
import '../../common/widgets.dart';

/// Registro de consulta na ficha clínica (restrito a veterinários/gerentes).
class ClinicalFormScreen extends StatefulWidget {
  const ClinicalFormScreen({super.key, required this.petId, this.appointmentId});
  final String petId;
  final String? appointmentId;

  @override
  State<ClinicalFormScreen> createState() => _ClinicalFormScreenState();
}

class _ClinicalFormScreenState extends State<ClinicalFormScreen> {
  final _form = GlobalKey<FormState>();
  final _queixa = TextEditingController();
  final _anamnese = TextEditingController();
  final _diag = TextEditingController();
  final _presc = TextEditingController();
  final _peso = TextEditingController();
  final _temp = TextEditingController();
  final _retorno = TextEditingController();

  @override
  void dispose() {
    for (final c in [_queixa, _anamnese, _diag, _presc, _peso, _temp, _retorno]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = context.read<AppData>();
    final me = currentUser(context);
    final entry = ClinicalEntry(
      id: newId(),
      petId: widget.petId,
      agendamentoId: widget.appointmentId,
      veterinarioId: me.id,
      veterinarioNome: me.nome,
      data: DateTime.now(),
      queixa: _queixa.text.trim(),
      anamnese: _anamnese.text.trim(),
      diagnostico: _diag.text.trim(),
      prescricao: _presc.text.trim(),
      peso: parseDecimal(_peso.text),
      temperatura: parseDecimal(_temp.text),
      retorno: _retorno.text.trim().isEmpty ? null : parseDate(_retorno.text),
    );
    final ok = await runAction(context, () => data.addClinicalEntry(me, entry), success: 'Consulta registrada.');
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final pet = data.petById(widget.petId);
    if (!me.canAccessVetArea || pet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.lock_outline, title: 'Área restrita a veterinários'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nova consulta')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            AppCard(
              color: AppColors.lilac,
              child: Row(
                children: [
                  PetAvatar(pet: pet, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${pet.nome} · ${pet.especie.label} · ${ageText(pet.nascimento)}'
                        '${pet.alergias.isNotEmpty ? '\nAlergias: ${pet.alergias}' : ''}'),
                  ),
                ],
              ),
            ),
            TextFormField(controller: _queixa, decoration: const InputDecoration(labelText: 'Queixa principal')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _anamnese, maxLines: 4, decoration: const InputDecoration(labelText: 'Anamnese / exame físico')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _peso,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    validator: (v) => Validators.positiveDecimal(v, optional: true, campo: 'Peso'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _temp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Temperatura (°C)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final t = parseDecimal(v);
                      if (t == null || t < 30 || t > 45) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diag,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Diagnóstico'),
              validator: (v) => Validators.required(v, 'Diagnóstico'),
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _presc, maxLines: 4, decoration: const InputDecoration(labelText: 'Prescrição e orientações')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _retorno,
              decoration: InputDecoration(
                labelText: 'Retorno (DD/MM/AAAA, opcional)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: now.add(const Duration(days: 7)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _retorno.text = formatDate(d));
                  },
                ),
              ),
              validator: (v) {
                final e = Validators.date(v, optional: true);
                if (e != null) return e;
                final d = parseDate(v ?? '');
                if (d != null && d.isBefore(dateOnly(DateTime.now()))) return 'O retorno deve ser futuro';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Salvar na ficha clínica')),
          ],
        ),
      ),
    );
  }
}
