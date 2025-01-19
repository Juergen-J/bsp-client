import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../app/router.dart';
import 'component/app_bar_component.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = Provider.of<AppState>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth =
            constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: CustomAppBar(
            isDarkMode: appState.isDarkMode,
            onThemeToggle: appState.toggleTheme,
            avatarKey: avatarKey,
            contentWidth: contentWidth,
          ),
          body: Center(
            child: Container(
              width: contentWidth,
              color: colorScheme.surface,
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Replace with actual login redirect
                          print('Login button pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Replace with actual registration redirect
                          print('Registration button pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
