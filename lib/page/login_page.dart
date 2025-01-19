import 'package:flutter/material.dart';
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
    var colorScheme = Theme.of(context).colorScheme;
    var appState = Provider.of<AppState>(context);

    return LayoutBuilder(builder: (context, constraints) {
      double contentWidth =
          constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
            isDarkMode: appState.isDarkMode,
            onThemeToggle: appState.toggleTheme,
            avatarKey: avatarKey,
            contentWidth: contentWidth),
        body: Center(
          child: Container(
            color: colorScheme.onPrimary,
            child: SizedBox(
              width: contentWidth,
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
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
                          minimumSize: const Size(double.infinity, 40),
                          backgroundColor: colorScheme.secondaryContainer,
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
