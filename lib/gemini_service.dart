import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Modelo simple para actividades generadas por IA
class ActividadGenerada {
  final String nombre;
  final String descripcion;
  final int puntosBase;
  final int duracion;
  final String categoria;

  ActividadGenerada({
    required this.nombre,
    required this.descripcion,
    required this.puntosBase,
    required this.duracion,
    required this.categoria,
  });
}

class GeminiService {
  late final GenerativeModel _model;
  
  // NOTA: Esta es una API Key temporal de desarrollo
  // Para producción, obtén tu propia key en: https://aistudio.google.com/app/apikey
  // y reemplázala aquí o usa variables de entorno
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Dejamos vacío para que uses tu propia key
  );

  GeminiService({String? apiKey}) {
    final key = apiKey ?? _apiKey;
    
    if (key.isEmpty) {
      throw Exception(
        '⚠️ API Key de Gemini no configurada.\n\n'
        'Para usar la generación de actividades con IA:\n'
        '1. Obtén tu API key gratuita en: https://aistudio.google.com/app/apikey\n'
        '2. Pasa la key al constructor: GeminiService(apiKey: "tu-key")\n'
        '   O configúrala como variable de entorno GEMINI_API_KEY'
      );
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: key,
    );
  }

  /// Genera actividades diarias personalizadas para un usuario
  Future<List<ActividadGenerada>> generarActividadesDiarias({
    required String nombreUsuario,
    String? sexo,
    int? edad,
    String nivel = 'intermedio',
    int cantidadActividades = 5,
  }) async {
    try {
      final prompt = '''
Eres un entrenador deportivo experto. Genera exactamente $cantidadActividades actividades deportivas variadas para hoy.

Información del usuario:
- Nombre: $nombreUsuario
${sexo != null ? '- Sexo: $sexo' : ''}
${edad != null ? '- Edad: $edad años' : ''}
- Nivel de fitness: $nivel

Instrucciones:
1. Crea actividades VARIADAS (cardio, fuerza, flexibilidad, deportes, etc.)
2. Ajusta la intensidad al nivel del usuario
3. Cada actividad debe tener:
   - nombre: Nombre corto y atractivo (máximo 20 caracteres)
   - descripcion: Descripción motivadora y específica (2-3 líneas)
   - puntosBase: Entre 30 y 100 puntos según dificultad
   - duracion: Tiempo estimado en minutos
   - categoria: Una de [cardio, fuerza, flexibilidad, deportes, bienestar]

Responde SOLO con un JSON válido en este formato exacto:
{
  "actividades": [
    {
      "nombre": "Nombre corto",
      "descripcion": "Descripción motivadora",
      "puntosBase": 50,
      "duracion": 30,
      "categoria": "cardio"
    }
  ]
}

NO agregues texto adicional, SOLO el JSON.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('No se recibió respuesta de Gemini');
      }

      // Limpiar la respuesta (remover markdown si existe)
      String jsonText = response.text!.trim();
      jsonText = jsonText.replaceAll('```json', '').replaceAll('```', '').trim();

      // Parsear JSON
      final Map<String, dynamic> jsonResponse = json.decode(jsonText);
      final List<dynamic> actividadesJson = jsonResponse['actividades'];

      // Convertir a objetos ActividadGenerada
      final List<ActividadGenerada> actividades = [];
      for (int i = 0; i < actividadesJson.length; i++) {
        final actJson = actividadesJson[i];
        actividades.add(ActividadGenerada(
          nombre: actJson['nombre'],
          descripcion: actJson['descripcion'],
          puntosBase: actJson['puntosBase'],
          duracion: actJson['duracion'] ?? 30,
          categoria: actJson['categoria'] ?? 'deportes',
        ));
      }

      return actividades;
    } catch (e) {
      print('Error al generar actividades con Gemini: $e');
      // Devolver actividades por defecto en caso de error
      return _actividadesPorDefecto();
    }
  }

  /// Genera actividades alternativas para usuarios que quieren algo diferente
  Future<List<ActividadGenerada>> generarActividadesAlternativas({
    required String nombreUsuario,
    required List<String> actividadesExistentes,
    String? sexo,
    int? edad,
    String nivel = 'intermedio',
  }) async {
    try {
      final actividadesStr = actividadesExistentes.join(', ');
      final prompt = '''
Eres un entrenador deportivo creativo. Genera 5 actividades deportivas DIFERENTES a estas que el usuario ya tiene: $actividadesStr

Información del usuario:
- Nombre: $nombreUsuario
${sexo != null ? '- Sexo: $sexo' : ''}
${edad != null ? '- Edad: $edad años' : ''}
- Nivel de fitness: $nivel

Instrucciones:
1. Las actividades deben ser COMPLETAMENTE DIFERENTES a las mencionadas
2. Sé creativo y ofrece variedad (yoga, natación, ciclismo, boxeo, etc.)
3. Ajusta la intensidad al nivel del usuario
4. Cada actividad debe tener:
   - nombre: Nombre corto y atractivo (máximo 20 caracteres)
   - descripcion: Descripción motivadora y específica (2-3 líneas)
   - puntosBase: Entre 30 y 100 puntos según dificultad
   - duracion: Tiempo estimado en minutos
   - categoria: Una de [cardio, fuerza, flexibilidad, deportes, bienestar]

Responde SOLO con un JSON válido en este formato exacto:
{
  "actividades": [
    {
      "nombre": "Nombre corto",
      "descripcion": "Descripción motivadora",
      "puntosBase": 50,
      "duracion": 30,
      "categoria": "cardio"
    }
  ]
}

NO agregues texto adicional, SOLO el JSON.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('No se recibió respuesta de Gemini');
      }

      // Limpiar la respuesta
      String jsonText = response.text!.trim();
      jsonText = jsonText.replaceAll('```json', '').replaceAll('```', '').trim();

      // Parsear JSON
      final Map<String, dynamic> jsonResponse = json.decode(jsonText);
      final List<dynamic> actividadesJson = jsonResponse['actividades'];

      // Convertir a objetos ActividadGenerada
      final List<ActividadGenerada> actividades = [];
      for (int i = 0; i < actividadesJson.length; i++) {
        final actJson = actividadesJson[i];
        actividades.add(ActividadGenerada(
          nombre: actJson['nombre'],
          descripcion: actJson['descripcion'],
          puntosBase: actJson['puntosBase'],
          duracion: actJson['duracion'] ?? 30,
          categoria: actJson['categoria'] ?? 'deportes',
        ));
      }

      return actividades;
    } catch (e) {
      print('Error al generar actividades alternativas: $e');
      return _actividadesPorDefecto();
    }
  }

  /// Actividades por defecto en caso de error
  List<ActividadGenerada> _actividadesPorDefecto() {
    return [
      ActividadGenerada(
        nombre: 'Caminata 30min',
        descripcion: 'Camina a paso moderado durante 30 minutos. Ideal para empezar el día.',
        puntosBase: 40,
        duracion: 30,
        categoria: 'cardio',
      ),
      ActividadGenerada(
        nombre: 'Flexiones x20',
        descripcion: 'Realiza 20 flexiones de pecho. Descansa si es necesario.',
        puntosBase: 35,
        duracion: 10,
        categoria: 'fuerza',
      ),
      ActividadGenerada(
        nombre: 'Estiramiento',
        descripcion: 'Sesión de estiramiento completo. Mejora tu flexibilidad.',
        puntosBase: 30,
        duracion: 15,
        categoria: 'flexibilidad',
      ),
    ];
  }
}
