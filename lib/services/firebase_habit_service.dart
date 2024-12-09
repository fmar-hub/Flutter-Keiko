import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_keiko/models/habit_model.dart';
import 'package:flutter_keiko/models/daily_record_model.dart';

class FirebaseHabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveHabit(Habit habit) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado en saveHabit");
      throw Exception("Usuario no autenticado");
    }
    try {
      await _firestore.collection('users_habits').doc(userId).collection('habits').add(habit.toMap());
      print("Hábito guardado para el usuario $userId");
    } catch (e) {
      print("Error al guardar el hábito: $e");
      throw Exception("Error al guardar el hábito: $e");
    }
  }

  Future<List<Habit>> getActiveHabitsToday() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("Error: Usuario no autenticado en getActiveHabitsToday");
      throw Exception("Usuario no autenticado");
    }
    try {
      final now = DateTime.now();
      QuerySnapshot querySnapshot = await _firestore
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      return querySnapshot.docs.map((doc) {
        final docData = doc.data();
        if (docData == null) {
          print("Error: Datos del hábito son nulos para el documento ${doc.id}");
          return null;
        }
        return Habit.fromMap(docData as Map<String, dynamic>, doc.id);
      }).whereType<Habit>().toList();
    } catch (e) {
      print("Error al cargar los hábitos activos: $e");
      throw Exception("Error al cargar los hábitos activos: $e");
    }
  }

  Future<void> addDailyRecord(String userId, String habitId, bool completed, String? notes) async {
    try {
      final habitSnapshot = await _firestore
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

      if (!habitSnapshot.exists) {
        print("Error: Hábito $habitId no encontrado para el usuario $userId");
        throw Exception("Hábito no encontrado");
      }

      final habitData = habitSnapshot.data();
      if (habitData == null) {
        print("Error: Datos del hábito son nulos");
        throw Exception("Datos del hábito son nulos");
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final existingRecord = await getDailyRecordByDate(userId, habitId, now);
      if (existingRecord == null) {
        final dailyRecord = DailyRecord(
          habitId: habitId,
          isCompleted: completed,
          date: startOfDay,
          notes: notes ?? '',
        );

        await _firestore
            .collection('users_habits')
            .doc(userId)
            .collection('habits')
            .doc(habitId)
            .collection('dailyRecords')
            .add(dailyRecord.toMap());
      } else {
        existingRecord.isCompleted = completed;
        existingRecord.notes = notes ?? existingRecord.notes;

        await _firestore
            .collection('users_habits')
            .doc(userId)
            .collection('habits')
            .doc(habitId)
            .collection('dailyRecords')
            .doc(existingRecord.id)
            .update(existingRecord.toMap());
      }
    } catch (e) {
      print("Error al agregar el registro diario: $e");
      throw Exception("Error al agregar el registro diario: $e");
    }
  }

  Future<void> updateDailyRecord(String userId, String habitId, bool isCompleted, String notes) async {
    final dailyRecord = {
      'isCompleted': isCompleted,
      'notes': notes,
    };

    final dailyRecordSnapshot = await _firestore.collection('users_habits').doc(userId).collection('habits').doc(habitId).collection('dailyRecords')
        .where('date', isEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
        .get();

    if (dailyRecordSnapshot.docs.isNotEmpty) {
      await _firestore.collection('users_habits').doc(userId).collection('habits').doc(habitId).collection('dailyRecords').doc(dailyRecordSnapshot.docs.first.id).update(dailyRecord);
    }
  }

  Future<DailyRecord?> getDailyRecordByDate(String userId, String habitId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);

      final querySnapshot = await _firestore
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .collection('dailyRecords')
          .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final docData = doc.data();

      return DailyRecord.fromMap(docData, doc.id);
    } catch (e) {
      print("Error al obtener el registro diario: $e");
      throw Exception("Error al obtener el registro diario: $e");
    }
  }

  Future<List<DailyRecord>> getMonthlyRecords(String userId, DateTime date) async {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    print("Obteniendo registros mensuales para el usuario $userId desde $firstDayOfMonth hasta $lastDayOfMonth");

    try {
      final snapshot = await _firestore
          .collection('users_habits')
          .doc(userId)
          .collection('habits')
          .get();

      List<DailyRecord> monthlyRecords = [];

      for (var habitDoc in snapshot.docs) {
        print("Obteniendo registros diarios para el hábito ${habitDoc.id}");
        final dailyRecordsSnapshot = await _firestore
            .collection('users_habits')
            .doc(userId)
            .collection('habits')
            .doc(habitDoc.id)
            .collection('dailyRecords')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
            .get();

        for (var doc in dailyRecordsSnapshot.docs) {
          final docData = doc.data();
          try {
            final dailyRecord = DailyRecord.fromMap(docData, doc.id);
            monthlyRecords.add(dailyRecord);
          } catch (e) {
            print("Error al convertir el registro diario: $e");
          }
        }
      }

      print("Registros mensuales obtenidos para el usuario $userId: $monthlyRecords");
      return monthlyRecords;
    } catch (e) {
      print("Error al obtener los registros mensuales: $e");
      throw Exception("Error al obtener los registros mensuales: $e");
    }
  }
}
