/// Respuesta de clasificación EPP recibida desde la API FastAPI por WebSocket.
class EppClassificationResponse {
  final int pasoId;
  final String pasoNombre;
  final double confianza;
  final Map<String, double> probabilidades;
  final double latenciaMs;
  final bool poseDetectada;

  const EppClassificationResponse({
    required this.pasoId,
    required this.pasoNombre,
    required this.confianza,
    required this.probabilidades,
    required this.latenciaMs,
    required this.poseDetectada,
  });

  factory EppClassificationResponse.fromJson(Map<String, dynamic> json) {
    return EppClassificationResponse(
      pasoId:     json['paso_id']      as int,
      pasoNombre: json['paso_nombre']  as String,
      confianza:  (json['confianza']   as num).toDouble(),
      probabilidades: (json['probabilidades'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      latenciaMs:    (json['latencia_ms']    as num).toDouble(),
      poseDetectada:  json['pose_detectada'] as bool,
    );
  }

  @override
  String toString() =>
      'EppClassificationResponse(paso=$pasoNombre, confianza=${(confianza * 100).toStringAsFixed(1)}%)';
}
