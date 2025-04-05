import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopNavigationMenu extends StatelessWidget {
  const TopNavigationMenu({super.key});

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

    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 1200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.map((item) {
              final isSelected = currentPath.startsWith(item.path);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => context.go(item.path),
                  child: Text(
                    item.label,
                    style: textStyle?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
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