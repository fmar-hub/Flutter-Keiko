import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';

class WeeklyStreakBar extends StatelessWidget {
  const WeeklyStreakBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitNotifier>(
      builder: (context, habitNotifier, _) {
        final weeklyRecords = habitNotifier.weeklyRecords;

        weeklyRecords.forEach((record) {
          if (record == null) {
            print('Null record found in weeklyRecords');
          } else {
            print('Racha Semanal - Registro: ${record.habitId}, Completado: ${record.isCompleted}');
          }
        });


        return Column(
          children: [
            const Text(
              'Racha Semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = index < weeklyRecords.length ? weeklyRecords[index] : null;
                final isCompleted = day?.isCompleted ?? false;
                return _StreakIndicator(
                  dayIndex: index,
                  isCompleted: isCompleted,
                  day: day,
                );
              }),
            ),
          ],
        );
      },
    );
  }

  String _dayAbbreviation(int index) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[index];
  }

  void _showHabitsDialog(BuildContext context, DailyRecord day) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hábitos del ${_dayAbbreviation(day.date!.weekday)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hábito: ${day.habitId}'),
              Text('Completado: ${day.isCompleted ? "Sí" : "No"}'),
              Text('Notas: ${day.notes}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _StreakIndicator extends StatefulWidget {
  final int dayIndex;
  final bool isCompleted;
  final DailyRecord? day;

  const _StreakIndicator({
    super.key,
    required this.dayIndex,
    required this.isCompleted,
    required this.day,
  });

  @override
  __StreakIndicatorState createState() => __StreakIndicatorState();
}

class __StreakIndicatorState extends State<_StreakIndicator> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  void didUpdateWidget(covariant _StreakIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _isCompleted = widget.isCompleted;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.day != null ? () => _showHabitsDialog(context, widget.day!) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isCompleted ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _dayAbbreviation(widget.dayIndex),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _dayAbbreviation(int index) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[index];
  }

  void _showHabitsDialog(BuildContext context, DailyRecord day) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hábitos del ${_dayAbbreviation(day.date!.weekday)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hábito: ${day.habitId}'),
              Text('Completado: ${day.isCompleted ? "Sí" : "No"}'),
              Text('Notas: ${day.notes}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
