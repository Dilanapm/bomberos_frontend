import '../../domain/entities/registration_code.dart';

class RegistrationCodeModel extends RegistrationCode {
  const RegistrationCodeModel({
    required super.code,
    required super.expiresAt,
    required super.uses,
    required super.maxUses,
  });

  factory RegistrationCodeModel.fromJson(Map<String, dynamic> json) {
    return RegistrationCodeModel(
      code:      json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      uses:      (json['uses'] as num?)?.toInt()     ?? 0,
      maxUses:   (json['max_uses'] as num?)?.toInt() ?? 1,
    );
  }
}
