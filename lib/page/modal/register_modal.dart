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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Registriere dich bei 3D',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Fülle die Felder aus, um dein Konto zu erstellen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'E-Mail',
                controller: _emailController,
                icon: Icons.email,
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
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Vorname',
                controller: _firstnameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Bitte Vorname eingeben' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nachname',
                controller: _lastnameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Bitte Nachname eingeben' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Passwort',
                controller: _passwordController,
                obscureText: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Passwort bestätigen',
                controller: _confirmPasswordController,
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
              const SizedBox(height: 24),
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
                        context
                            .read<ModalManager>()
                            .show(ModalType.verifyEmail, data: _emailController.text.trim());
                      }
                    }
                  },
                  child: const Text('Registrieren'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bereits ein Konto? '),
                  GestureDetector(
                    onTap: () {
                      widget.onClose();
                      context.read<ModalManager>().show(ModalType.login);
                    },
                    child: Text(
                      'Einloggen',
                      style: TextStyle(
                        color: colorScheme.primary,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    FormFieldValidator<String>? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          labelText: label,
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleObscure,
                )
              : icon != null
                  ? Icon(icon)
                  : null,
        ),
      ),
    );
  }
}
