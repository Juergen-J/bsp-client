import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/auth_service.dart';
import 'base_modal_wrapper.dart';
import 'modal_service.dart';
import 'modal_type.dart';

class RegisterModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const RegisterModal({
    super.key,
    required this.onClose,
    required this.isMobile,
  });

  @override
  State<RegisterModal> createState() => _RegisterModalState();
}

class _RegisterModalState extends State<RegisterModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _emailExists = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      builder: (context) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Registriere dich bei 3D',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Fülle die Felder aus, um dein Konto zu erstellen.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              InputModalField(
                controller: _emailController,
                label: 'E-Mail',
                icon: Icons.email_outlined,
                obscureText: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte E-Mail eingeben';
                  } else if (_emailExists) {
                    return 'E-Mail existiert';
                  }
                  return null;
                },
                onChanged: (_) => _emailExists = false,
              ),
              const SizedBox(height: 12),
              InputModalField(
                controller: _firstnameController,
                label: 'Vorname',
                obscureText: false,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Bitte Vorname eingeben' : null,
              ),
              const SizedBox(height: 12),
              InputModalField(
                controller: _lastnameController,
                label: 'Nachname',
                obscureText: false,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Bitte Nachname eingeben' : null,
              ),
              const SizedBox(height: 12),
              InputModalField(
                controller: _passwordController,
                label: 'Passwort',
                obscureText: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 12),
              InputModalField(
                controller: _confirmPasswordController,
                label: 'Passwort bestätigen',
                obscureText: _obscurePasswordConfirm,
                toggleObscure: () => setState(() {
                  _obscurePasswordConfirm = !_obscurePasswordConfirm;
                }),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      final authService = context.read<AuthService>();
                      final error = await authService.signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _firstnameController.text.trim(),
                        _lastnameController.text.trim(),
                      );

                      if (error.isNotEmpty) {
                        setState(() {
                          _emailExists = true;
                          _formKey.currentState!.validate();
                        });
                      } else {
                        widget.onClose();
                        context.read<ModalManager>().show(ModalType.verifyEmail,
                            data: _emailController.text.trim());
                      }
                    }
                  },
                  child: const Text('Registrieren',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bereits ein Konto? ',
                      style: Theme.of(context).textTheme.labelSmall),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        widget.onClose();
                        context.read<ModalManager>().show(ModalType.login);
                      },
                      child: Text(
                        'Einloggen',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
