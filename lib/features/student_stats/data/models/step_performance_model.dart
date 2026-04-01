import '../../domain/entities/step_performance.dart';

class StepPerformanceModel extends StepPerformance {
  const StepPerformanceModel({
    required super.numero,
    required super.nombre,
    required super.promedioGrupo,
    required super.tasaExito,
    required super.dificultad,
    super.problema,
  });

  factory StepPerformanceModel.fromJson(Map<String, dynamic> json) {
    return StepPerformanceModel(
      numero:       (json['numero']        as num).toInt(),
      nombre:        json['nombre']        as String,
      promedioGrupo:(json['promedio_grupo'] as num).toDouble(),
      tasaExito:    (json['tasa_exito']    as num).toDouble(),
      dificultad:    json['dificultad']    as String,
      problema:      json['problema']      as String?,
    );
  }
}
