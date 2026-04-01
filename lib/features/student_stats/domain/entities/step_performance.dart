/// Rendimiento por paso EPP — GET /instructor/stats/step-analysis
class StepPerformance {
  const StepPerformance({
    required this.numero,
    required this.nombre,
    required this.promedioGrupo,
    required this.tasaExito,
    required this.dificultad,
    this.problema,
  });

  final int numero;
  final String nombre;
  final double promedioGrupo;
  final double tasaExito;

  /// "facil" | "moderado" | "dificil"
  final String dificultad;

  /// Descripción del problema o null
  final String? problema;
}
