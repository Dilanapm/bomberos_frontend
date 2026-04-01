/// Datos del endpoint GET /instructor/stats/my-group
class GroupSummary {
  const GroupSummary({
    required this.totalAprendices,
    required this.promedioGrupo,
    required this.tasaAprobacion,
    this.mejorAprendiz,
    required this.necesitanApoyo,
    required this.miGrupoPromedio,
    required this.promedioInstitucional,
    required this.diferencia,
    required this.interpretacionVsInstitucion,
    required this.desviacionEstandar,
    required this.nivelConsistencia,
    required this.interpretacionConsistencia,
  });

  final int totalAprendices;
  final double promedioGrupo;
  final double tasaAprobacion;
  final BestStudent? mejorAprendiz;
  final int necesitanApoyo;

  // vs_institucion
  final double miGrupoPromedio;
  final double promedioInstitucional;
  final double diferencia;
  final String interpretacionVsInstitucion;

  // consistencia_grupo
  final double desviacionEstandar;
  final String nivelConsistencia;
  final String interpretacionConsistencia;
}

class BestStudent {
  const BestStudent({required this.name, required this.promedio});
  final String name;
  final double promedio;
}
