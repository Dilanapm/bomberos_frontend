import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Pantalla de sesión de cámara con cuenta regresiva de 10 segundos.
///
/// Flujo:
///  1. Inicializa el controlador de cámara frontal.
///  2. Muestra una cuenta regresiva de 10 s ("Prepárate…").
///  3. Al llegar a 0 comienza la grabación y muestra el indicador REC.
///  4. El botón DETENER finaliza la grabación y cierra la pantalla.
class CameraSessionScreen extends StatefulWidget {
  const CameraSessionScreen({super.key});

  @override
  State<CameraSessionScreen> createState() => _CameraSessionScreenState();
}

class _CameraSessionScreenState extends State<CameraSessionScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording   = false;
  bool _isStopping    = false;
  String? _errorMessage;

  // Cuenta regresiva
  static const int _countdownSeconds = 10;
  int _countdown = _countdownSeconds;
  bool _countdownDone = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No se encontró ninguna cámara.');
        return;
      }

      // Preferir cámara frontal para escanear EPP
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _isInitialized = true);

      _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al inicializar la cámara: $e');
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _countdownDone = true;
        });
        _startRecording();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.startVideoRecording();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error al grabar: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;
    setState(() => _isStopping = true);
    try {
      final file = await _controller!.stopVideoRecording();
      if (mounted) {
        // TODO: pasar file.path al provider de entrenamiento para procesar
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStopping = false;
          _errorMessage = 'Error al detener la grabación: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Vista de cámara ───────────────────────────────────────────
            if (_isInitialized && _controller != null)
              CameraPreview(_controller!)
            else if (_errorMessage != null)
              _ErrorView(message: _errorMessage!)
            else
              const _LoadingView(),

            // ── Overlay ───────────────────────────────────────────────────
            if (_isInitialized) ...[
              // Marco de detección EPP
              const _ScanOverlay(),

              // Encabezado con botón atrás
              _TopBar(onBack: _isRecording ? null : () => Navigator.pop(context)),

              // Cuenta regresiva o indicador REC
              _BottomOverlay(
                countdownDone: _countdownDone,
                countdown: _countdown,
                isRecording: _isRecording,
                isStopping: _isStopping,
                onStop: _stopRecording,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay superior: botón atrás + etiqueta
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(180), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: onBack,
            ),
            const Spacer(),
            const Text(
              'EVALUACIÓN EPP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Marco de detección central
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frameSize = size.width * 0.7;

    return Center(
      child: SizedBox(
        width: frameSize,
        height: frameSize * 1.4,
        child: CustomPaint(painter: _FramePainter()),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary5
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLen = 28.0;

    // Top-left
    canvas.drawArc(Rect.fromLTWH(0, 0, 12, 12), 3.14, 1.57, false, paint);
    canvas.drawLine(const Offset(0, 6), Offset(0, cornerLen), paint);
    canvas.drawLine(const Offset(6, 0), Offset(cornerLen, 0), paint);

    // Top-right
    final tr = Offset(size.width, 0);
    canvas.drawArc(
        Rect.fromLTWH(size.width - 12, 0, 12, 12), -1.57, 1.57, false, paint);
    canvas.drawLine(tr + const Offset(0, 6), tr + Offset(0, cornerLen), paint);
    canvas.drawLine(
        tr - const Offset(6, 0), tr - Offset(cornerLen, 0), paint);

    // Bottom-left
    final bl = Offset(0, size.height);
    canvas.drawArc(Rect.fromLTWH(0, size.height - 12, 12, 12), 1.57, 1.57,
        false, paint);
    canvas.drawLine(bl - const Offset(0, 6), bl - Offset(0, cornerLen), paint);
    canvas.drawLine(bl + const Offset(6, 0), bl + Offset(cornerLen, 0), paint);

    // Bottom-right
    final br = Offset(size.width, size.height);
    canvas.drawArc(
        Rect.fromLTWH(size.width - 12, size.height - 12, 12, 12),
        0,
        1.57,
        false,
        paint);
    canvas.drawLine(br - const Offset(0, 6), br - Offset(0, cornerLen), paint);
    canvas.drawLine(
        br - const Offset(6, 0), br - Offset(cornerLen, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay inferior: cuenta regresiva / REC / DETENER
// ─────────────────────────────────────────────────────────────────────────────

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({
    required this.countdownDone,
    required this.countdown,
    required this.isRecording,
    required this.isStopping,
    required this.onStop,
  });

  final bool countdownDone;
  final int countdown;
  final bool isRecording;
  final bool isStopping;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(200), Colors.transparent],
          ),
        ),
        child: countdownDone
            ? _RecordingControls(
                isRecording: isRecording,
                isStopping: isStopping,
                onStop: onStop,
              )
            : _CountdownDisplay(countdown: countdown),
      ),
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  const _CountdownDisplay({required this.countdown});
  final int countdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$countdown',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prepárate para iniciar el ejercicio',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({
    required this.isRecording,
    required this.isStopping,
    required this.onStop,
  });

  final bool isRecording;
  final bool isStopping;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador REC
        if (isRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'GRABANDO',
                style: TextStyle(
                  color: AppColors.primary5,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

        const SizedBox(height: 20),

        // Botón detener
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isStopping ? null : onStop,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(220),
              foregroundColor: AppColors.secondary800,
              disabledBackgroundColor: Colors.white.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isStopping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary700,
                    ),
                  )
                : const Text(
                    'DETENER SESIÓN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary5),
          SizedBox(height: 20),
          Text(
            'Iniciando cámara…',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.primary5, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver',
                  style: TextStyle(color: AppColors.primary5)),
            ),
          ],
        ),
      ),
    );
  }
}
