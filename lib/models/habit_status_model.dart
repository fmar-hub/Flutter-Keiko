import 'package:flutter_keiko/models/habit_model.dart';

class HabitStatus {
  Habit habit;
  bool isCompleted;
  String? notes;

  HabitStatus({
    required this.habit,
    this.isCompleted = false,
    this.notes,
  });

  // Convertir el objeto a un mapa asegurando que 'notes' no sea nulo
  Map<String, dynamic> toMap() {
    return {
      'habit': habit.toMap(),
      'isCompleted': isCompleted,
      'notes': notes ?? '', // Si 'notes' es nulo, se asigna una cadena vacía
    };
  }

  // Crear un objeto a partir de un mapa, asegurando que 'notes' no sea nulo
  static HabitStatus fromMap(Map<String, dynamic> map) {
    return HabitStatus(
      habit: Habit.fromMap(map['habit'] as Map<String, dynamic>, map['habit']['id'] as String),
      isCompleted: map['isCompleted'] as bool? ?? false, // Si 'isCompleted' es nulo, se asigna 'false'
      notes: map['notes'] as String? ?? '', // Si 'notes' es nulo, se asigna una cadena vacía
    );
  }
}
