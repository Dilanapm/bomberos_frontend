import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/registration_code_model.dart';

class InstructorRemoteDataSource {
  const InstructorRemoteDataSource(this._dio);
  final Dio _dio;

  Future<RegistrationCodeModel> generateCode() async {
    try {
      final res = await _dio.post(ApiEndpoints.registrationCodeGenerate);
      final rawData = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return RegistrationCodeModel.fromJson(rawData);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<RegistrationCodeModel?> getActiveCode() async {
    try {
      final res = await _dio.get(ApiEndpoints.registrationCodeActive);
      // Si la API devuelve "data": null significa que no hay código activo
      final rawData = (res.data as Map<String, dynamic>?)?['data'];
      if (rawData == null) return null;
      return RegistrationCodeModel.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> revokeCode() async {
    try {
      await _dio.delete(ApiEndpoints.registrationCodeRevoke);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final instructorRemoteDataSourceProvider =
    Provider<InstructorRemoteDataSource>((ref) {
  return InstructorRemoteDataSource(ref.read(dioClientProvider).dio);
});
