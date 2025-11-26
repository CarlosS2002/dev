import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _apiKey = 'AIzaSyCNiGJWdMHbhwLaPEFN2Otpu3xugXAIySc';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Genera actividades personalizadas usando IA
  /// [sexo] - 'Masculino' o 'Femenino'
  /// [edad] - Edad del usuario
  /// [tipoActividad] - Tipo de actividad seleccionada (ej: 'Cardio', 'Fuerza', etc.)
  /// [cantidad] - Número de actividades a generar
  Future<List<Map<String, dynamic>>> generarActividades({
    required String sexo,
    required int edad,
    required String tipoActividad,
    int cantidad = 3,
  }) async {
    try {
      final prompt = '''
Eres un entrenador personal experto. Genera exactamente $cantidad actividades de entrenamiento para una persona con las siguientes características:
- Sexo: $sexo
- Edad: $edad años
- Tipo de entrenamiento deseado: $tipoActividad

Para cada actividad, proporciona:
1. nombre: Un nombre corto y descriptivo (máximo 30 caracteres)
2. descripcion: Una descripción detallada del ejercicio incluyendo duración, repeticiones o series según corresponda (máximo 150 caracteres)
3. puntos: Un valor entre 10 y 150 basado en la intensidad y duración del ejercicio

Responde ÚNICAMENTE con un JSON válido en el siguiente formato, sin texto adicional ni explicaciones:
{
  "actividades": [
    {
      "nombre": "Nombre del ejercicio",
      "descripcion": "Descripción detallada del ejercicio",
      "puntos": 50
    }
  ]
}

Adapta la intensidad y tipo de ejercicios según la edad y sexo del usuario. Para personas mayores, sugiere ejercicios de menor impacto. Para jóvenes, puedes incluir ejercicios más intensos.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extraer el texto de la respuesta
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        print('🤖 Respuesta de IA: $text');
        
        // Limpiar el texto para extraer solo el JSON
        String jsonText = text.trim();
        
        // Remover marcadores de código si existen
        if (jsonText.contains('```json')) {
          jsonText = jsonText.replaceAll('```json', '').replaceAll('```', '');
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.replaceAll('```', '');
        }
        
        jsonText = jsonText.trim();
        
        // Parsear el JSON
        final jsonData = jsonDecode(jsonText);
        final actividades = jsonData['actividades'] as List;
        
        return actividades.map((a) => {
          'nombre': a['nombre']?.toString() ?? 'Actividad',
          'descripcion': a['descripcion']?.toString() ?? '',
          'puntos': (a['puntos'] is int) ? a['puntos'] : int.tryParse(a['puntos'].toString()) ?? 50,
        }).toList();
      } else {
        print('❌ Error de API: ${response.statusCode} - ${response.body}');
        throw Exception('Error al generar actividades: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en AIService: $e');
      rethrow;
    }
  }

  /// Lista de tipos de actividades disponibles
  static List<String> get tiposActividad => [
    'Cardio (correr, saltar, etc.)',
    'Fuerza (pesas, resistencia)',
    'Flexibilidad (yoga, estiramientos)',
    'HIIT (alta intensidad)',
    'Resistencia (ejercicios prolongados)',
    'Funcional (movimientos cotidianos)',
    'Core (abdominales, espalda)',
    'Bajo impacto (articulaciones)',
    'Equilibrio y coordinación',
    'Relajación (meditación, respiración)',
  ];
}
