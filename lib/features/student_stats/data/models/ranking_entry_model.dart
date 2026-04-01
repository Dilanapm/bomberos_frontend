import '../../domain/entities/ranking_entry.dart';

class RankingEntryModel extends RankingEntry {
  const RankingEntryModel({
    required super.posicion,
    required super.aprendizId,
    required super.name,
    required super.promedio,
    required super.intentos,
    required super.mejorPuntaje,
    required super.tendencia,
    required super.badge,
  });

  factory RankingEntryModel.fromJson(Map<String, dynamic> json) {
    return RankingEntryModel(
      posicion:    (json['posicion']     as num).toInt(),
      aprendizId:  (json['aprendiz_id']  as num).toInt(),
      name:         json['name']         as String,
      promedio:    (json['promedio']      as num).toDouble(),
      intentos:    (json['intentos']      as num).toInt(),
      mejorPuntaje:(json['mejor_puntaje'] as num).toDouble(),
      tendencia:    json['tendencia']    as String,
      badge:        json['badge']        as String,
    );
  }
}
