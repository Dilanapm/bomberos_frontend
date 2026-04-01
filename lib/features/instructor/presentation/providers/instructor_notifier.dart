import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/registration_code.dart';
import '../../data/repositories/instructor_repository_impl.dart';

class InstructorState {
  const InstructorState({
    this.code,
    this.isLoading = false,
    this.error,
  });

  final RegistrationCode? code;
  final bool isLoading;
  final Object? error;

  bool get hasActiveCode => code != null && code!.isActive;

  InstructorState copyWith({
    RegistrationCode? code,
    bool? isLoading,
    Object? error,
    bool clearCode = false,
    bool clearError = false,
  }) {
    return InstructorState(
      code:      clearCode  ? null  : (code      ?? this.code),
      isLoading: isLoading  ?? this.isLoading,
      error:     clearError ? null  : (error     ?? this.error),
    );
  }
}

class InstructorNotifier extends AsyncNotifier<InstructorState> {
  @override
  Future<InstructorState> build() async {
    final code = await ref
        .read(instructorRepositoryProvider)
        .getActiveCode();
    return InstructorState(code: code);
  }

  Future<void> generateCode() async {
    state = const AsyncLoading();
    try {
      final code = await ref
          .read(instructorRepositoryProvider)
          .generateCode();
      state = AsyncData(InstructorState(code: code));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> revokeCode() async {
    final currentState = state.whenData((s) => s).value;
    state = AsyncData(currentState?.copyWith(isLoading: true) ??
        const InstructorState(isLoading: true));
    try {
      await ref.read(instructorRepositoryProvider).revokeCode();
      state = const AsyncData(InstructorState());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final code = await ref
        .read(instructorRepositoryProvider)
        .getActiveCode();
    state = AsyncData(InstructorState(code: code));
  }
}

final instructorNotifierProvider =
    AsyncNotifierProvider<InstructorNotifier, InstructorState>(
        InstructorNotifier.new);
