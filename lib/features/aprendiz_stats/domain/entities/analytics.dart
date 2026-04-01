/// Análisis avanzado del aprendiz — GET /evaluations/analytics (A2)
/// [data] puede ser null si no tiene evaluaciones.

class Analytics {
  const Analytics({
    required this.personalStats,
    required this.comparacionGrupo,
    required this.fortalezas,
    required this.debilidades,
    required this.progresoTemporal,
    required this.tendencia,
  });

  final PersonalStats personalStats;
  final AnalyticsGroupComparison comparacionGrupo;
  final List<Strength> fortalezas;
  final List<Weakness> debilidades;
  final List<TemporalPoint> progresoTemporal;
  final Tendency tendencia;
}

class PersonalStats {
  const PersonalStats({
    required this.promedio,
    required this.mejorPuntaje,
    required this.resultadoMasComun,
    required this.rangoTipico,
    required this.nivelConsistencia,
    required this.interpretacion,
    required this.totalIntentos,
  });

  final double promedio;
  final double mejorPuntaje;
  final double resultadoMasComun;
  /// e.g. "±3.6" — returned as a formatted string by the API
  final String rangoTipico;
  final String nivelConsistencia;
  final String interpretacion;
  final int totalIntentos;
}

class AnalyticsGroupComparison {
  const AnalyticsGroupComparison({
    required this.miPromedio,
    required this.promedioGrupo,
    required this.diferencia,
    required this.posicionEstimada,
    required this.mejorDelGrupo,
    required this.paraTop10,
  });

  final double miPromedio;
  final double promedioGrupo;
  final double diferencia;
  final String posicionEstimada;
  final double mejorDelGrupo;
  final double paraTop10;
}

class Strength {
  const Strength({
    required this.paso,
    required this.nombre,
    required this.promedio,
    required this.estrellas,
  });

  final int paso;
  final String nombre;
  final double promedio;

  /// 1–5
  final int estrellas;
}

class Weakness {
  const Weakness({
    required this.paso,
    required this.nombre,
    required this.promedio,
    required this.promedioGrupo,
    required this.diferencia,
    required this.recomendacion,
  });

  final int paso;
  final String nombre;
  final double promedio;
  final double promedioGrupo;
  final double diferencia;
  final String recomendacion;
}

class TemporalPoint {
  const TemporalPoint({
    required this.intento,
    required this.puntaje,
    required this.fecha,
  });

  final int intento;
  final double puntaje;
  final String fecha;
}

class Tendency {
  const Tendency({
    required this.tipo,
    required this.mejorTotal,
    required this.velocidadMejora,
    required this.interpretacion,
  });

  /// "positiva" | "negativa" | "estable"
  final String tipo;
  final double mejorTotal;
  final double velocidadMejora;
  final String interpretacion;
}
