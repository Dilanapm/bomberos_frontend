/// Pasos del proceso de colocación de EPP de bombero.
///
/// El servidor devuelve `paso_id = -1` mientras acumula frames para clasificar.
enum EppStep {
  acumulando(-1, 'Preparando clasificación…'),
  pantalonIgnifugo(0, 'Pantalón Ignífugo'),
  esclavina(1, 'Esclavina'),
  chaquetaIgnifuga(2, 'Chaqueta Ignífuga'),
  casco(3, 'Casco'),
  guantes(4, 'Guantes'),
  posturaFinal(5, 'Postura Final');

  final int id;
  final String displayName;

  const EppStep(this.id, this.displayName);

  /// Devuelve el paso correspondiente al `id` recibido del servidor.
  /// Si el id no se reconoce, retorna [EppStep.acumulando].
  static EppStep fromId(int id) => EppStep.values.firstWhere(
        (step) => step.id == id,
        orElse: () => EppStep.acumulando,
      );

  /// Pasos reales del EPP (excluye [acumulando]).
  static List<EppStep> get eppSteps => EppStep.values
      .where((s) => s.id >= 0)
      .toList();
}
