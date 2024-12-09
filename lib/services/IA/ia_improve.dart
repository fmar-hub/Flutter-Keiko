import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIImproveService {
  final String _apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  Future<Map<String, String>> improveHabitDetails({
    required String name,
    required String description,
  }) async {
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un asistente experto en productividad y desarrollo personal. Tu tarea es ayudar a los usuarios a mejorar los nombres y descripciones de sus hábitos para que sean más claros, motivadores y detallados. Devuelve siempre una respuesta en formato JSON con dos claves: "name" (el nombre mejorado) y "description" (la descripción mejorada).'
        },
        {
          'role': 'user',
          'content': '''
Mejora los siguientes detalles de un hábito:
- Nombre: "$name"
- Descripción: "$description"

Proporciona el resultado como un JSON con las claves "name" y "description".'''
        }
      ],
      'max_tokens':
          200, // Límite de tokens suficiente para nombre y descripción
    });

    try {
      final response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);
        final message = data['choices'][0]['message']['content'].trim();
        return Map<String, String>.from(jsonDecode(message));
      } else {
        throw Exception(
            'Error al obtener respuesta de OpenAI: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión con OpenAI: $e');
    }
  }
}
