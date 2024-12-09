import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  Future<String> getMotivationalMessage(String habitsSummary) async {
    const String apiUrl = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo', // Modelo actualizado
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un experto motivador y crítico constructivo que ayuda a los usuarios a desarrollar y mantener hábitos efectivos. Evalúas cuidadosamente el hábito descrito y respondes de manera natural y conversacional. Si el hábito es claro, razonable y específico, brindas una evaluación positiva y consejos prácticos. Si no es claro o carece de sentido, proporcionas comentarios útiles y haces preguntas aclaratorias para guiar al usuario a mejorarlo. Tu objetivo es motivar sin sonar artificial ni mecánico.'
        },
        {
          'role': 'user',
          'content':
              'El hábito se describe como: $habitsSummary. Evalúa este hábito y proporciona una respuesta motivacional que incluya: 1) una breve evaluación del hábito, 2) una felicitación o motivación solo si el hábito es claro y positivo, 3) sugerencias concretas y prácticas para mejorarlo o adaptarlo, y 4) preguntas aclaratorias si es necesario.'
        }
      ],
      'max_tokens': 500, // Límite de tokens
    });

    try {
      final response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception(
            'Error al obtener respuesta de OpenAI: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión con OpenAI: $e');
    }
  }
}
