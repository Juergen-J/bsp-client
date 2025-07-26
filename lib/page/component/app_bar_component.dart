import 'package:berlin_service_portal/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../util/user_info_sammler.dart';
import 'account_menu_overlay.dart';
import 'context_menu.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final GlobalKey avatarKey;
  final GlobalKey languageKey;

  // todo mobile view
  final double contentWidth;
  final double height;

  const CustomAppBar({super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.avatarKey,
    required this.languageKey,
    required this.contentWidth,
    required this.height});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final appState = Provider.of<AppState>(context);
    final locale = appState.locale;

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
              Row(
                children: [
                  Text(
                    'Find',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Xpert',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.location_pin,
                            color: colorScheme.primary),
                        onPressed: () async {
                          await fetchLocation();
                        },
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  // IconButton(
                  //   icon: SvgPicture.asset(
                  //     'assets/icons/equalizer.svg',
                  //     color: colorScheme.onPrimary,
                  //     width: 24,
                  //     height: 20,
                  //   ),
                  //   onPressed: () {
                  //     // handle favorites tap
                  //   },
                  // ),
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
                        showContextMenuForWidget<Locale>(
                          context: context,
                          key: languageKey,
                          items: appState.supportedLocales.map((locale) {
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
                        color: colorScheme.onPrimary),
                    onPressed: onThemeToggle,
                  ),
                  IconButton(
                    key: avatarKey,
                    tooltip: 'Account',
                    icon: SvgPicture.asset(
                      'assets/icons/profile.svg',
                      colorFilter: ColorFilter.mode(
                        colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () => AccountMenuOverlay.show(context, avatarKey),
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
