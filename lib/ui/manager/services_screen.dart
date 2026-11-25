import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final me = currentUser(context);
    final services = data.services.toList()
      ..sort((a, b) {
        final c = a.categoria.index.compareTo(b.categoria.index);
        return c != 0 ? c : a.nome.compareTo(b.nome);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Serviços e preços')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo serviço'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceFormScreen())),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: services.map((s) {
          final profs = data.qualifiedStaff(s.categoria).length;
          return AppCard(
            color: s.ativo ? Colors.white : AppColors.beige.withOpacity(0.5),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ServiceFormScreen(serviceId: s.id))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: s.categoria.color, shape: BoxShape.circle),
                  child: Icon(s.categoria.icon, color: AppColors.sageDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${formatMoney(s.preco)} · ${formatDuration(s.duracaoMin)} · ${s.etapas.length} etapas',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text('$profs profissional(is) habilitado(s)',
                          style: TextStyle(fontSize: 12, color: profs == 0 ? AppColors.danger : AppColors.muted)),
                    ],
                  ),
                ),
                Switch(
                  value: s.ativo,
                  onChanged: (v) => runAction(context, () => data.setServiceActive(me, s.id, v),
                      success: v ? 'Serviço ativado.' : 'Serviço desativado.'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key, this.serviceId});
  final String? serviceId;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _desc = TextEditingController();
  final _preco = TextEditingController();
  final _dur = TextEditingController();
  final _etapas = TextEditingController();
  ServiceCategory _cat = ServiceCategory.banho;
  ServiceModel? _original;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppData>().serviceById(widget.serviceId);
    if (s != null) {
      _original = s;
      _nome.text = s.nome;
      _desc.text = s.descricao;
      _preco.text = s.preco.toStringAsFixed(2).replaceAll('.', ',');
      _dur.text = '${s.duracaoMin}';
      _etapas.text = s.etapas.join('\n');
      _cat = s.categoria;
    } else {
      _etapas.text = 'Recepção\nProcedimento\nFinalização';
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _desc, _preco, _dur, _etapas]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = context.read<AppData>();
    final s = ServiceModel(
      id: _original?.id ?? newId(),
      nome: _nome.text.trim(),
      descricao: _desc.text.trim(),
      categoria: _cat,
      preco: parseMoney(_preco.text)!,
      duracaoMin: int.parse(_dur.text.trim()),
      etapas: _etapas.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      ativo: _original?.ativo ?? true,
    );
    final ok = await runAction(context, () => data.saveService(currentUser(context), s),
        success: 'Serviço salvo. Novos agendamentos já usam este preço.');
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_original == null ? 'Novo serviço' : 'Editar serviço')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome do serviço'),
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ServiceCategory>(
              value: _cat,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: ServiceCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _cat = v ?? _cat),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _preco,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço (R\$)', hintText: '89,90'),
                    validator: Validators.money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dur,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duração (min)'),
                    validator: (v) {
                      final e = Validators.positiveInt(v, campo: 'Duração');
                      if (e != null) return e;
                      return int.parse(v!.trim()) > 600 ? 'Máximo 600 min' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _etapas,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Etapas do procedimento (uma por linha)',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v ?? '').split('\n').where((e) => e.trim().isNotEmpty).isEmpty ? 'Informe ao menos uma etapa' : null,
            ),
            const SizedBox(height: 8),
            const Text(
              'As etapas formam a linha do tempo que o tutor acompanha. '
              'Alterar o preço não muda atendimentos já agendados.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
