import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/aprendiz.dart';

/// Servicio que consume el endpoint de aprendices de la API Laravel.
class AprendizService {
  AprendizService(this._client);
  final DioClient _client;

  /// `GET /instructor/aprendices/all`
  /// El token se adjunta automáticamente por el interceptor de Dio.
  Future<List<Aprendiz>> fetchAll() async {
    final response =
        await _client.dio.get('/instructor/aprendices/all');

    final data = response.data;

    // La API puede devolver { data: [...] } o directamente [...]
    final List<dynamic> list = data is Map ? data['data'] ?? data : data;

    return list
        .map((e) => Aprendiz.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final aprendizServiceProvider = Provider<AprendizService>((ref) {
  final client = ref.read(dioClientProvider);
  return AprendizService(client);
});
