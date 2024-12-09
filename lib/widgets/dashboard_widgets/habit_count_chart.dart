import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';

class HabitCountChart extends StatelessWidget {
  const HabitCountChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitNotifier>(
      builder: (context, habitNotifier, _) {
        // Crear los datos del gráfico para mostrar el total de hábitos creados
        final totalHabits = habitNotifier.habits.length;
        final chartData = [_HabitData('Total de Hábitos', totalHabits.toDouble())];

        return SfCircularChart(
          title: ChartTitle(text: 'Cantidad de Hábitos Creados'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CircularSeries<_HabitData, String>>[
            PieSeries<_HabitData, String>(
              dataSource: chartData,
              xValueMapper: (_HabitData data, _) => data.label,
              yValueMapper: (_HabitData data, _) => data.value,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

class _HabitData {
  _HabitData(this.label, this.value);

  final String label;
  final double value;

  @override
  String toString() {
    return '{label: $label, value: $value}';
  }
}
