import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';

class ChallengingHabitCountChart extends StatelessWidget {
  const ChallengingHabitCountChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<HabitNotifier>(context, listen: false).loadAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar datos'));
        } else {
          return Consumer<HabitNotifier>(
            builder: (context, habitNotifier, _) {
              final challengingHabits = habitNotifier.habits.where((habit) => habit.isChallenging).toList();
              print('Total de hábitos desfiantes: ${challengingHabits.length}');

              // Crear los datos del gráfico
              final chartData = [
                _HabitData('Desafiantes', challengingHabits.length.toDouble())
              ];

              print('Datos del gráfico: $chartData');

              return SfCircularChart(
                title: ChartTitle(text: 'Cantidad de Hábitos Desfiantes'),
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
