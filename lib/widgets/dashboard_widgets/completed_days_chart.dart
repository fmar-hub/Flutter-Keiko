import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:intl/intl.dart';

class CompletedDaysChart extends StatelessWidget {
  const CompletedDaysChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitNotifier>(
      builder: (context, habitNotifier, _) {
        return SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Cantidad de Días Completados al 100%'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <ChartSeries<_DayData, String>>[
            BarSeries<_DayData, String>(
              dataSource: habitNotifier.dailyRecords.map((record) {
                // Verifica si todas las tareas del hábito del día están completadas
                final allCompleted = record.isCompleted;
                return _DayData(DateFormat.yMd().format(record.date ?? DateTime.now()), allCompleted ? 1 : 0);
              }).toList(),
              xValueMapper: (_DayData data, _) => data.day,
              yValueMapper: (_DayData data, _) => data.completed,
              name: 'Completados',
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

class _DayData {
  _DayData(this.day, this.completed);

  final String day;
  final double completed;
}
