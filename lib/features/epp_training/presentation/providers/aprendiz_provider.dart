import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/aprendiz.dart';
import '../../data/services/aprendiz_service.dart';

/// Lista de aprendices del instructor. Se recarga con `.invalidate()`.
final aprendicesProvider = FutureProvider<List<Aprendiz>>((ref) async {
  final service = ref.read(aprendizServiceProvider);
  return service.fetchAll();
});

/// Aprendiz seleccionado para la sesión de entrenamiento.
/// `null` significa sesión sin aprendiz asignado.
class SelectedAprendizNotifier extends Notifier<Aprendiz?> {
  @override
  Aprendiz? build() => null;

  void select(Aprendiz? aprendiz) => state = aprendiz;
}

final selectedAprendizProvider =
    NotifierProvider<SelectedAprendizNotifier, Aprendiz?>(
  SelectedAprendizNotifier.new,
);
