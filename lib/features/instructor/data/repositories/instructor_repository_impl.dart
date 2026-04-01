import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/registration_code.dart';
import '../datasources/instructor_remote_datasource.dart';

abstract class InstructorRepository {
  Future<RegistrationCode> generateCode();
  Future<RegistrationCode?> getActiveCode();
  Future<void> revokeCode();
}

class InstructorRepositoryImpl implements InstructorRepository {
  const InstructorRepositoryImpl(this._remote);
  final InstructorRemoteDataSource _remote;

  @override
  Future<RegistrationCode> generateCode() => _remote.generateCode();

  @override
  Future<RegistrationCode?> getActiveCode() => _remote.getActiveCode();

  @override
  Future<void> revokeCode() => _remote.revokeCode();
}

final instructorRepositoryProvider = Provider<InstructorRepository>((ref) {
  return InstructorRepositoryImpl(ref.read(instructorRemoteDataSourceProvider));
});
