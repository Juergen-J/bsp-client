import 'package:flutter/material.dart';

final BoxDecoration inputFieldDecoration = BoxDecoration(
  color: Colors.grey.shade100,
  borderRadius: BorderRadius.circular(24),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
);

// ModalStyle class that accepts inputFieldDecoration
class ModalStyle {
  final BoxDecoration inputFieldDecoration;

  const ModalStyle({required this.inputFieldDecoration});
}

// ModalStyleProvider that provides access to ModalStyle
class ModalStyleProvider extends InheritedWidget {
  final ModalStyle style;

  const ModalStyleProvider({
    super.key,
    required this.style,
    required super.child,
  });

  // Method to access ModalStyle from context
  static ModalStyle of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ModalStyleProvider>();
    assert(result != null, 'No ModalStyleProvider found in context');
    return result!.style;
  }

  @override
  bool updateShouldNotify(ModalStyleProvider oldWidget) =>
      style != oldWidget.style;
}
