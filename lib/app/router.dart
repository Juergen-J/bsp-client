import 'package:berlin_service_portal/page/services_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../page/component/app_bar_component.dart';
import '../page/component/footer_component.dart';
import '../page/component/sticky_menu_delegate.dart';
import '../page/component/top_navigation_menu.dart';
import '../page/devices_page.dart';
import '../page/home_page.dart';
import '../page/messages_page.dart';
import '../page/modal/modal_overlay.dart';
import '../page/modal/modal_service.dart';
import '../page/modal/modal_type.dart';
import '../page/profile_page.dart';
import '../service/auth_redirect_service.dart';
import '../service/auth_service.dart';
import 'app_state.dart';

final ValueNotifier<bool> isMessagesWindowOpen = ValueNotifier(false);
final GlobalKey _avatarKey = GlobalKey();
final GlobalKey _languageKey = GlobalKey();
final ValueNotifier<String> homeSearchQuery = ValueNotifier<String>('');
final ValueNotifier<String?> homeSelectedCategoryId = ValueNotifier(null);

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        var colorScheme = Theme.of(context).colorScheme;
        var appState = Provider.of<AppState>(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            double contentWidth =
                constraints.maxWidth > 1290 ? 1290 : constraints.maxWidth;
            bool isMobile = constraints.maxWidth < 450;
            bool isOnMessagesPage = _getSelectedIndex(context) == 2;
            bool isLoggedIn =
                Provider.of<AuthService>(context, listen: false).isLoggedIn;

            bool showMessagesButton =
                constraints.maxWidth > 800 && !isOnMessagesPage && isLoggedIn;
            const double height = 60.0;
            const double kFooterHeight = 120.0;
            const double kFABBottomOffset = 24;
            const double kMessagesWindowBottomOffset = 96;

            return Stack(
              children: [
                isMobile
                    ? buildMobileScaffold(context, navigationShell,
                        contentWidth, colorScheme, appState, height)
                    : buildDesktopScaffold(
                        context,
                        navigationShell,
                        contentWidth,
                        colorScheme,
                        appState,
                        height,
                        kFooterHeight),
                if (showMessagesButton)
                  ...buildStickyMessages(
                      kFABBottomOffset, kMessagesWindowBottomOffset),
                const ModalOverlay(),
              ],
            );
          },
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const Placeholder(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              name: 'messages',
              redirect: (context, state) {
                final auth = Provider.of<AuthService>(context, listen: false);
                final modal = Provider.of<ModalManager>(context, listen: false);
                final redirectService =
                    Provider.of<AuthRedirectService>(context, listen: false);

                if (!auth.isLoggedIn) {
                  redirectService.saveRedirect(state.matchedLocation);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    modal.show(ModalType.login);
                  });
                  return '/home';
                }
                return null;
              },
              builder: (context, state) => const MessagesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              name: 'devices',
              builder: (context, state) => const DevicesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/service',
              name: 'service',
              builder: (context, state) => const ServicesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/me',
              name: 'me',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

List<Widget> buildStickyMessages(
    double kFABBottomOffset, double kMessagesWindowBottomOffset) {
  return [
    // Floating button
    Positioned(
      right: kFABBottomOffset,
      bottom: kMessagesWindowBottomOffset,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          isMessagesWindowOpen.value = !isMessagesWindowOpen.value;
        },
        child: const Icon(Icons.message),
      ),
    ),

    // Floating message window
    ValueListenableBuilder<bool>(
      valueListenable: isMessagesWindowOpen,
      builder: (context, isOpen, child) {
        if (!isOpen) return const SizedBox.shrink();

        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    isMessagesWindowOpen.value = false;
                  },
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
              Positioned(
                  right: kFABBottomOffset,
                  bottom: kMessagesWindowBottomOffset + 64,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Container(
                            width: 300,
                            height: 400,
                            color: Colors.white,
                            child: const MessagesPage(),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Закрыть',
                              onPressed: () {
                                isMessagesWindowOpen.value = false;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    ),
  ];
}

/// Desktop version (wide screen)
Widget buildDesktopScaffold(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    double contentWidth,
    ColorScheme colorScheme,
    AppState appState,
    double height,
    double kFooterHeight) {
  final auth = Provider.of<AuthService>(context);
  final isLoggedIn = auth.isLoggedIn;

  return Scaffold(
    backgroundColor: colorScheme.surface,
    appBar: CustomAppBar(
      isDarkMode: appState.isDarkMode,
      onThemeToggle: appState.toggleTheme,
      contentWidth: contentWidth,
      avatarKey: _avatarKey,
      languageKey: _languageKey,
      height: height,
    ),
    body: CustomScrollView(
      slivers: [
        if (isLoggedIn)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyMenuDelegate(
              height: height,
              child: TopNavigationMenu(
                contentWidth: contentWidth,
                height: height,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (ctx, c) {
              final viewportH = MediaQuery.of(ctx).size.height;
              final minBodyH = viewportH - kFooterHeight;

              return Column(
                children: [
                  // Место для контента страниц (navigationShell) c ЖЁСТКОЙ высотой:
                  Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: SizedBox(
                        height: minBodyH, // <-- ключевая строка
                        child:
                            navigationShell, // тут сидят Offstage/IndexedStack от go_router
                      ),
                    ),
                  ),

                  // Футер всегда внизу
                  FooterComponent(
                    contentWidth: contentWidth,
                    height: kFooterHeight,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Mobile version (narrow screen)
Widget buildMobileScaffold(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  double contentWidth,
  ColorScheme colorScheme,
  AppState appState,
  double height,
) {
  final auth = Provider.of<AuthService>(context);
  final isLoggedIn = auth.isLoggedIn;

  return Scaffold(
    backgroundColor: colorScheme.surface,
    appBar: CustomAppBar(
      isDarkMode: appState.isDarkMode,
      onThemeToggle: appState.toggleTheme,
      contentWidth: contentWidth,
      avatarKey: _avatarKey,
      languageKey: _languageKey,
      height: height,
    ),
    body: isLoggedIn
        ? Column(
            children: [
              Expanded(child: navigationShell),
              SafeArea(
                child: BottomNavigationBar(
                  backgroundColor: colorScheme.primary,
                  fixedColor: colorScheme.secondary,
                  unselectedItemColor: colorScheme.onPrimary,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _getSelectedIndex(context) ?? 0,
                  onTap: (index) => navigationShell.goBranch(index),
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.favorite), label: 'Favorites'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.message), label: 'Messages'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.devices), label: 'Devices'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.sell_rounded), label: 'Services'),
                  ],
                ),
              ),
            ],
          )
        : null,
  );
}

int? _getSelectedIndex(BuildContext context) {
  final location =
      GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

  switch (location) {
    case '/home':
      return 0;
    case '/favorites':
      return 1;
    case '/messages':
      return 2;
    case '/devices':
      return 3;
    case '/service':
      return 4;
    default:
      return null;
  }
}
