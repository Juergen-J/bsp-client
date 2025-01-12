import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../pages/messages_page.dart';
import '../pages/profile_page.dart';
import 'app_state.dart';

final ValueNotifier<bool> isMessagesWindowOpen = ValueNotifier(false);
final GlobalKey avatarKey = GlobalKey();

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
                constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;

            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56.0),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: AppBar(
                      backgroundColor: colorScheme.primaryContainer,
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
                          icon: Icon(appState.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode),
                          onPressed: appState.toggleTheme,
                        ),
                        GestureDetector(
                          key: avatarKey,
                          onTap: () => _showContextMenu(context),
                          child: CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
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
                                    currentIndex: navigationShell.currentIndex,
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
                                  selectedIndex: navigationShell.currentIndex,
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
              path: '/services',
              name: 'services',
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

void _showContextMenu(BuildContext context) {
  final RenderBox avatarBox =
      avatarKey.currentContext!.findRenderObject() as RenderBox;
  final Offset avatarPosition = avatarBox.localToGlobal(Offset.zero);

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      avatarPosition.dx,
      avatarPosition.dy + avatarBox.size.height,
      avatarPosition.dx + avatarBox.size.width,
      0,
    ),
    items: [
      PopupMenuItem(
        child: Text("Profile"),
        onTap: () {
          Future.microtask(() => context.push('/me'));
        },
      ),
      PopupMenuItem(
        child: Text("Logout"),
      ),
    ],
  );
}
