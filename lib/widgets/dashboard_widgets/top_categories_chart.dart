import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';

class TopCategoriesChart extends StatelessWidget {
  const TopCategoriesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitNotifier>(
      builder: (context, habitNotifier, _) {
        final categoryCounts = <String, int>{};
        
        for (final habit in habitNotifier.habits) {
          final completedCount = habitNotifier.dailyRecords.where((record) => record.habitId == habit.id && record.isCompleted).length;
          categoryCounts[habit.category] = (categoryCounts[habit.category] ?? 0) + completedCount;
        }

        final pieData = categoryCounts.entries
            .map((entry) => _CategoryData(entry.key, entry.value.toDouble()))
            .toList();

        return SfCircularChart(
          title: ChartTitle(text: 'Principales Categorías con Hábitos Creados'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <CircularSeries<_CategoryData, String>>[
            DoughnutSeries<_CategoryData, String>(
              dataSource: pieData,
              xValueMapper: (_CategoryData data, _) => data.category,
              yValueMapper: (_CategoryData data, _) => data.count,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            )
          ],
        );
      },
    );
  }
}

class _CategoryData {
  _CategoryData(this.category, this.count);

  final String category;
  final double count;
}
