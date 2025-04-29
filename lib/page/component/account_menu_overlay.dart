import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../service/auth_service.dart';
import '../modal/modal_service.dart';
import '../modal/modal_type.dart';

class AccountMenuOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, GlobalKey key) {
    if (_entry != null) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final overlay = Overlay.of(context);

    final appState = context.read<AppState>();
    final authService = context.read<AuthService>();
    final colorScheme = Theme.of(context).colorScheme;

    _entry = OverlayEntry(
      builder: (_) => GestureDetector(
        onTap: hide,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              top: offset.dy + size.height + 8,
              left: offset.dx - 200 + size.width,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mein Konto',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondary)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: hide,
                              color: colorScheme.onSecondary,
                            ),
                          ],
                        ),
                      ),
                      if (authService.isLoggedIn) ...[
                        _item(context, Icons.person, colorScheme.onSecondary,
                            'Mein Profil', colorScheme.onSurfaceVariant, () {
                          hide();
                          context.push('/me');
                        }),
                        _item(context, Icons.devices, colorScheme.onSurface,
                            'Devices', colorScheme.onSurfaceVariant, () {
                          hide();
                          context.push('/devices');
                        }),
                        _item(context, Icons.widgets, colorScheme.onSurface,
                            'Services', colorScheme.onSurfaceVariant, () {
                          hide();
                          context.push('/services');
                        }),
                        _item(
                            context,
                            Icons.favorite_border,
                            colorScheme.onSurface,
                            'Merkliste',
                            colorScheme.onSurfaceVariant, () {
                          hide();
                          context.push('/favorites');
                        }),
                        const Divider(height: 1),
                        _item(
                            context,
                            Icons.logout,
                            colorScheme.onSurface,
                            'Ausloggen',
                            colorScheme.onSurfaceVariant, () async {
                          hide();
                          await authService.logout();
                          context.pushReplacement('/home');
                        }),
                      ] else ...[
                        _item(context, Icons.login, colorScheme.onSurface,
                            'Login', colorScheme.onSurfaceVariant, () {
                          hide();
                          context.read<ModalManager>().show(ModalType.login);
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static Widget _item(BuildContext context, IconData icon, Color iconColor,
      String label, Color labelColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: labelColor)),
            ),
          ],
        ),
      ),
    );
  }
}
