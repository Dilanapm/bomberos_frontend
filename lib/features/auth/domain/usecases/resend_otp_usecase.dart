import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

class ResendOtpUseCase {
  const ResendOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required int userId}) =>
      _repository.resendOtp(userId: userId);
}

final resendOtpUseCaseProvider = Provider<ResendOtpUseCase>((ref) {
  return ResendOtpUseCase(ref.read(authRepositoryProvider));
});
