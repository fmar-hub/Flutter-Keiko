import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String id;
  String name;
  String description; // Agregado description
  String emoji;
  int color;
  bool isChallenging;
  int challengeDays;
  DateTime? startDate;
  DateTime? endDate;
  String category;

  Habit({
    required this.id,
    required this.name,
    required this.description, // Se agrega el parámetro description
    required this.emoji,
    required this.color,
    required this.isChallenging,
    required this.challengeDays,
    this.startDate, // Cambiado a opcional
    this.endDate, // Cambiado a opcional
    required this.category,
  });

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description, // Incluye description en el mapa
      'emoji': emoji,
      'color': color,
      'isChallenging': isChallenging,
      'challengeDays': challengeDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null, // Manejo seguro de nulos
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null, // Manejo seguro de nulos
      'category': category,
    };
  }

  // Convertir de Map (de Firestore) a objeto Habit
  static Habit fromMap(Map<String, dynamic> map, String id) {
    // Verificar que los campos nulos se manejen adecuadamente
    return Habit(
      id: id,
      name: map['name'] ?? 'Sin nombre', // Valor por defecto si es nulo
      description: map['description'] ?? '', // Valor por defecto si es nulo
      emoji: map['emoji'] ?? '😊', // Valor por defecto si es nulo
      color: map['color'] ?? 0xFF000000, // Valor por defecto si es nulo
      isChallenging: map['isChallenging'] ?? false, // Valor por defecto si es nulo
      challengeDays: map['challengeDays'] ?? 0, // Valor por defecto si es nulo
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null, // Manejo seguro
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null, // Manejo seguro
      category: map['category'] ?? 'General', // Valor por defecto si es nulo
    );
  }
}
