/// Entidad del código de registro generado por un instructor.
class RegistrationCode {
  const RegistrationCode({
    required this.code,
    required this.expiresAt,
    required this.uses,
    required this.maxUses,
  });

  final String code;
  final DateTime expiresAt;
  final int uses;
  final int maxUses;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExhausted => uses >= maxUses;
  bool get isActive => !isExpired && !isExhausted;

  Duration get timeRemaining =>
      expiresAt.isAfter(DateTime.now())
          ? expiresAt.difference(DateTime.now())
          : Duration.zero;
}
