import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';

/// Cadastro e edição de animais, com foto e informações de saúde.
class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, required this.tutorId, this.petId});
  final String tutorId;
  final String? petId;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _nasc = TextEditingController();
  final _peso = TextEditingController();
  final _alergias = TextEditingController();
  final _condicoes = TextEditingController();
  final _medicacoes = TextEditingController();
  final _obs = TextEditingController();
  Species _especie = Species.cachorro;
  PetSex _sexo = PetSex.macho;
  PetSize _porte = PetSize.medio;
  bool _castrado = false;
  String? _foto;
  List<Vaccine> _vacinas = [];
  Pet? _original;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppData>().petById(widget.petId);
    if (p != null) {
      _original = p;
      _nome.text = p.nome;
      _raca.text = p.raca;
      _nasc.text = p.nascimento == null ? '' : formatDate(p.nascimento!);
      _peso.text = formatDecimal(p.peso);
      _alergias.text = p.alergias;
      _condicoes.text = p.condicoes;
      _medicacoes.text = p.medicacoes;
      _obs.text = p.observacoes;
      _especie = p.especie;
      _sexo = p.sexo;
      _porte = p.porte;
      _castrado = p.castrado;
      _foto = p.fotoBase64;
      _vacinas = p.vacinas.map((v) => Vaccine(nome: v.nome, data: v.data, proxima: v.proxima)).toList();
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _raca, _nasc, _peso, _alergias, _condicoes, _medicacoes, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 700, maxHeight: 700, imageQuality: 72);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _foto = base64Encode(bytes));
    } catch (e) {
      if (mounted) showSnack(context, 'Não foi possível abrir a ${source == ImageSource.camera ? 'câmera' : 'galeria'}.', error: true);
    }
  }

  void _photoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remover foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _foto = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(_nasc.text) ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (d != null) setState(() => _nasc.text = formatDate(d));
  }

  Future<void> _addVaccine() async {
    final form = GlobalKey<FormState>();
    final nome = TextEditingController();
    final data = TextEditingController(text: formatDate(DateTime.now()));
    final prox = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar vacina'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nome,
                decoration: const InputDecoration(labelText: 'Vacina (ex.: V10, Antirrábica)'),
                validator: (v) => Validators.required(v, 'Nome'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: data,
                decoration: const InputDecoration(labelText: 'Aplicada em (DD/MM/AAAA)'),
                validator: (v) => Validators.date(v, notFuture: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: prox,
                decoration: const InputDecoration(labelText: 'Próxima dose (opcional)'),
                validator: (v) => Validators.date(v, optional: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _vacinas.add(Vaccine(
            nome: nome.text.trim(),
            data: parseDate(data.text)!,
            proxima: prox.text.trim().isEmpty ? null : parseDate(prox.text),
          )));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = context.read<AppData>();
    final me = currentUser(context);
    final pet = Pet(
      id: _original?.id ?? newId(),
      tutorId: _original?.tutorId ?? widget.tutorId,
      nome: _nome.text.trim(),
      especie: _especie,
      raca: _raca.text.trim(),
      sexo: _sexo,
      porte: _porte,
      nascimento: _nasc.text.trim().isEmpty ? null : parseDate(_nasc.text),
      peso: parseDecimal(_peso.text)!,
      fotoBase64: _foto,
      castrado: _castrado,
      alergias: _alergias.text.trim(),
      condicoes: _condicoes.text.trim(),
      medicacoes: _medicacoes.text.trim(),
      observacoes: _obs.text.trim(),
      vacinas: _vacinas,
      criadoEm: _original?.criadoEm ?? DateTime.now(),
    );
    final ok = await runAction(context, () => data.savePet(me, pet),
        success: _original == null ? '${pet.nome} cadastrado!' : 'Dados atualizados.');
    if (ok && mounted) Navigator.pop(context);
  }

  Widget _segmented<T>(List<T> values, T selected, String Function(T) label, ValueChanged<T> onChanged) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: values.map((v) => ButtonSegment<T>(value: v, label: Text(label(v)))).toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = _original != null;
    final previewPet = Pet(
      id: 'preview',
      tutorId: '',
      nome: '',
      especie: _especie,
      raca: '',
      sexo: _sexo,
      porte: _porte,
      peso: 0,
      fotoBase64: _foto,
      criadoEm: DateTime.now(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar pet' : 'Novo pet')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _photoOptions,
                child: Stack(
                  children: [
                    PetAvatar(pet: previewPet, size: 120, radius: 30),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
                        child: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader('Identificação'),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome do pet'),
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            const SizedBox(height: 12),
            _segmented(Species.values, _especie, (s) => s.label, (v) => setState(() => _especie = v)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _raca,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Raça (ou SRD)'),
              validator: (v) => Validators.required(v, 'Raça'),
            ),
            const SizedBox(height: 12),
            _segmented(PetSex.values, _sexo, (s) => s.label, (v) => setState(() => _sexo = v)),
            const SizedBox(height: 12),
            _segmented(PetSize.values, _porte, (s) => s.label, (v) => setState(() => _porte = v)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nasc,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Nascimento (DD/MM/AAAA)',
                      suffixIcon: IconButton(icon: const Icon(Icons.calendar_today, size: 18), onPressed: _pickBirth),
                    ),
                    validator: (v) => Validators.date(v, optional: true, notFuture: true),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _peso,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    validator: (v) {
                      final e = Validators.positiveDecimal(v, campo: 'Peso');
                      if (e != null) return e;
                      return parseDecimal(v!)! > 120 ? 'Peso inválido' : null;
                    },
                  ),
                ),
              ],
            ),
            const SectionHeader('Saúde'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Castrado(a)'),
              value: _castrado,
              onChanged: (v) => setState(() => _castrado = v),
            ),
            TextFormField(
              controller: _alergias,
              decoration: const InputDecoration(labelText: 'Alergias', hintText: 'Ex.: frango, dipirona'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _condicoes,
              decoration: const InputDecoration(labelText: 'Condições de saúde'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicacoes,
              decoration: const InputDecoration(labelText: 'Medicações em uso'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _obs,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Comportamento e observações', hintText: 'Ex.: medo de secador'),
            ),
            SectionHeader('Vacinas',
                action: TextButton.icon(
                    onPressed: _addVaccine, icon: const Icon(Icons.add, size: 18), label: const Text('Adicionar'))),
            if (_vacinas.isEmpty)
              const Text('Nenhuma vacina registrada.', style: TextStyle(color: AppColors.muted))
            else
              ..._vacinas.asMap().entries.map((e) => AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.vaccines_outlined, color: AppColors.sage),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${e.value.nome} — ${formatDate(e.value.data)}'
                              '${e.value.proxima != null ? '\nPróxima: ${formatDate(e.value.proxima!)}' : ''}'),
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _vacinas.removeAt(e.key)),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(editing ? 'Salvar alterações' : 'Cadastrar pet')),
          ],
        ),
      ),
    );
  }
}
