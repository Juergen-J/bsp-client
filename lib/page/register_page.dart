import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/router.dart';
import '../service/auth_service.dart';
import 'component/app_bar_component.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey _avatarKeyRegister = GlobalKey();
  bool _emailExists = true;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  final _emailController = TextEditingController();
  //final _usernameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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
            contentWidth: contentWidth,
            avatarKey: _avatarKeyRegister,
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
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Registriere dich bei 3D...',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fülle die Felder aus, um dein Konto zu erstellen.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // E-Mail
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
                              _emailExists = false;
                            },
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte E-Mail eingeben';
                              } else if (_emailExists) {
                                return 'E-Mail existiert';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          /*
                          // Username
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte Username eingeben';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),*/

                          // Firstname
                          TextFormField(
                            controller: _firstnameController,
                            decoration: InputDecoration(
                              labelText: 'Vorname *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte Vorname eingeben';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Lastname
                          TextFormField(
                            controller: _lastnameController,
                            decoration: InputDecoration(
                              labelText: 'Nachname *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte Nachname eingeben';
                              }
                              return null;
                            },
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
                                    String error = await authService.signUp(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                      _firstnameController.text.trim(),
                                      _lastnameController.text.trim()
                                    );
                                    if (error.isNotEmpty) {
                                      _emailExists = true;
                                      _formKey.currentState!.validate();
                                    } else {
                                      context.go('/verify-email', extra: _emailController.text.trim());
                                    }

                                  } catch (e) {
                                    print('SignUp error: $e');
                                  }
                                  print('Register button pressed');
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('Registrieren'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_right_alt),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Bereits ein Konto? '),
                              InkWell(
                                onTap: () {
                                  Future.microtask(
                                          () => context.pushReplacement('/login'));
                                },
                                child: Text(
                                  'Einloggen',
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
          ),
        );
      },
    );
  }
}
