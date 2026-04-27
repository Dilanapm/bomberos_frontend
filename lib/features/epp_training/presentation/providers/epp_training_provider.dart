import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/epp_classification_response.dart';
import '../../data/models/epp_step.dart';
import '../../data/services/epp_websocket_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final eppWebSocketServiceProvider = Provider<EppWebSocketService>((ref) {
  final service = EppWebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

/// Riverpod 3: NotifierProvider (StateNotifierProvider fue removido).
final eppTrainingProvider =
    NotifierProvider<EppTrainingNotifier, EppTrainingState>(
  EppTrainingNotifier.new,
);

// ── Estado ────────────────────────────────────────────────────────────────────

class EppTrainingState {
  final bool isConnected;
  final bool isConnecting;
  final EppClassificationResponse? lastClassification;
  final EppStep currentStep;
  final Set<int> completedStepIds;
  final List<EppClassificationResponse> history;

  /// ID de sesión WebSocket — se conserva después de desconectar para la evaluación GRU.
  final String? sessionId;

  final String? error;

  const EppTrainingState({
    this.isConnected      = false,
    this.isConnecting     = false,
    this.lastClassification,
    this.currentStep      = EppStep.acumulando,
    this.completedStepIds = const {},
    this.history          = const [],
    this.sessionId,
    this.error,
  });

  EppTrainingState copyWith({
    bool? isConnected,
    bool? isConnecting,
    EppClassificationResponse? lastClassification,
    EppStep? currentStep,
    Set<int>? completedStepIds,
    List<EppClassificationResponse>? history,
    String? sessionId,
    String? error,
  }) =>
      EppTrainingState(
        isConnected:        isConnected        ?? this.isConnected,
        isConnecting:       isConnecting       ?? this.isConnecting,
        lastClassification: lastClassification ?? this.lastClassification,
        currentStep:        currentStep        ?? this.currentStep,
        completedStepIds:   completedStepIds   ?? this.completedStepIds,
        history:            history            ?? this.history,
        sessionId:          sessionId          ?? this.sessionId,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class EppTrainingNotifier extends Notifier<EppTrainingState> {
  StreamSubscription<EppClassificationResponse>? _sub;

  /// En Riverpod 3 las dependencias se obtienen vía [ref] dentro de build().
  EppWebSocketService get _ws => ref.read(eppWebSocketServiceProvider);

  @override
  EppTrainingState build() {
    ref.onDispose(() => _sub?.cancel());
    return const EppTrainingState();
  }

  // ── Público ─────────────────────────────────────────────────────────────────

  Future<void> connect({String? authToken, int? aprendizId}) async {
    if (state.isConnected || state.isConnecting) return;

    state = state.copyWith(isConnecting: true, error: null);

    try {
      await _ws.connect(authToken: authToken, aprendizId: aprendizId);

      _sub = _ws.responses.listen(
        _onClassification,
        onError: (Object e) {
          state = state.copyWith(isConnected: false, error: e.toString());
        },
      );

      // Guardar sessionId en el estado para que persista tras desconexión
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        sessionId: _ws.sessionId,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected:  false,
        isConnecting: false,
        error: 'No se pudo conectar: $e\n'
            'Verifica que FastAPI esté corriendo en ${_ws.sessionId ?? '...'}',
      );
    }
  }

  /// Desconecta el WebSocket manteniendo el historial y sessionId para evaluación GRU.
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _ws.disconnect();
    // Mantiene history y sessionId; solo resetea flags de conexión
    state = state.copyWith(
      isConnected:  false,
      isConnecting: false,
      error: null,
    );
  }

  /// Limpia el historial y resetea completamente el estado.
  void clearHistory() {
    state = const EppTrainingState();
  }

  /// Actualiza solo la visualización (paso actual + barra de confianza)
  /// sin completar el paso ni agregar al historial.
  /// Usado para simular la variabilidad de la red neuronal entre detecciones.
  void simulateVariability(int stepId, double confidence) {
    final step         = EppStep.fromId(stepId);
    final fakeResponse = EppClassificationResponse(
      pasoId:         stepId,
      pasoNombre:     step.displayName,
      confianza:      confidence,
      probabilidades: const {},
      latenciaMs:     0,
      poseDetectada:  stepId >= 0,
    );
    // Solo actualiza lo visual; completedStepIds e history no cambian.
    state = state.copyWith(
      lastClassification: fakeResponse,
      currentStep:        step,
    );
  }

  /// Inyecta una clasificación simulada sin pasar por el WebSocket.
  /// Usado en modo de simulación por nombre de video (video_N.mp4).
  void simulateStep(int stepId) {
    final step         = EppStep.fromId(stepId);
    final newCompleted = Set<int>.from(state.completedStepIds);

    final fakeResponse = EppClassificationResponse(
      pasoId:         stepId,
      pasoNombre:     step.displayName,
      confianza:      0.95,
      probabilidades: const {},
      latenciaMs:     0,
      poseDetectada:  true,
    );

    if (stepId >= 0) {
      newCompleted.add(stepId);
    }

    state = state.copyWith(
      lastClassification: fakeResponse,
      currentStep:        step,
      completedStepIds:   newCompleted,
      history:            [...state.history, fakeResponse],
      // error queda en null (comportamiento de copyWith sin pasar error)
    );
  }

  // ── Privado ─────────────────────────────────────────────────────────────────

  void _onClassification(EppClassificationResponse r) {
    final step         = EppStep.fromId(r.pasoId);
    final newCompleted = Set<int>.from(state.completedStepIds);
    final newHistory   = [...state.history, r];

    if (r.pasoId >= 0 && r.confianza >= 0.5) {
      newCompleted.add(r.pasoId);
    }

    state = state.copyWith(
      lastClassification: r,
      currentStep:        step,
      completedStepIds:   newCompleted,
      history:            newHistory,
      error: null,
    );
  }
}
