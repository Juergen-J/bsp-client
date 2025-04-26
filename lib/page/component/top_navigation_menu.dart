import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopNavigationMenu extends StatelessWidget implements PreferredSizeWidget {
  final double contentWidth;
  final double height;

  const TopNavigationMenu(
      {super.key, required this.contentWidth, required this.height});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge;

    final items = [
      _NavItem('Home', '/home'),
      _NavItem('Devices', '/devices'),
      _NavItem('Services', '/service'),
      _NavItem('Favorites', '/favorites'),
      _NavItem('Messages', '/messages'),
    ];

    final currentPath =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    return Container(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: contentWidth,
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.map((item) {
                final isSelected = currentPath.startsWith(item.path);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: () => context.go(item.path),
                    child: Text(
                      item.label,
                      style: textStyle?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String path;

  _NavItem(this.label, this.path);
}
