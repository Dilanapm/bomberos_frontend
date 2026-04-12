import 'package:flutter/material.dart';

/// Envuelve cualquier widget y añade una animación de escala al presionarlo.
///
/// Usa [Listener] en lugar de [GestureDetector] para no interferir con
/// los manejadores de gestos del widget hijo (botones, InkWell, etc.).
///
/// Parámetros:
/// - [scaleDown] : escala mínima al presionar (por defecto 0.96).
/// - [enabled]   : si es false la animación no se activa (p. ej. botón deshabilitado).
///
/// Ejemplo:
/// ```dart
/// TapScale(
///   child: ElevatedButton(onPressed: _submit, child: Text('Guardar')),
/// )
/// ```
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.scaleDown = 0.96,
    this.enabled   = true,
  });

  final Widget child;
  final double scaleDown;
  final bool   enabled;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:           this,
      duration:        const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent:       _ctrl,
        curve:        Curves.easeIn,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    if (widget.enabled) _ctrl.forward();
  }

  void _onUp(PointerUpEvent _) {
    if (widget.enabled) _ctrl.reverse();
  }

  void _onCancel(PointerCancelEvent _) {
    if (widget.enabled) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:   _onDown,
      onPointerUp:     _onUp,
      onPointerCancel: _onCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
