import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../service/auth_service.dart';
import 'component/app_bar_component.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  bool _incorrectCode = false;
  bool _incorrectEmail = false;
  bool _showCodePart = false;
  final GlobalKey _avatarKeyLogin = GlobalKey();

  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  final _formKey = GlobalKey<FormState>();

  Widget _getEmailFieldOrPasswordRecoveryPart(width, colorScheme) {
    if (!_showCodePart) {
      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Willkommen bei 3D...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wir wissen, wie ärgerlich es ist, etwas zu vergessen, aber wir helfen Ihnen, Ihr Passwort wiederherzustellen. Geben Sie hierzu Ihre E-Mail-Adresse ein.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-Mail *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.email),
              ),
              onChanged: (value) {
                _incorrectEmail = false;
              },
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte E-Mail eingeben';
                } else if (_incorrectEmail) {
                  return 'Falsche E-Mail';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authService = context.read<AuthService>();
                    try {
                      String error = await authService.sendPasswordRecoveryCode(
                          _emailController.text.trim());
                      if (error.isNotEmpty) {
                        setState(() {
                          _incorrectEmail = true;
                          _showCodePart = false;
                        });
                        _formKey.currentState!.validate();
                      } else {
                        setState(() {
                          _incorrectEmail = false;
                          _showCodePart = true;
                        });
                      }
                    } catch (e) {
                      print('Verification error: $e');
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Anfrage senden'),
                    SizedBox(width: 8)
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Willkommen bei 3D...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Geben Sie den Code ein, der Ihnen per E-Mail zugesandt wurde: ${_emailController.text}.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: width,
              child: Pinput(
                controller: _codeController,
                length: 6,
                autofocus: true,
                validator: (value) {
                  if (value!.length < 6 || _incorrectCode) {
                    return 'Pin ist falsch';
                  } else {
                    return null;
                  }
                },
                onChanged: (value) {
                  _incorrectCode = false;
                },
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                defaultPinTheme: PinTheme(
                    height: 60.0,
                    width: 60.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    )),
              ),
            ),
            const SizedBox(height: 16),
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Passwort *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Passwort eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePasswordConfirm,
              decoration: InputDecoration(
                labelText: 'Passwort bestätigen *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePasswordConfirm =
                      !_obscurePasswordConfirm;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Passwort bestätigen';
                }
                if (value != _passwordController.text) {
                  return 'Passwörter stimmen nicht überein';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authService = context.read<AuthService>();
                    try {
                      String error = await authService.recoverPassword(
                          _emailController.text.trim(),
                          _codeController.text.trim(),
                        _passwordController.text
                      );
                      if (error.isNotEmpty) {
                        _incorrectCode = true;
                        _formKey.currentState!.validate();
                      } else {
                        context.go('/login');
                      }
                    } catch (e) {
                      print('Verification error: $e');
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Anfrage senden'),
                    SizedBox(width: 8)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
            contentWidth: contentWidth,
            avatarKey: _avatarKeyLogin,
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
                  child: _getEmailFieldOrPasswordRecoveryPart(width, colorScheme),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
