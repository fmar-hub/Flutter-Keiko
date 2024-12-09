import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/habit_count_chart.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/challenging_habit_count_chart.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/completed_days_chart.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/net_completed_days_chart.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/top_categories_chart.dart';
import 'package:flutter_keiko/widgets/dashboard_widgets/weekly_streak_bar.dart';
import 'package:flutter_keiko/widgets/monthly_calendar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keiko/notifiers/habit_notifier.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseHabitService _habitService = FirebaseHabitService();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _navigateToPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HabitCountChart(),
            const ChallengingHabitCountChart(),
            const CompletedDaysChart(),
            const NetCompletedDaysChart(),
            const TopCategoriesChart(),
          ],
        ),
      ),
    );
  }
}
