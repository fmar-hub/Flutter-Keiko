import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';

class NetCompletedDaysChart extends StatelessWidget {
  const NetCompletedDaysChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitNotifier>(
      builder: (context, habitNotifier, _) {
        final totalDays = habitNotifier.dailyRecords.length;
        final netCompleted = habitNotifier.dailyRecords.fold<int>(
          0,
          (sum, record) => sum + (record.isCompleted ? 1 : -1),
        );

        // Asegurarnos de que el valor del progreso sea válido
        final progress = totalDays > 0 ? netCompleted / totalDays : 0.0;

        return Column(
          children: [
            Text(
              'Días Completados: $netCompleted de $totalDays',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress.isNaN ? 0.0 : progress, // Si el progreso es NaN, establecerlo en 0.0
              backgroundColor: Colors.red[100],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        );
      },
    );
  }
}
