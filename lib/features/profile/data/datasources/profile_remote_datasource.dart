import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<UserModel> updateProfile({
    String? name,
    String? username,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name     != null) body['name']     = name;
      if (username != null) body['username'] = username;

      final res = await _dio.patch(ApiEndpoints.profileUpdate, data: body);
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          ?? res.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.profilePassword,
        data: {
          'current_password':      currentPassword,
          'password':              password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<UserModel> uploadAvatar(File file) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final res = await _dio.post(
        ApiEndpoints.profileAvatar,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?
          ?? res.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<void> deleteAvatar() async {
    try {
      await _dio.delete(ApiEndpoints.profileAvatar);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  AppException _unwrap(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return ErrorHandler.handle(e);
  }
}

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.read(dioClientProvider).dio);
});
