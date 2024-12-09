import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';
import 'package:flutter_keiko/utils/color_utils.dart';
import 'package:flutter_keiko/theme/theme_provider.dart';

class MonthlyCalendar extends StatefulWidget {
  final FirebaseHabitService habitService;
  final DateTime selectedDate;

  const MonthlyCalendar({super.key, required this.habitService, required this.selectedDate});

  @override
  _MonthlyCalendarState createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime _selectedDate;
  Future<List<DailyRecord>>? _monthlyRecords;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadMonthlyRecords();
  }

  void _loadMonthlyRecords() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _monthlyRecords = widget.habitService.getMonthlyRecords(userId, _selectedDate);
      });
    }
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      _loadMonthlyRecords();
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      _loadMonthlyRecords();
    });
  }

  List<DateTime> _generateDaysInMonth(DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    List<DateTime> daysInMonth = [];
    for (int i = 0; i < firstDayOfMonth.weekday - 1; i++) {
      daysInMonth.add(DateTime(firstDayOfMonth.year, firstDayOfMonth.month, 1 - (firstDayOfMonth.weekday - i - 1)));
    }
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      daysInMonth.add(DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1));
    }
    for (int i = lastDayOfMonth.weekday; i < 7; i++) {
      daysInMonth.add(DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day + i - lastDayOfMonth.weekday + 1));
    }
    return daysInMonth;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateToPreviousMonth,
                ),
                Text(
                  DateFormat.yMMMM().format(_selectedDate),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _navigateToNextMonth,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Lun"),
                Text("Mar"),
                Text("Mié"),
                Text("Jue"),
                Text("Vie"),
                Text("Sáb"),
                Text("Dom"),
              ],
            ),
          ),
          FutureBuilder<List<DailyRecord>>(
            future: _monthlyRecords,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("Error al cargar los datos"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay datos disponibles"));
              }

              final records = snapshot.data!;
              final daysInMonth = _generateDaysInMonth(_selectedDate);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: daysInMonth.length,
                itemBuilder: (context, index) {
                  final day = daysInMonth[index];
                  final dailyRecords = records.where((record) =>
                      record.date != null &&
                      record.date!.day == day.day &&
                      record.date!.month == day.month &&
                      record.date!.year == day.year).toList();
                  final dayColor = calculateDayColor(dailyRecords);

                  final isCurrentMonth = day.month == _selectedDate.month;

                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrentMonth ? dayColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: isCurrentMonth ? 1.0 : 0.5,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isCurrentMonth ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
