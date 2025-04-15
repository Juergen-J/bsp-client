import 'package:berlin_service_portal/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../service/auth_service.dart';
import '../modal/modal_service.dart';
import '../modal/modal_type.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final GlobalKey avatarKey;
  final GlobalKey languageKey;
  final double contentWidth;

  const CustomAppBar({
    Key? key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.avatarKey,
    required this.languageKey,
    required this.contentWidth,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  void _showLanguageContextMenu(BuildContext context) {
    final contextForKey = languageKey.currentContext;
    if (contextForKey == null) {
      debugPrint('languageKey is not attached yet');
      return;
    }

    final renderBox = contextForKey.findRenderObject() as RenderBox;
    final languagePosition = renderBox.localToGlobal(Offset.zero);
    final appState = Provider.of<AppState>(context, listen: false);
    final locales = appState.supportedLocales;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          languagePosition.dx,
          languagePosition.dy + renderBox.size.height,
          renderBox.size.width,
          renderBox.size.height,
        ),
        Offset.zero & overlay.size,
      ),
      items: locales.map((locale) {
        return PopupMenuItem(
          value: locale,
          child: Text(locale.languageCode.toUpperCase()),
        );
      }).toList(),
    ).then((selectedLocale) {
      if (selectedLocale != null) {
        appState.changeLocale(selectedLocale);
      }
    });
  }

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
              context.read<ModalManager>().show(ModalType.login);
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
            child: const Text("Logout"),
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
    final locale = Provider.of<AppState>(context).locale;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      child: Center(
        child: Container(
          width: contentWidth,
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Логотип
              Row(
                children: [
                  const Text(
                    'Find',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Xpert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Строка поиска
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.location_pin, color: Colors.blue),
                        onPressed: () {
                          // handle geolocation tap
                        },
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/equalizer.svg',
                      color: colorScheme.onPrimary,
                      width: 24,
                      height: 20,
                    ),
                    onPressed: () {
                      // handle favorites tap
                    },
                  ),
                  Stack(alignment: Alignment.center, children: [
                    IconButton(
                      key: languageKey,
                      icon: SvgPicture.asset(
                        'assets/icons/language.svg',
                        colorFilter: ColorFilter.mode(
                            colorScheme.onPrimary, BlendMode.srcIn),
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        _showLanguageContextMenu(context);
                      },
                    ),
                    IgnorePointer(
                      child: Text(
                        locale.languageCode.toUpperCase(),
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    )
                  ])
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.white),
                    onPressed: onThemeToggle,
                  ),
                  GestureDetector(
                    key: avatarKey,
                    onTap: () => _showContextMenu(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
