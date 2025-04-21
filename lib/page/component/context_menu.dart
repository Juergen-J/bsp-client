import 'package:flutter/material.dart';

Future<T?> showContextMenuForWidget<T>({
  required BuildContext context,
  required GlobalKey key,
  required List<PopupMenuEntry<T>> items,
}) async {
  final contextForKey = key.currentContext;
  if (contextForKey == null) {
    debugPrint('Key is not attached to any widget');
    return null;
  }

  final renderBox = contextForKey.findRenderObject() as RenderBox;
  final widgetPosition = renderBox.localToGlobal(Offset.zero);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  return await showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(
        widgetPosition.dx,
        widgetPosition.dy + renderBox.size.height,
        renderBox.size.width,
        renderBox.size.height,
      ),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}
