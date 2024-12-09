import 'package:cloud_firestore/cloud_firestore.dart';

class DailyRecord {
  String id; // ID generado por Firebase
  String habitId; // ID del hábito al que pertenece el registro
  bool isCompleted;
  DateTime? date;
  String notes;  // Campo de notas

  // Constructor
  DailyRecord({
    String? id, // El ID puede estar vacío hasta que se cree el documento
    required this.habitId,
    this.isCompleted = false,
    required this.date,
    required this.notes,  // Notas añadidas
  }) : id = id ?? FirebaseFirestore.instance.collection('dailyRecords').doc().id;

  // Convertir el objeto DailyRecord a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'isCompleted': isCompleted,
      'date': date != null ? Timestamp.fromDate(date!) : null, // Convertimos la fecha solo si no es nula
      'notes': notes,  // Incluir el campo de notas en el mapa
    };
  }

  // Convertir un mapa de Firestore a un objeto DailyRecord
  static DailyRecord fromMap(Map<String, dynamic> map, String id) {
    return DailyRecord(
      id: id, // Asignamos el ID de Firestore al objeto
      habitId: map['habitId'] ?? '', // Garantizamos que habitId nunca sea null
      isCompleted: map['isCompleted'] ?? false, // Valor predeterminado para isCompleted si es null
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : null, // Convertimos el Timestamp a DateTime, manejamos null
      notes: map['notes'] ?? '',  // Si no hay notas, asignar una cadena vacía
    );
  }

  // Método copyWith para crear una nueva instancia con algunos valores modificados
  DailyRecord copyWith({
    String? id,
    String? habitId,
    bool? isCompleted,
    DateTime? date,
    String? notes,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
