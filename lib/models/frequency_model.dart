// lib/models/frequency.dart
class Frequency {
  final String id; // id_frecuencia
  final String type; // tipo_frecuencia
  final String frequency; // frecuencia (nombre de la frecuencia)
  final String description; // descripción

  // Constructor
  Frequency({
    required this.id,
    required this.type,
    required this.frequency,
    required this.description,
  });

  // Método de fábrica para crear un objeto Frequency desde un mapa (por ejemplo, desde Firestore)
  factory Frequency.fromMap(Map<String, dynamic> data) {
    return Frequency(
      id: data['id_frecuencia'] ?? '', // Asigna un valor por defecto si no existe el campo
      type: data['tipo_frecuencia'] ?? 'No especificado', // Valor por defecto
      frequency: data['frecuencia'] ?? 'No especificado', // Valor por defecto
      description: data['descripcion'] ?? '', // Descripción vacía si no existe el campo
    );
  }

  // Método para convertir un objeto Frequency a un mapa (para guardar en Firestore o base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id_frecuencia': id,
      'tipo_frecuencia': type,
      'frecuencia': frequency,
      'descripcion': description,
    };
  }
}
