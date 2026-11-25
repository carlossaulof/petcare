import 'package:flutter/material.dart';

import '../../core/theme.dart';

class ChartPoint {
  final String label;
  final double value;
  final String? valueLabel;
  const ChartPoint(this.label, this.value, {this.valueLabel});
}

/// Gráfico de colunas simples (sem dependências externas).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.points, this.height = 180, this.highlightLast = true});
  final List<ChartPoint> points;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(points.length, (i) {
          final p = points[i];
          final ratio = max == 0 ? 0.0 : p.value / max;
          final isLast = highlightLast && i == points.length - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(p.valueLabel ?? p.value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: ratio == 0 ? 0.02 : ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLast ? AppColors.sageDark : AppColors.sage.withOpacity(0.55),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.label, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Barras horizontais (ranking, distribuição por categoria).
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({super.key, required this.points, this.colors});
  final List<ChartPoint> points;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Sem dados no período.', style: TextStyle(color: AppColors.muted)),
      );
    }
    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    return Column(
      children: List.generate(points.length, (i) {
        final p = points[i];
        final color = colors != null && colors!.isNotEmpty ? colors![i % colors!.length] : AppColors.sage;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.label, style: const TextStyle(fontSize: 13))),
                  Text(p.valueLabel ?? p.value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : p.value / max,
                  minHeight: 10,
                  backgroundColor: AppColors.cream,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
