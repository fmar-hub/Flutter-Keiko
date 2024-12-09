import 'package:flutter/material.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';

class HabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, DailyRecord> cachedDailyRecords;
  final void Function(String habitId) showAddNoteDialog;
  final Future<void> Function(String habitId, bool completed, String? notes) addDailyRecord;

  const HabitsList({
    super.key,
    required this.habits,
    required this.cachedDailyRecords,
    required this.showAddNoteDialog,
    required this.addDailyRecord,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final dailyRecord = cachedDailyRecords[habit.id];
        print('Hábito: ${habit.id}, Completado (DailyRecord): ${dailyRecord?.isCompleted ?? false}');

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(habit.color),
              child: Text(habit.emoji),
            ),
            title: Text(habit.name),
            subtitle: Text(habit.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.note_add),
                  onPressed: () {
                    showAddNoteDialog(habit.id);
                  },
                ),
                _HabitCheckbox(
                  habitId: habit.id,
                  isCompleted: dailyRecord?.isCompleted ?? false,
                  notes: dailyRecord?.notes,
                  addDailyRecord: addDailyRecord,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HabitCheckbox extends StatefulWidget {
  final String habitId;
  final bool isCompleted;
  final String? notes;
  final Future<void> Function(String habitId, bool completed, String? notes) addDailyRecord;

  const _HabitCheckbox({
    super.key,
    required this.habitId,
    required this.isCompleted,
    required this.notes,
    required this.addDailyRecord,
  });

  @override
  __HabitCheckboxState createState() => __HabitCheckboxState();
}

class __HabitCheckboxState extends State<_HabitCheckbox> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
    print('Inicialización Checkbox - Hábito: ${widget.habitId}, Completado: ${widget.isCompleted}');
  }

  @override
  void didUpdateWidget(covariant _HabitCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
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
    return Checkbox(
      value: _isCompleted,
      onChanged: (bool? value) async {
        if (value != null) {
          setState(() {
            _isCompleted = value;
          });
          await widget.addDailyRecord(widget.habitId, value, widget.notes);
        }
      },
    );
  }
}
