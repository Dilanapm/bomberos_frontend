import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      _repository.resetPassword(
        token:                token,
        email:                email,
        password:             password,
        passwordConfirmation: passwordConfirmation,
      );
}

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.read(authRepositoryProvider));
});
