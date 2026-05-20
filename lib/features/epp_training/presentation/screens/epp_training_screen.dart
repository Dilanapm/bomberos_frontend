import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:dio/dio.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/config/env.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/epp_step.dart';
import '../../data/services/epp_websocket_service.dart';
import '../providers/epp_training_provider.dart';
import '../providers/aprendiz_provider.dart';
import 'epp_evaluation_result_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modos de entrada
// ─────────────────────────────────────────────────────────────────────────────

enum _InputMode { camera, video }

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal
// ─────────────────────────────────────────────────────────────────────────────

class EppTrainingScreen extends ConsumerStatefulWidget {
  const EppTrainingScreen({super.key});

  @override
  ConsumerState<EppTrainingScreen> createState() => _EppTrainingScreenState();
}

class _EppTrainingScreenState extends ConsumerState<EppTrainingScreen> {
  // ── Modo ──────────────────────────────────────────────────────────────────
  _InputMode _mode = _InputMode.video;

  // ── Cámara ────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _cameraReady = false;

  // ── Vídeo de prueba ───────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isCapturingFrame = false;

  // ── Streaming ─────────────────────────────────────────────────────────────
  bool _isStreaming  = false;
  bool _isEvaluating = false;
  Timer? _frameTimer;

  // (file_picker no necesita instancia — usa FilePicker.platform)

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Modo vídeo es el default; la cámara se inicia solo si el usuario cambia
  }

  @override
  void dispose() {
    _stopStreaming(disconnect: true);
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Cámara ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No hay cámaras disponibles');

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de cámara: $e')),
        );
      }
    }
  }

  // ── Vídeo de prueba ───────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    await _videoController?.dispose();
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    await controller.setLooping(true);

    if (!mounted) return;
    setState(() {
      _videoController = controller;
      _videoReady = true;
    });
  }

  // ── Streaming / WebSocket ─────────────────────────────────────────────────

  Future<void> _startStreaming() async {
    final notifier = ref.read(eppTrainingProvider.notifier);
    final ws       = ref.read(eppWebSocketServiceProvider);

    // Leer token Sanctum y aprendiz seleccionado
    final token    = await ref.read(secureStorageProvider).readToken() ?? '';
    final aprendiz = ref.read(selectedAprendizProvider);

    await notifier.connect(authToken: token, aprendizId: aprendiz?.id);

    // ── Requiere conexión WS ───────────────────────────────────────────────
    if (!ref.read(eppTrainingProvider).isConnected) return;

    if (_mode == _InputMode.camera) {
      await _cameraController!.startImageStream((image) {
        if (!_isStreaming) return;
        ws.sendCameraFrame(image);
      });
    } else {
      await _videoController!.play();
      _frameTimer = Timer.periodic(
        const Duration(milliseconds: 120), // ~8 FPS
        (_) => _captureAndSendVideoFrame(ws),
      );
    }

    if (mounted) setState(() => _isStreaming = true);
  }

  Future<void> _captureAndSendVideoFrame(EppWebSocketService ws) async {
    if (_isCapturingFrame || !_isStreaming) return;
    _isCapturingFrame = true;
    try {
      final context = _repaintKey.currentContext;
      if (context == null) return;

      final boundary =
          context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Captura el widget renderizado como imagen RGBA
      final uiImage = await boundary.toImage(pixelRatio: 0.6);
      final byteData =
          await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final rgba = byteData.buffer.asUint8List();
      final jpeg = await _rgbaToJpeg(
        rgba,
        uiImage.width,
        uiImage.height,
      );

      ws.sendJpegBytes(jpeg);
    } catch (e) {
      debugPrint('[EppScreen] Error capturando frame: $e');
    } finally {
      _isCapturingFrame = false;
    }
  }

  Future<Uint8List> _rgbaToJpeg(
      Uint8List rgba, int width, int height) async {
    final imgLib = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      format: img.Format.uint8,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(imgLib, quality: 70));
  }

  void _stopStreaming({bool disconnect = false}) {
    _frameTimer?.cancel();
    _frameTimer = null;

    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _videoController?.pause();

    if (disconnect) {
      ref.read(eppTrainingProvider.notifier).disconnect();
    }

    if (mounted) setState(() => _isStreaming = false);
  }

  /// Termina el ejercicio: pausa vídeo, cancela timers, cierra WebSocket.
  Future<void> _terminateTraining() async {
    try {
      _frameTimer?.cancel();
      _frameTimer = null;

      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.seekTo(Duration.zero);
      }

      await ref.read(eppTrainingProvider.notifier).disconnect();

      if (mounted) {
        setState(() => _isStreaming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrenamiento finalizado'),
            backgroundColor: AppColors.success600,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[EppScreen] Error terminando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: AppColors.primary5),
        );
      }
    }
  }

  // ── Evaluación GRU ────────────────────────────────────────────────────────

  void _openEvaluationResultScreen(Map<String, dynamic> result) {
    final precision = (result['precision'] as num?)?.toDouble() ?? 0.0;
    final totalVent = (result['total_ventanas'] as num?)?.toInt() ?? 0;
    final correctos = (result['correctos'] as List?)?.cast<String>() ?? [];
    final incorrectos =
        (result['incorrectos'] as List?)?.cast<String>() ?? [];
    final scores = (result['scores'] as Map<String, dynamic>?) ?? {};
    final laravelPayload =
        (result['laravel_payload'] as Map<String, dynamic>?) ?? {};

    context.push(
      RouteNames.eppEvaluationResult,
      extra: EppEvaluationResultArgs(
        precision: precision,
        totalVentanas: totalVent,
        correctos: correctos,
        incorrectos: incorrectos,
        scores: scores,
        laravelPayload: laravelPayload,
      ),
    );
  }

  Future<void> _evaluateWithGRU() async {
    setState(() => _isEvaluating = true);

    // ── Evaluación con FastAPI ───────────────────────────────────────────────
    try {
      final sessionId = ref.read(eppTrainingProvider).sessionId;

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception(
            'No hay session_id disponible. Realiza un entrenamiento primero.');
      }

      final dio = Dio();
      final response = await dio.post(
        '${Env.fastApiBaseUrl}/api/epp/evaluate',
        data: {'session_id': sessionId},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _openEvaluationResultScreen(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Respuesta inesperada: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de red: ${e.message}'),
            backgroundColor: AppColors.primary5,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.primary5,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  // ── Cambio de modo ────────────────────────────────────────────────────────

  Future<void> _switchMode(_InputMode mode) async {
    if (mode == _mode) return;
    _stopStreaming(disconnect: true);

    setState(() {
      _mode = mode;
      _cameraReady = false;
    });

    if (mode == _InputMode.camera) {
      await _initCamera();
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eppTrainingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fondo: cámara o vídeo ────────────────────────────────────
            _BackgroundView(
              mode: _mode,
              cameraController: _cameraController,
              cameraReady: _cameraReady,
              videoController: _videoController,
              videoReady: _videoReady,
              repaintKey: _repaintKey,
            ),

            // ── Marco de detección ───────────────────────────────────────
            if (_mode == _InputMode.camera && _cameraReady ||
                _mode == _InputMode.video && _videoReady)
              const _ScanFrame(),

            // ── Barra superior ───────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                mode: _mode,
                onBack: () => Navigator.pop(context),
                onModeChanged: _switchMode,
              ),
            ),

            // ── Panel inferior ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomPanel(
                mode: _mode,
                state: state,
                isStreaming: _isStreaming,
                isEvaluating: _isEvaluating,
                videoReady: _videoReady,
                cameraReady: _cameraReady,
                onPickVideo: _pickVideo,
                onStart: _startStreaming,
                onTerminate: _terminateTraining,
                onEvaluate: _evaluateWithGRU,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fondo: cámara o reproductor de vídeo
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundView extends StatelessWidget {
  const _BackgroundView({
    required this.mode,
    required this.cameraController,
    required this.cameraReady,
    required this.videoController,
    required this.videoReady,
    required this.repaintKey,
  });

  final _InputMode mode;
  final CameraController? cameraController;
  final bool cameraReady;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final GlobalKey repaintKey;

  @override
  Widget build(BuildContext context) {
    if (mode == _InputMode.camera) {
      if (!cameraReady || cameraController == null) {
        return const _CenteredHint(
          icon: Icons.videocam_off_outlined,
          text: 'Inicializando cámara…',
        );
      }
      return CameraPreview(cameraController!);
    }

    // Modo vídeo
    if (!videoReady || videoController == null) {
      return const _CenteredHint(
        icon: Icons.video_library_outlined,
        text: 'Selecciona un vídeo de prueba',
      );
    }

    return RepaintBoundary(
      key: repaintKey,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: videoController!.value.size.width,
          height: videoController!.value.size.height,
          child: VideoPlayer(videoController!),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Marco de esquinas
// ─────────────────────────────────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width * 0.68;
    return Center(
      child: SizedBox(
        width: w,
        height: w * 1.35,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.primary5
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const c = 28.0;

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o + Offset(dx, 0), p);
      canvas.drawLine(o, o + Offset(0, dy), p);
    }

    corner(Offset.zero, c, c);
    corner(Offset(size.width, 0), -c, c);
    corner(Offset(0, size.height), c, -c);
    corner(Offset(size.width, size.height), -c, -c);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra superior
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.onBack,
    required this.onModeChanged,
  });

  final _InputMode mode;
  final VoidCallback onBack;
  final ValueChanged<_InputMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
          // Toggle Cámara / Vídeo
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeChip(
                  label: 'Cámara',
                  icon: Icons.videocam_rounded,
                  selected: mode == _InputMode.camera,
                  onTap: () => onModeChanged(_InputMode.camera),
                ),
                _ModeChip(
                  label: 'Vídeo',
                  icon: Icons.video_library_rounded,
                  selected: mode == _InputMode.video,
                  onTap: () => onModeChanged(_InputMode.video),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary5 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel inferior de clasificación
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.mode,
    required this.state,
    required this.isStreaming,
    required this.isEvaluating,
    required this.videoReady,
    required this.cameraReady,
    required this.onPickVideo,
    required this.onStart,
    required this.onTerminate,
    required this.onEvaluate,
  });

  final _InputMode mode;
  final EppTrainingState state;
  final bool isStreaming;
  final bool isEvaluating;
  final bool videoReady;
  final bool cameraReady;
  final VoidCallback onPickVideo;
  final VoidCallback onStart;
  final VoidCallback onTerminate;
  final VoidCallback onEvaluate;

  bool get _canStart =>
      !isStreaming &&
      !state.isConnecting &&
      (mode == _InputMode.camera ? cameraReady : videoReady);

  bool get _canEvaluate =>
      !isStreaming &&
      !state.isConnected &&
      !isEvaluating &&
      state.history.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary800.withAlpha(230),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondary500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Badge modo simulación ───────────────────────────────────────
          // if (isSimulation)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 10),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Container(
          //           padding: const EdgeInsets.symmetric(
          //               horizontal: 10, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: AppColors.info600.withAlpha(40),
          //             borderRadius: BorderRadius.circular(20),
          //             border: Border.all(color: AppColors.info600, width: 1),
          //           ),
          //           child: const Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Icon(Icons.science_rounded,
          //                   size: 13, color: AppColors.info600),
          //               SizedBox(width: 5),
          //               Text(
          //                 'MODO SIMULACIÓN',
          //                 style: TextStyle(
          //                   color: AppColors.info600,
          //                   fontSize: 11,
          //                   fontWeight: FontWeight.w700,
          //                   letterSpacing: 0.8,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),

          // ── Estado / clasificación actual ───────────────────────────────
          _ClassificationBadge(state: state, isStreaming: isStreaming),

          const SizedBox(height: 14),

          // ── Indicador de pasos ──────────────────────────────────────────
          _StepProgress(
            currentStep: state.currentStep,
            completedIds: state.completedStepIds,
          ),

          const SizedBox(height: 16),

          // ── Error ───────────────────────────────────────────────────────
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: AppColors.primary4,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),

          // ── Botón seleccionar vídeo (solo modo vídeo) ───────────────────
          if (mode == _InputMode.video && !isStreaming) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.video_library_rounded, size: 16),
                label: Text(videoReady
                    ? 'Cambiar vídeo de prueba'
                    : 'Seleccionar vídeo de prueba'),
                onPressed: onPickVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary300,
                  side: const BorderSide(color: AppColors.secondary500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Controles ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  label: state.isConnecting ? 'Conectando…' : 'INICIAR',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success600,
                  enabled: _canStart,
                  onTap: onStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ControlButton(
                  label: 'TERMINAR',
                  icon: Icons.stop_rounded,
                  color: AppColors.primary5,
                  enabled: isStreaming,
                  onTap: onTerminate,
                ),
              ),
            ],
          ),

          // ── Botón evaluar con GRU ────────────────────────────────────────
          if (_canEvaluate || (state.history.isNotEmpty && !isStreaming)) ...[  
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: isEvaluating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics_rounded, size: 18),
                label: Text(
                  isEvaluating ? 'Evaluando…' : 'EVALUAR EJERCICIO (GRU)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: _canEvaluate ? onEvaluate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.secondary700,
                  disabledForegroundColor:
                      AppColors.secondary500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de clasificación actual
// ─────────────────────────────────────────────────────────────────────────────

class _ClassificationBadge extends StatelessWidget {
  const _ClassificationBadge({
    required this.state,
    required this.isStreaming,
  });
  final EppTrainingState state;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final cls = state.lastClassification;
    final step = state.currentStep;

    // Indicador de conexión
    final dotColor =
        state.isConnected ? AppColors.success700 : AppColors.secondary500;
    final statusText = !isStreaming
        ? 'Detenido'
        : state.isConnecting
            ? 'Conectando…'
            : state.isConnected
                ? 'Conectado'
                : 'Sin conexión';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado + latencia
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: state.isConnected
                    ? AppColors.success700
                    : AppColors.secondary400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (cls != null) ...[
              const Spacer(),
              Text(
                '${cls.latenciaMs.toStringAsFixed(0)} ms',
                style: const TextStyle(
                  color: AppColors.secondary400,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Paso actual
        Text(
          step == EppStep.acumulando && !isStreaming
              ? 'Listo para iniciar'
              : step.displayName,
          style: TextStyle(
            color: step == EppStep.acumulando
                ? AppColors.secondary300
                : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),

        if (cls != null && step != EppStep.acumulando) ...[
          const SizedBox(height: 8),
          // Barra de confianza
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cls.confianza,
              minHeight: 6,
              backgroundColor: AppColors.secondary700,
              valueColor: AlwaysStoppedAnimation<Color>(
                cls.confianza >= 0.5
                    ? AppColors.success500
                    : AppColors.accent300,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confianza: ${(cls.confianza * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.secondary300,
              fontSize: 12,
            ),
          ),
        ],

        if (cls == null && isStreaming)
          const Text(
            'Acumulando frames para clasificar…',
            style: TextStyle(
              color: AppColors.secondary400,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicador de progreso de pasos EPP
// ─────────────────────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.currentStep,
    required this.completedIds,
  });

  final EppStep currentStep;
  final Set<int> completedIds;

  @override
  Widget build(BuildContext context) {
    final steps = EppStep.eppSteps; // 6 pasos reales

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASOS EPP',
          style: TextStyle(
            color: AppColors.secondary500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.map((step) {
            final isDone = completedIds.contains(step.id);
            final isCurrent = currentStep == step;

            Color bg;
            Color fg;
            if (isDone) {
              bg = AppColors.success600;
              fg = Colors.white;
            } else if (isCurrent) {
              bg = AppColors.primary5;
              fg = Colors.white;
            } else {
              bg = AppColors.secondary700;
              fg = AppColors.secondary400;
            }

            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 14,
                              color: Colors.white)
                          : Text(
                              '${step.id + 1}',
                              style: TextStyle(
                                color: fg,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.displayName.split(' ').first, // Abreviación
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent || isDone
                          ? Colors.white
                          : AppColors.secondary500,
                      fontSize: 9,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de control
// ─────────────────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.secondary700,
          disabledForegroundColor: AppColors.secondary500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary500, size: 48),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.secondary400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
