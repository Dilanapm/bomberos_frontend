/// Configuración de simulación de detección EPP por video.
///
/// Cada entrada mapea el número de video (extraído del nombre del
/// archivo, p.ej. "video_1.mp4" → número 1) a su [SimulationStepConfig].
class SimulationStepConfig {
  const SimulationStepConfig({
    required this.secondToStepId,
    required this.evaluationResult,
  });

  /// Map: segundo transcurrido → paso_id que se confirma en ese segundo.
  final Map<int, int> secondToStepId;

  /// Resultado simulado con el mismo esquema que devuelve FastAPI.
  /// NOTA: session_id se inyecta dinámicamente en _evaluateWithGRU.
  final Map<String, dynamic> evaluationResult;
}

class SimulationConfig {
  SimulationConfig._();

  /// Patrón de nombre de archivo: video_N.mp4 (case-insensitive).
  static final RegExp _pattern =
      RegExp(r'video_(\d+)\.mp4', caseSensitive: false);

  /// Extrae el número de video del nombre/path del archivo.
  static int? videoNumberFromPath(String path) {
    final name = path.replaceAll('\\', '/').split('/').last;
    final match = _pattern.firstMatch(name);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Retorna la config para el video N, o null si no existe.
  static SimulationStepConfig? forVideo(int videoNumber) =>
      _configs[videoNumber];

  // ── Configuraciones por video ─────────────────────────────────────────────

  static final Map<int, SimulationStepConfig> _configs = {

    // ── Video 1 ──────────────────────────────────────────────────────────────
    // Pasos fuera de orden: Casco (paso 4) detectado antes que Esclavina (paso 2)
    1: SimulationStepConfig(
      secondToStepId: const {
        10: 0, // Pantalón Ignífugo  → s10
        43: 3, // Casco              → s43
        45: 1, // Esclavina          → s45
        70: 2, // Chaqueta Ignífuga  → s70
        94: 4, // Guantes            → s94
        99: 5, // Postura Final      → s99
      },
      evaluationResult: const {
        'precision':    0.772,
        'total_ventanas': 120,
        'correctos':  ['pantalon_ignifugo', 'chaqueta_ignifuga', 'guantes'],
        'incorrectos': ['esclavina', 'casco', 'postura_final'],
        'scores': {
          'pantalon_ignifugo': 0.88,
          'esclavina':         0.72,
          'chaqueta_ignifuga': 0.79,
          'casco':             0.65,
          'guantes':           0.91,
          'postura_final':     0.68,
        },
        'laravel_payload': {
          'general_score':         77.2,
          'total_steps':           6,
          'steps_completed':       6,
          'correct_order':         false,
          'duration_seconds':      99.0,
          'total_frames':          1188,
          'frames_with_detection': 980,
          'detection_rate':        82.5,
          'steps_evaluation': [
            {
              'step_number': 1, 'step_name': 'Pantalón Ignífugo',
              'score': 0.88, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 0.0, 'time_end': 10.0, 'duration': 10.0,
            },
            {
              'step_number': 2, 'step_name': 'Esclavina',
              'score': 0.72, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 43.0, 'time_end': 45.0, 'duration': 2.0,
            },
            {
              'step_number': 3, 'step_name': 'Chaqueta Ignífuga',
              'score': 0.79, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 45.0, 'time_end': 70.0, 'duration': 25.0,
            },
            {
              'step_number': 4, 'step_name': 'Casco',
              'score': 0.65, 'status': 'correcto', 'detected': true,
              'feedback': 'Detectado fuera de orden',
              'time_start': 10.0, 'time_end': 43.0, 'duration': 33.0,
            },
            {
              'step_number': 5, 'step_name': 'Guantes',
              'score': 0.91, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 70.0, 'time_end': 94.0, 'duration': 24.0,
            },
            {
              'step_number': 6, 'step_name': 'Postura Final',
              'score': 0.68, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 94.0, 'time_end': 99.0, 'duration': 5.0,
            },
          ],
        },
      },
    ),

    // ── Video 2 ──────────────────────────────────────────────────────────────
    // Pasos en orden correcto: 0→1→2→3→4→5
    2: SimulationStepConfig(
      secondToStepId: const {
        13:  0, // Pantalón Ignífugo  → s13
        41:  1, // Esclavina          → s41
        55:  2, // Chaqueta Ignífuga  → s55
        84:  3, // Casco              → s84
        94:  4, // Guantes            → s94
        101: 5, // Postura Final      → s101
      },
      evaluationResult: const {
        'precision':    0.782,
        'total_ventanas': 140,
        'correctos':  [
          'pantalon_ignifugo', 'chaqueta_ignifuga',
          'casco', 'postura_final',
        ],
        'incorrectos': ['esclavina', 'guantes'],
        'scores': {
          'pantalon_ignifugo': 0.94,
          'esclavina':         0.63,
          'chaqueta_ignifuga': 0.81,
          'casco':             0.75,
          'guantes':           0.69,
          'postura_final':     0.87,
        },
        'laravel_payload': {
          'general_score':         78.2,
          'total_steps':           6,
          'steps_completed':       6,
          'correct_order':         true,
          'duration_seconds':      101.0,
          'total_frames':          1212,
          'frames_with_detection': 1050,
          'detection_rate':        86.6,
          'steps_evaluation': [
            {
              'step_number': 1, 'step_name': 'Pantalón Ignífugo',
              'score': 0.94, 'status': 'correcto', 'detected': true,
              'feedback': 'Excelente colocación',
              'time_start': 0.0, 'time_end': 13.0, 'duration': 13.0,
            },
            {
              'step_number': 2, 'step_name': 'Esclavina',
              'score': 0.63, 'status': 'incorrecto', 'detected': true,
              'feedback': 'Se detectó, pero con ejecución incompleta',
              'time_start': 13.0, 'time_end': 41.0, 'duration': 28.0,
            },
            {
              'step_number': 3, 'step_name': 'Chaqueta Ignífuga',
              'score': 0.81, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 41.0, 'time_end': 55.0, 'duration': 14.0,
            },
            {
              'step_number': 4, 'step_name': 'Casco',
              'score': 0.75, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 55.0, 'time_end': 84.0, 'duration': 29.0,
            },
            {
              'step_number': 5, 'step_name': 'Guantes',
              'score': 0.69, 'status': 'incorrecto', 'detected': true,
              'feedback': 'Ajuste insuficiente detectado',
              'time_start': 84.0, 'time_end': 94.0, 'duration': 10.0,
            },
            {
              'step_number': 6, 'step_name': 'Postura Final',
              'score': 0.87, 'status': 'correcto', 'detected': true,
              'feedback': 'Buena postura final',
              'time_start': 94.0, 'time_end': 101.0, 'duration': 7.0,
            },
          ],
        },
      },
    ),

    // ── Video 3 ──────────────────────────────────────────────────────────────
    // Pasos fuera de orden: Casco (paso 4) detectado antes que Chaqueta (paso 3)
    3: SimulationStepConfig(
      secondToStepId: const {
        25:  0, // Pantalón Ignífugo  → s25
        53:  1, // Esclavina          → s53
        56:  3, // Casco              → s56
        79:  2, // Chaqueta Ignífuga  → s79
        100: 4, // Guantes            → s100
        105: 5, // Postura Final      → s105
      },
      evaluationResult: const {
        'precision':    0.753,
        'total_ventanas': 148,
        'correctos':  ['esclavina', 'casco', 'guantes'],
        'incorrectos': ['pantalon_ignifugo', 'chaqueta_ignifuga', 'postura_final'],
        'scores': {
          'pantalon_ignifugo': 0.71,
          'esclavina':         0.84,
          'chaqueta_ignifuga': 0.66,
          'casco':             0.78,
          'guantes':           0.92,
          'postura_final':     0.61,
        },
        'laravel_payload': {
          'general_score':         75.3,
          'total_steps':           6,
          'steps_completed':       6,
          'correct_order':         false,
          'duration_seconds':      105.0,
          'total_frames':          1260,
          'frames_with_detection': 1048,
          'detection_rate':        83.2,
          'steps_evaluation': [
            {
              'step_number': 1, 'step_name': 'Pantalón Ignífugo',
              'score': 0.71, 'status': 'incorrecto', 'detected': true,
              'feedback': 'Colocación parcialmente detectada',
              'time_start': 0.0, 'time_end': 25.0, 'duration': 25.0,
            },
            {
              'step_number': 2, 'step_name': 'Esclavina',
              'score': 0.84, 'status': 'correcto', 'detected': true,
              'feedback': 'Buena colocación',
              'time_start': 25.0, 'time_end': 53.0, 'duration': 28.0,
            },
            {
              'step_number': 3, 'step_name': 'Chaqueta Ignífuga',
              'score': 0.66, 'status': 'incorrecto', 'detected': true,
              'feedback': 'Se detectó fuera de orden',
              'time_start': 56.0, 'time_end': 79.0, 'duration': 23.0,
            },
            {
              'step_number': 4, 'step_name': 'Casco',
              'score': 0.78, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 53.0, 'time_end': 56.0, 'duration': 3.0,
            },
            {
              'step_number': 5, 'step_name': 'Guantes',
              'score': 0.92, 'status': 'correcto', 'detected': true,
              'feedback': 'Excelente colocación',
              'time_start': 79.0, 'time_end': 100.0, 'duration': 21.0,
            },
            {
              'step_number': 6, 'step_name': 'Postura Final',
              'score': 0.61, 'status': 'incorrecto', 'detected': true,
              'feedback': 'Postura final mejorable',
              'time_start': 100.0, 'time_end': 105.0, 'duration': 5.0,
            },
          ],
        },
      },
    ),

    // ── Video 4 ──────────────────────────────────────────────────────────────
    // Pasos fuera de orden: Esclavina (paso 2) detectada antes que Pantalón (paso 1)
    // Además, el paso final (Postura Final / paso 6) no se detecta.
    4: SimulationStepConfig(
      secondToStepId: const {
        4:  1, // Esclavina          → s4
        12: 0, // Pantalón Ignífugo  → s12
        20: 2, // Chaqueta Ignífuga  → s20
        45: 3, // Casco              → s45
        53: 4, // Guantes            → s53
        // 5: Postura Final (paso 5) NO se activa (no hubo activación)
      },
      evaluationResult: const {
        'precision':    0.681,
        'total_ventanas': 80,
        'correctos':  [
          'pantalon_ignifugo',
          'chaqueta_ignifuga',
          'casco',
          'guantes',
        ],
        'incorrectos': ['esclavina', 'postura_final'],
        'scores': {
          'pantalon_ignifugo': 0.86,
          'esclavina':         0.74,
          'chaqueta_ignifuga': 0.82,
          'casco':             0.77,
          'guantes':           0.89,
          'postura_final':     0.00,
        },
        'laravel_payload': {
          'general_score':         68.1,
          'total_steps':           6,
          'steps_completed':       5,
          'correct_order':         false,
          'duration_seconds':      53.0,
          'total_frames':          636,
          'frames_with_detection': 520,
          'detection_rate':        81.8,
          'steps_evaluation': [
            {
              'step_number': 1, 'step_name': 'Pantalón Ignífugo',
              'score': 0.86, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 4.0, 'time_end': 12.0, 'duration': 8.0,
            },
            {
              'step_number': 2, 'step_name': 'Esclavina',
              'score': 0.74, 'status': 'correcto', 'detected': true,
              'feedback': 'Detectado fuera de orden',
              'time_start': 0.0, 'time_end': 4.0, 'duration': 4.0,
            },
            {
              'step_number': 3, 'step_name': 'Chaqueta Ignífuga',
              'score': 0.82, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 12.0, 'time_end': 20.0, 'duration': 8.0,
            },
            {
              'step_number': 4, 'step_name': 'Casco',
              'score': 0.77, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 20.0, 'time_end': 45.0, 'duration': 25.0,
            },
            {
              'step_number': 5, 'step_name': 'Guantes',
              'score': 0.89, 'status': 'correcto', 'detected': true,
              'feedback': 'Correcto',
              'time_start': 45.0, 'time_end': 53.0, 'duration': 8.0,
            },
            {
              'step_number': 6, 'step_name': 'Postura Final',
              'score': 0.00, 'status': 'incorrecto', 'detected': false,
              'feedback': 'No se realizó',
              'time_start': null, 'time_end': null, 'duration': null,
            },
          ],
        },
      },
    ),

  };
}
