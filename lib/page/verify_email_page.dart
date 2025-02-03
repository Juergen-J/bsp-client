import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../service/auth_service.dart';
import 'component/app_bar_component.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email,});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState(this.email);
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _incorrectCode = false;
  final GlobalKey _avatarKeyLogin = GlobalKey();

  final _codeController = TextEditingController();
  String _email = '';

  final _formKey = GlobalKey<FormState>();

  _VerifyEmailPageState(String email)  {
    _email = email;
  }

  @override
  Widget build(BuildContext context) {
    if (_email.isEmpty) {
      Future.microtask(() => context.pushReplacement('/login'));
    }
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
                  child: Form(
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
                          'Herzlichen Glückwunsch zu Ihrer erfolgreichen Registrierung. Prüfen Sie Ihre E-Mail ${_email}, die Sie bei der Registrierung angegeben haben. Sie erhalten einen sechsstelligen Code zur Bestätigung Ihrer E-Mail-Adresse.',
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
                                  String error = await authService.verifyEmail(
                                      _email.trim(),
                                      _codeController.text.trim());
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
                                Text('E-Mail-Verifizierungen'),
                                SizedBox(width: 8)
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Keine E-Mail? '),
                            InkWell(
                              onTap: () async {
                                final authService = context.read<AuthService>();
                                try {
                                  await authService.resendVerifyEmail(
                                      _email.trim());
                                } catch (e) {
                                  print('resend verification error: $e');
                                }
                              },
                              child: Text(
                                'Erneut senden',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
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
