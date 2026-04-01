/// Entrada del ranking — GET /instructor/stats/ranking
class RankingEntry {
  const RankingEntry({
    required this.posicion,
    required this.aprendizId,
    required this.name,
    required this.promedio,
    required this.intentos,
    required this.mejorPuntaje,
    required this.tendencia,
    required this.badge,
  });

  final int posicion;
  final int aprendizId;
  final String name;
  final double promedio;
  final int intentos;
  final double mejorPuntaje;

  /// "mejorando" | "empeorando" | "estable"
  final String tendencia;

  /// "oro" | "plata" | "bronce" | "sin_badge"
  final String badge;
}
