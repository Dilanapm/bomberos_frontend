import '../../domain/entities/analytics.dart';

/// Safely parses a value that may arrive as String or num from the API.
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());
int _toInt(dynamic v) =>
    v is num ? v.toInt() : int.parse(v.toString());

class PersonalStatsModel extends PersonalStats {
  const PersonalStatsModel({
    required super.promedio,
    required super.mejorPuntaje,
    required super.resultadoMasComun,
    required super.rangoTipico,
    required super.nivelConsistencia,
    required super.interpretacion,
    required super.totalIntentos,
  });

  factory PersonalStatsModel.fromJson(Map<String, dynamic> json) {
    return PersonalStatsModel(
      promedio:           _toDouble(json['promedio']),
      mejorPuntaje:       _toDouble(json['mejor_puntaje']),
      resultadoMasComun:  _toDouble(json['resultado_mas_comun']),
      rangoTipico:        json['rango_tipico']        as String,
      nivelConsistencia:   json['nivel_consistencia']  as String,
      interpretacion:      json['interpretacion']      as String,
      totalIntentos:      _toInt(json['total_intentos']),
    );
  }
}

class AnalyticsGroupComparisonModel extends AnalyticsGroupComparison {
  const AnalyticsGroupComparisonModel({
    required super.miPromedio,
    required super.promedioGrupo,
    required super.diferencia,
    required super.posicionEstimada,
    required super.mejorDelGrupo,
    required super.paraTop10,
  });

  factory AnalyticsGroupComparisonModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsGroupComparisonModel(
      miPromedio:       _toDouble(json['mi_promedio']),
      promedioGrupo:    _toDouble(json['promedio_grupo']),
      diferencia:       _toDouble(json['diferencia']),
      posicionEstimada:  json['posicion_estimada'] as String,
      mejorDelGrupo:    _toDouble(json['mejor_del_grupo']),
      paraTop10:        _toDouble(json['para_top_10']),
    );
  }
}

class StrengthModel extends Strength {
  const StrengthModel({
    required super.paso,
    required super.nombre,
    required super.promedio,
    required super.estrellas,
  });

  factory StrengthModel.fromJson(Map<String, dynamic> json) {
    return StrengthModel(
      paso:      _toInt(json['paso']),
      nombre:     json['nombre']    as String,
      promedio:  _toDouble(json['promedio']),
      estrellas: _toInt(json['estrellas']),
    );
  }
}

class WeaknessModel extends Weakness {
  const WeaknessModel({
    required super.paso,
    required super.nombre,
    required super.promedio,
    required super.promedioGrupo,
    required super.diferencia,
    required super.recomendacion,
  });

  factory WeaknessModel.fromJson(Map<String, dynamic> json) {
    return WeaknessModel(
      paso:          _toInt(json['paso']),
      nombre:         json['nombre']         as String,
      promedio:      _toDouble(json['promedio']),
      promedioGrupo: _toDouble(json['promedio_grupo']),
      diferencia:    _toDouble(json['diferencia']),
      recomendacion:  json['recomendacion']  as String,
    );
  }
}

class TemporalPointModel extends TemporalPoint {
  const TemporalPointModel({
    required super.intento,
    required super.puntaje,
    required super.fecha,
  });

  factory TemporalPointModel.fromJson(Map<String, dynamic> json) {
    return TemporalPointModel(
      intento: _toInt(json['intento']),
      puntaje: _toDouble(json['puntaje']),
      fecha:    json['fecha']   as String,
    );
  }
}

class TendencyModel extends Tendency {
  const TendencyModel({
    required super.tipo,
    required super.mejorTotal,
    required super.velocidadMejora,
    required super.interpretacion,
  });

  factory TendencyModel.fromJson(Map<String, dynamic> json) {
    return TendencyModel(
      tipo:            json['tipo']             as String,
      mejorTotal:     _toDouble(json['mejora_total']),
      velocidadMejora:_toDouble(json['velocidad_mejora']),
      interpretacion:  json['interpretacion']   as String,
    );
  }
}

class AnalyticsModel extends Analytics {
  const AnalyticsModel({
    required super.personalStats,
    required super.comparacionGrupo,
    required super.fortalezas,
    required super.debilidades,
    required super.progresoTemporal,
    required super.tendencia,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final fd = json['fortalezas_debilidades'] as Map<String, dynamic>;

    return AnalyticsModel(
      personalStats: PersonalStatsModel.fromJson(
          json['personal_stats'] as Map<String, dynamic>),
      comparacionGrupo: AnalyticsGroupComparisonModel.fromJson(
          json['comparacion_grupo'] as Map<String, dynamic>),
      fortalezas: (fd['fortalezas'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(StrengthModel.fromJson)
          .toList(),
      debilidades: (fd['debilidades'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WeaknessModel.fromJson)
          .toList(),
      progresoTemporal: (json['progreso_temporal'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TemporalPointModel.fromJson)
          .toList(),
      tendencia: TendencyModel.fromJson(
          json['tendencia'] as Map<String, dynamic>),
    );
  }
}
