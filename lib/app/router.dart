import 'package:berlin_service_portal/page/component/footer_component.dart';
import 'package:berlin_service_portal/page/component/top_navigation_menu.dart';
import 'package:berlin_service_portal/page/devices_page.dart';
import 'package:berlin_service_portal/page/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/short_device.dart';
import '../page/component/app_bar_component.dart';
import '../page/device_form_page.dart';
import '../page/home_page.dart';
import '../page/login_page.dart';
import '../page/messages_page.dart';
import '../page/password_recovery_page.dart';
import '../page/profile_page.dart';
import '../page/register_page.dart';
import 'app_state.dart';

final ValueNotifier<bool> isMessagesWindowOpen = ValueNotifier(false);
final GlobalKey _avatarKey = GlobalKey();

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/verify-email',
      name: 'verify email',
      builder: (context, state) => VerifyEmailPage(
        email: state.extra as String,
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: '/forgot-password',
      builder: (context, state) => const PasswordRecoveryPage(),
    ),
    GoRoute(
      path: '/device-form',
      name: 'device_form',
      builder: (context, state) {
        final ShortDevice? device = state.extra as ShortDevice?;
        return DeviceFormPage(editedDevice: device);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        var colorScheme = Theme.of(context).colorScheme;
        var appState = Provider.of<AppState>(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            double contentWidth =
                constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;
            bool isMobile = constraints.maxWidth < 450;

            return Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: CustomAppBar(
                isDarkMode: appState.isDarkMode,
                onThemeToggle: appState.toggleTheme,
                contentWidth: contentWidth,
                avatarKey: _avatarKey,
              ),
              body: isMobile
                  ? Column(
                      children: [
                        Expanded(child: navigationShell),
                        SafeArea(
                          child: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            currentIndex: _getSelectedIndex(context) ?? 0,
                            onTap: (index) => navigationShell.goBranch(index),
                            items: const [
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.home), label: 'Home'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.favorite),
                                  label: 'Favorites'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.message), label: 'Messages'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.devices), label: 'Devices'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.sell_rounded),
                                  label: 'Services'),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          color: colorScheme.surface,
                          child: Center(
                            child: SizedBox(
                              width: contentWidth,
                              child: const TopNavigationMenu(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: Center(
                                  child: SizedBox(
                                    width: contentWidth,
                                    child: navigationShell,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  heroTag: null,
                                  onPressed: () {
                                    isMessagesWindowOpen.value =
                                        !isMessagesWindowOpen.value;
                                  },
                                  child: const Icon(Icons.message),
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: isMessagesWindowOpen,
                                builder: (context, isOpen, child) {
                                  if (isOpen) {
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const MessagesPage(),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: colorScheme.primary,
                          child: Center(
                            child: FooterComponent(contentWidth: contentWidth),
                          ),
                        ),
                      ],
                    ),
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
              builder: (context, state) => const DevicesPage(),
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
        child: const MessagesPage(),
      ),
    ),
  );
}
