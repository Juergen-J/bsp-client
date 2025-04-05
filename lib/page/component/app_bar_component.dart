import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../service/auth_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final GlobalKey avatarKey;
  final double contentWidth;

  const CustomAppBar({
    Key? key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.avatarKey,
    required this.contentWidth,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  void _showContextMenu(BuildContext context) {
    final renderBox = avatarKey.currentContext!.findRenderObject() as RenderBox;
    final avatarPosition = renderBox.localToGlobal(Offset.zero);
    final authService = Provider.of<AuthService>(context, listen: false);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        avatarPosition.dx,
        avatarPosition.dy + renderBox.size.height,
        avatarPosition.dx + renderBox.size.width,
        0,
      ),
      items: [
        if (!authService.isLoggedIn)
          PopupMenuItem(
            child: const Text('Login'),
            onTap: () {
              Future.microtask(() => context.pushReplacement('/login'));
            },
          ),
        PopupMenuItem(
          onTap: () {
            Future.microtask(() => context.pushReplacement('/me'));
          },
          child: const Text("Profile"),
        ),
        if (authService.isLoggedIn)
          PopupMenuItem(
            child: Text("Logout"),
            onTap: () async {
              await authService.logout();
              Future.microtask(() => context.pushReplacement('/home'));
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: const Center(
            child: Text(
              'Logo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 0,
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          onPressed: onThemeToggle,
        ),
        GestureDetector(
          key: avatarKey,
          onTap: () => _showContextMenu(context),
          child: const CircleAvatar(
            child: Icon(Icons.person),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
