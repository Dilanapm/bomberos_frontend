import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_icons.dart';
import '../../../../../core/error/app_exception.dart';
import '../../../../../core/utils/app_toast.dart';
import '../../../../../core/widgets/app_app_bar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scroll_body.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({
    super.key,
    required this.userId,
    required this.email,
  });

  final int userId;
  final String email;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _timer;

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 6) {
      AppToast.showError(context, 'Ingresa los 6 dígitos del código.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(userId: widget.userId, code: code);
    } catch (_) {
      // Los errores se manejan en el listener.
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authNotifierProvider.notifier).resendOtp(
            userId: widget.userId,
          );
      if (!mounted) return;
      AppToast.showSuccess(context, 'Código reenviado a ${widget.email}.');
      _startCooldown();
    } on AppException catch (e) {
      AppToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          if (e is AppException) {
            AppToast.showError(context, e.message);
          }
        },
      );
    });

    return Scaffold(
      appBar: AppAppBar(title: 'Verificar correo'),
      body: SafeArea(
        child: AppScrollBody(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de verificación', style: text.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 6 dígitos que enviamos a\n${widget.email}',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.secondary400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildBox),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Verificar',
                isLoading: _isVerifying,
                onPressed: _isVerifying ? null : _verify,
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        'Reenviar código en ${_resendCooldown}s',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.secondary400,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resend,
                        child: Text(
                          _isResending ? 'Enviando...' : 'Reenviar código',
                          style: text.labelMedium?.copyWith(
                            color: AppColors.primary5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: Theme.of(context).textTheme.titleSmall,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.dark1
              : AppColors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.secondary200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.secondary200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary5, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
