import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String? habitId; // Hacerlo opcional para tareas no guardadas aún
  String name;
  String description;
  bool completed;
  DateTime dueDate;
  String frequency;
  bool isTemporary; // Indica si la tarea está temporalmente en memoria

  Task({
    required this.id,
    this.habitId, // Puede ser nulo hasta que el hábito se guarde
    required this.name,
    required this.description,
    required this.completed,
    required this.dueDate,
    required this.frequency,
    this.isTemporary = true, // Por defecto será temporal
  });

  // Convertir el modelo Task a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'name': name,
      'description': description,
      'completed': completed,
      'dueDate': dueDate.toIso8601String(),
      'frequency': frequency,
    };
  }

  // Crear un modelo Task desde un mapa de Firestore
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      habitId: map['habitId'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      completed: map['completed'] ?? false,
      dueDate: DateTime.parse(map['dueDate']),
      frequency: map['frequency'] ?? '',
      isTemporary: false, // Tareas provenientes de Firestore no son temporales
    );
  }
}
