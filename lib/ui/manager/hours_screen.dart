import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';
import '../common/helpers.dart';
import '../common/widgets.dart';

class HoursScreen extends StatefulWidget {
  const HoursScreen({super.key});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  late int _abertura;
  late int _fechamento;
  late Set<int> _dias;
  late int _intervalo;
  late int _antecedencia;

  @override
  void initState() {
    super.initState();
    final h = context.read<AppData>().hours;
    _abertura = h.aberturaMin;
    _fechamento = h.fechamentoMin;
    _dias = {...h.diasFuncionamento};
    _intervalo = h.intervaloMin;
    _antecedencia = h.antecedenciaCancelamentoHoras;
  }

  Future<int?> _pickTime(int current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.read<AppData>();
    return Scaffold(
      appBar: AppBar(title: const Text('Horários')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionHeader('Expediente'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.sage),
                  title: const Text('Abertura'),
                  trailing: Text(formatMinutesOfDay(_abertura), style: const TextStyle(fontSize: 18)),
                  onTap: () async {
                    final v = await _pickTime(_abertura);
                    if (v != null) setState(() => _abertura = v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nightlight_outlined, color: AppColors.sage),
                  title: const Text('Fechamento'),
                  trailing: Text(formatMinutesOfDay(_fechamento), style: const TextStyle(fontSize: 18)),
                  onTap: () async {
                    final v = await _pickTime(_fechamento);
                    if (v != null) setState(() => _fechamento = v);
                  },
                ),
              ],
            ),
          ),
          const SectionHeader('Dias de funcionamento'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final d = i + 1;
              return FilterChip(
                label: Text(weekdayShort[d]!),
                selected: _dias.contains(d),
                onSelected: (v) => setState(() => v ? _dias.add(d) : _dias.remove(d)),
              );
            }),
          ),
          const SectionHeader('Intervalo entre horários'),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15 min')),
              ButtonSegment(value: 30, label: Text('30 min')),
              ButtonSegment(value: 60, label: Text('60 min')),
            ],
            selected: {_intervalo},
            onSelectionChanged: (s) => setState(() => _intervalo = s.first),
          ),
          const SectionHeader('Cancelamento/reagendamento pelo cliente'),
          Row(
            children: [
              IconButton(
                onPressed: _antecedencia > 0 ? () => setState(() => _antecedencia--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('Até $_antecedencia h antes', style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: _antecedencia < 72 ? () => setState(() => _antecedencia++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(
                context,
                () => data.updateBusinessHours(
                  currentUser(context),
                  BusinessHours(
                    aberturaMin: _abertura,
                    fechamentoMin: _fechamento,
                    diasFuncionamento: _dias,
                    intervaloMin: _intervalo,
                    antecedenciaCancelamentoHoras: _antecedencia,
                  ),
                ),
                success: 'Horários atualizados.',
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
