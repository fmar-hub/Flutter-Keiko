import 'package:flutter/material.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';

Color calculateDayColor(List<DailyRecord> records) {
  if (records.isEmpty) return Colors.white;

  final totalHabits = records.length;
  final completedHabits = records.where((record) => record.isCompleted).length;
  final completionRate = completedHabits / totalHabits;

  if (completionRate == 1) {
    return Colors.green[900]!;
  } else if (completionRate >= 0.75) {
    return Colors.green[700]!;
  } else if (completionRate >= 0.5) {
    return Colors.green[500]!;
  } else if (completionRate >= 0.25) {
    return Colors.green[300]!;
  } else {
    return Colors.red[100]!;
  }
}

