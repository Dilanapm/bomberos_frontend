import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../datasources/profile_remote_datasource.dart';

abstract class ProfileRepository {
  Future<User> updateProfile({String? name, String? username});
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
  Future<User> uploadAvatar(File file);
  Future<void> deleteAvatar();
}

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<User> updateProfile({String? name, String? username}) =>
      _remote.updateProfile(name: name, username: username);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _remote.changePassword(
        currentPassword:      currentPassword,
        password:             password,
        passwordConfirmation: passwordConfirmation,
      );

  @override
  Future<User> uploadAvatar(File file) => _remote.uploadAvatar(file);

  @override
  Future<void> deleteAvatar() => _remote.deleteAvatar();
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.read(profileRemoteDataSourceProvider));
});
