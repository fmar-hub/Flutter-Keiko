import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';
import 'package:flutter_keiko/services/firebase_habit_service.dart';

class HabitNotifier with ChangeNotifier {
  List<Habit> _habits = [];
  List<DailyRecord> _dailyRecords = [];
  final FirebaseHabitService habitService;

  HabitNotifier({required this.habitService}) {
    _setupListeners();
    loadAllData();
  }

  List<Habit> get habits => _habits;
  List<DailyRecord> get dailyRecords => _dailyRecords;

  List<DailyRecord> get weeklyRecords {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _dailyRecords.where((record) =>
        record.date != null &&
        record.date!.isAfter(startOfWeek) &&
        record.date!.isBefore(endOfWeek)).toList();
  }

  void _setupListeners() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado");
      return;
    }

    FirebaseFirestore.instance
        .collection('users_habits')
        .doc(userId)
        .collection('habits')
        .snapshots()
        .listen((snapshot) {
      _habits = snapshot.docs.map((doc) => Habit.fromMap(doc.data(), doc.id)).toList();
      _loadDailyRecords().then((_) => notifyListeners());
    });
  }

  Future<void> loadAllData() async {
    _habits.clear();
    _dailyRecords.clear();
    await _loadHabits();
    await _loadDailyRecords();
    notifyListeners();
  }

  Future<void> _loadHabits() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado en _loadHabits");
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users_habits').doc(userId).collection('habits').get();
      _habits = snapshot.docs.map((doc) => Habit.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
      print("Hábitos cargados: $_habits");
    } catch (e) {
      print("Error al cargar los hábitos: $e");
    }
  }

  Future<void> _loadDailyRecords() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado en _loadDailyRecords");
      return;
    }
    try {
      // Limpiar registros anteriores
      _dailyRecords.clear();

      for (var habit in _habits) {
        print("Obteniendo registros diarios para el hábito ${habit.id}");
        final snapshot = await FirebaseFirestore.instance
            .collection('users_habits')
            .doc(userId)
            .collection('habits')
            .doc(habit.id)
            .collection('dailyRecords')
            .get();
        print("Snapshot de registros diarios para el hábito ${habit.id}: ${snapshot.docs}");

        // Agregar registros únicos
        final newRecords = snapshot.docs.map((doc) => DailyRecord.fromMap(doc.data(), doc.id)).toList();
        for (var record in newRecords) {
          if (!_dailyRecords.any((r) => r.id == record.id)) {
            _dailyRecords.add(record);
          }
        }
      }
      notifyListeners();
      print("Registros diarios obtenidos: ${_dailyRecords.length}");
    } catch (e) {
      print("Error al cargar los registros diarios: $e");
    }
  }

  Future<void> toggleCompletionStatus(DailyRecord record) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado");
      return;
    }

    try {
      final updatedRecord = record.copyWith(isCompleted: !record.isCompleted);
      await FirebaseFirestore.instance
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .doc(updatedRecord.habitId)
          .collection('dailyRecords')
          .doc(updatedRecord.id)
          .update(updatedRecord.toMap());

      _dailyRecords[_dailyRecords.indexWhere((r) => r.id == record.id)] = updatedRecord;
      notifyListeners();
    } catch (e) {
      print("Error al actualizar el estado de finalización: $e");
    }
  }

  Future<void> addDailyRecord(DailyRecord dailyRecord) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .doc(dailyRecord.habitId)
          .collection('dailyRecords')
          .doc(dailyRecord.id)
          .set(dailyRecord.toMap());

      // Verificar y agregar el registro diario si no existe
      if (!_dailyRecords.any((r) => r.id == dailyRecord.id)) {
        _dailyRecords.add(dailyRecord);
        notifyListeners();
      }
    } catch (e) {
      print("Error al añadir el registro diario: $e");
    }
  }
}
