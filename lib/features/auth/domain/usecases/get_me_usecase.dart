import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetMeUseCase {
  const GetMeUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> call() => _repository.getMe();
}

final getMeUseCaseProvider = Provider<GetMeUseCase>((ref) {
  return GetMeUseCase(ref.read(authRepositoryProvider));
});
