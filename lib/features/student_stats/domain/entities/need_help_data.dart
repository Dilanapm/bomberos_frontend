/// Aprendiz en riesgo — GET /instructor/stats/need-help
class NeedHelpStudent {
  const NeedHelpStudent({
    required this.id,
    required this.name,
    required this.problema,
    required this.promedioPaso,
    required this.promedioGeneral,
    required this.prioridad,
    required this.recomendacion,
  });

  final int id;
  final String name;
  final String problema;
  final double promedioPaso;
  final double promedioGeneral;

  /// "alta" (< 50) | "media" (entre 50 y 65)
  final String prioridad;
  final String recomendacion;
}

/// Wrapper del endpoint need-help (incluye el total)
class NeedHelpData {
  const NeedHelpData({required this.total, required this.aprendices});
  final int total;
  final List<NeedHelpStudent> aprendices;
}
