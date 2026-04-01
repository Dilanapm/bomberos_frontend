import '../../domain/entities/group_summary.dart';

class BestStudentModel extends BestStudent {
  const BestStudentModel({required super.name, required super.promedio});

  factory BestStudentModel.fromJson(Map<String, dynamic> json) {
    return BestStudentModel(
      name:     json['name']     as String,
      promedio: (json['promedio'] as num).toDouble(),
    );
  }
}

class GroupSummaryModel extends GroupSummary {
  const GroupSummaryModel({
    required super.totalAprendices,
    required super.promedioGrupo,
    required super.tasaAprobacion,
    super.mejorAprendiz,
    required super.necesitanApoyo,
    required super.miGrupoPromedio,
    required super.promedioInstitucional,
    required super.diferencia,
    required super.interpretacionVsInstitucion,
    required super.desviacionEstandar,
    required super.nivelConsistencia,
    required super.interpretacionConsistencia,
  });

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    final resumen   = json['resumen_grupo']    as Map<String, dynamic>;
    final vs        = json['vs_institucion']   as Map<String, dynamic>;
    final consist   = json['consistencia_grupo'] as Map<String, dynamic>;

    final mejorJson = resumen['mejor_aprendiz'] as Map<String, dynamic>?;

    return GroupSummaryModel(
      totalAprendices:            (resumen['total_aprendices']   as num).toInt(),
      promedioGrupo:              (resumen['promedio_grupo']      as num).toDouble(),
      tasaAprobacion:             (resumen['tasa_aprobacion']     as num).toDouble(),
      mejorAprendiz: mejorJson != null
          ? BestStudentModel.fromJson(mejorJson)
          : null,
      necesitanApoyo:             (resumen['necesitan_apoyo']     as num).toInt(),
      miGrupoPromedio:            (vs['mi_grupo_promedio']        as num).toDouble(),
      promedioInstitucional:      (vs['promedio_institucional']   as num).toDouble(),
      diferencia:                 (vs['diferencia']               as num).toDouble(),
      interpretacionVsInstitucion: vs['interpretacion']           as String,
      desviacionEstandar:         (consist['desviacion_estandar'] as num).toDouble(),
      nivelConsistencia:           consist['nivel']               as String,
      interpretacionConsistencia:  consist['interpretacion']      as String,
    );
  }
}
