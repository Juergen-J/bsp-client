import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../page/component/app_bar_component.dart';
import '../page/home_page.dart';
import '../page/login_page.dart';
import '../page/messages_page.dart';
import '../page/profile_page.dart';
import 'app_state.dart';

final ValueNotifier<bool> isMessagesWindowOpen = ValueNotifier(false);
final GlobalKey avatarKey = GlobalKey();

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        var colorScheme = Theme.of(context).colorScheme;
        var appState = Provider.of<AppState>(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            double contentWidth =
                constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;

            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: CustomAppBar(
                isDarkMode: appState.isDarkMode,
                onThemeToggle: appState.toggleTheme,
                avatarKey: avatarKey,
                contentWidth: contentWidth,
              ),
              body: Container(
                color: colorScheme.surface,
                child: Stack(children: [
                  Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: constraints.maxWidth < 450
                          ? Column(
                              children: [
                                Expanded(child: navigationShell),
                                SafeArea(
                                  child: BottomNavigationBar(
                                    type: BottomNavigationBarType.fixed,
                                    // todo selected index by /me path???
                                    currentIndex:
                                        _getSelectedIndex(context) ?? -1,
                                    // currentIndex: navigationShell.currentIndex,
                                    onTap: (index) =>
                                        navigationShell.goBranch(index),
                                    items: const [
                                      BottomNavigationBarItem(
                                          icon: Icon(Icons.home),
                                          label: 'Home'),
                                      BottomNavigationBarItem(
                                          icon: Icon(Icons.favorite),
                                          label: 'Favorites'),
                                      BottomNavigationBarItem(
                                          icon: Icon(Icons.message),
                                          label: 'Messages'),
                                      BottomNavigationBarItem(
                                          icon: Icon(Icons.devices),
                                          label: 'Devices'),
                                      BottomNavigationBarItem(
                                          icon: Icon(Icons.sell_rounded),
                                          label: 'Services'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                NavigationRail(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  indicatorColor: colorScheme.onInverseSurface,
                                  extended: constraints.maxWidth > 800,
                                  destinations: const [
                                    NavigationRailDestination(
                                      icon: Icon(Icons.home),
                                      label: Text('Home'),
                                    ),
                                    NavigationRailDestination(
                                      icon: Icon(Icons.favorite),
                                      label: Text('Favorites'),
                                    ),
                                    NavigationRailDestination(
                                      icon: Icon(Icons.message),
                                      label: Text('Messages'),
                                    ),
                                    NavigationRailDestination(
                                        icon: Icon(Icons.devices),
                                        label: Text('Devices')),
                                    NavigationRailDestination(
                                        icon: Icon(Icons.sell_rounded),
                                        label: Text('Services')),
                                  ],
                                  selectedIndex: _getSelectedIndex(context),
                                  onDestinationSelected: (index) =>
                                      navigationShell.goBranch(index),
                                ),
                                const VerticalDivider(thickness: 1, width: 1),
                                Expanded(
                                  child: navigationShell,
                                ),
                              ],
                            ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isMessagesWindowOpen,
                    builder: (context, isOpen, child) {
                      if (constraints.maxWidth >= 450 && isOpen) {
                        return Positioned(
                          right: 16,
                          bottom: 80,
                          child: _buildFloatingMessagesWindow(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ]),
              ),
              floatingActionButton: constraints.maxWidth >= 450
                  ? FloatingActionButton(
                      onPressed: () {
                        isMessagesWindowOpen.value =
                            !isMessagesWindowOpen.value;
                        print("Messages $isMessagesWindowOpen");
                      },
                      child: Icon(Icons.message),
                    )
                  : null,
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
              builder: (context, state) => const MessagesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              name: 'devices',
              builder: (context, state) => const Placeholder(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/service',
              name: 'service',
              builder: (context, state) => const Placeholder(),
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

Widget _buildFloatingMessagesWindow() {
  return Positioned(
    right: 16,
    bottom: 80,
    child: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MessagesPage(),
      ),
    ),
  );
}
