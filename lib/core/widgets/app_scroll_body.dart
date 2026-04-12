import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Reemplaza [SingleChildScrollView] añadiendo automáticamente
/// [MediaQuery.viewPaddingOf(context).bottom] al padding inferior.
///
/// Esto garantiza que el último elemento del scroll nunca quede oculto
/// detrás de la barra de navegación del sistema, el indicador de gestos
/// o cualquier otro elemento de UI del SO, en cualquier dispositivo.
///
/// Acepta los mismos parámetros relevantes que [SingleChildScrollView].
///
/// Ejemplo:
/// ```dart
/// body: AppScrollBody(
///   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
///   child: Column(children: [...]),
/// )
/// ```
class AppScrollBody extends StatelessWidget {
  const AppScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
    this.keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.onDrag,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.clipBehavior = Clip.hardEdge,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  final Widget                          child;
  final EdgeInsetsGeometry?             padding;
  final ScrollController?               controller;
  final ScrollPhysics?                  physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Axis                            scrollDirection;
  final bool                            reverse;
  final Clip                            clipBehavior;
  final DragStartBehavior               dragStartBehavior;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // Resolve the caller-provided padding (or zero) and add the safe-area
    // bottom inset so the last item is always scrollable above system UI.
    final base = padding?.resolve(Directionality.of(context)) ??
        EdgeInsets.zero;
    final resolved = base.copyWith(bottom: base.bottom + bottomInset);

    return SingleChildScrollView(
      padding:                 resolved,
      controller:              controller,
      physics:                 physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      scrollDirection:         scrollDirection,
      reverse:                 reverse,
      clipBehavior:            clipBehavior,
      dragStartBehavior:       dragStartBehavior,
      child: child,
    );
  }
}

/// Espaciador para el final de un [ListView] o [Column] que suma
/// [MediaQuery.viewPaddingOf(context).bottom] + [extra] de altura.
///
/// Colócalo como último elemento de la lista para que el contenido nunca
/// quede tapado por la barra de navegación del sistema.
class AppSafeBottom extends StatelessWidget {
  const AppSafeBottom({super.key, this.extra = 16});

  /// Espacio adicional por encima del safe-area inset.
  final double extra;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.viewPaddingOf(context).bottom + extra,
    );
  }
}
