import '../../domain/entities/need_help_data.dart';

class NeedHelpStudentModel extends NeedHelpStudent {
  const NeedHelpStudentModel({
    required super.id,
    required super.name,
    required super.problema,
    required super.promedioPaso,
    required super.promedioGeneral,
    required super.prioridad,
    required super.recomendacion,
  });

  factory NeedHelpStudentModel.fromJson(Map<String, dynamic> json) {
    return NeedHelpStudentModel(
      id:             (json['id']               as num).toInt(),
      name:            json['name']             as String,
      problema:        json['problema']         as String,
      promedioPaso:   (json['promedio_paso']     as num).toDouble(),
      promedioGeneral:(json['promedio_general']  as num).toDouble(),
      prioridad:       json['prioridad']        as String,
      recomendacion:   json['recomendacion']    as String,
    );
  }
}

class NeedHelpDataModel extends NeedHelpData {
  const NeedHelpDataModel({required super.total, required super.aprendices});

  factory NeedHelpDataModel.fromJson(Map<String, dynamic> json) {
    final list = (json['aprendices'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(NeedHelpStudentModel.fromJson)
        .toList();
    return NeedHelpDataModel(
      total:      (json['total'] as num).toInt(),
      aprendices: list,
    );
  }
}
