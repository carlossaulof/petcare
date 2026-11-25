import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/app_data.dart';

/// Seleção de data (próximos 21 dias) e horário disponível em tempo real.
class SlotPicker extends StatefulWidget {
  const SlotPicker({
    super.key,
    required this.service,
    required this.selected,
    required this.onChanged,
    this.petId,
    this.ignoreAppointmentId,
  });

  final ServiceModel service;
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;
  final String? petId;
  final String? ignoreAppointmentId;

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = dateOnly(widget.selected ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final today = dateOnly(DateTime.now());
    final days = List.generate(21, (i) => today.add(Duration(days: i)));
    final slots = data.availableSlots(_day, widget.service,
        petId: widget.petId, ignoreId: widget.ignoreAppointmentId);
    final open = data.hours.diasFuncionamento.contains(_day.weekday);

    // Se o horário escolhido deixou de estar livre (outro usuário agendou), limpa.
    final sel = widget.selected;
    if (sel != null && isSameDay(sel, _day) && !slots.contains(sel)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(null);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              final isSel = isSameDay(d, _day);
              final closed = !data.hours.diasFuncionamento.contains(d.weekday);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _day = d);
                  widget.onChanged(null);
                },
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.sage : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? AppColors.sage : AppColors.beige),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weekdayShort[d.weekday]!,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSel ? Colors.white : (closed ? AppColors.beigeDark : AppColors.muted))),
                      Text('${d.day}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isSel ? Colors.white : (closed ? AppColors.beigeDark : AppColors.ink))),
                      Text(two(d.month),
                          style: TextStyle(fontSize: 10, color: isSel ? Colors.white70 : AppColors.muted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(formatLongDate(_day), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (!open)
          const Text('O petshop não abre neste dia.', style: TextStyle(color: AppColors.muted))
        else if (slots.isEmpty)
          const Text('Sem horários livres para este serviço nesta data.', style: TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((s) {
              final isSel = sel != null && s.isAtSameMomentAs(sel);
              return ChoiceChip(
                label: Text(formatTime(s)),
                selected: isSel,
                onSelected: (_) => widget.onChanged(s),
              );
            }).toList(),
          ),
      ],
    );
  }
}
