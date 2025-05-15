import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../service/auth_service.dart';
import 'base_modal_wrapper.dart';
import 'modal_style_provider.dart';

class ForgotPasswordModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const ForgotPasswordModal({
    super.key,
    required this.onClose,
    required this.isMobile,
  });

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _incorrectCode = false;
  bool _incorrectEmail = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _showCodePart = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      builder: (context) => Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Passwort vergessen?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _showCodePart
                    ? 'Gib den Code aus der E-Mail ein und erstelle ein neues Passwort.'
                    : 'Gib deine E-Mail ein, um den Wiederherstellungscode zu erhalten.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!_showCodePart)
                _buildEmailStep(colorScheme)
              else
                _buildResetStep(colorScheme),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(ColorScheme colorScheme) {
    return Column(
      children: [
        InputModalField(
          controller: _emailController,
          label: 'E-Mail *',
          icon: Icons.email_outlined,
          obscureText: false,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Bitte E-Mail eingeben';
            if (_incorrectEmail) return 'E-Mail existiert nicht';
            return null;
          },
          onChanged: (_) => _incorrectEmail = false,
        ),
        const SizedBox(height: 24),
        _buildButton(
          label: 'Code anfordern',
          colorScheme: colorScheme,
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final auth = context.read<AuthService>();
              final error = await auth.sendPasswordRecoveryCode(
                _emailController.text.trim(),
              );
              if (error.isEmpty) {
                setState(() {
                  _showCodePart = true;
                  _incorrectEmail = false;
                });
              } else {
                setState(() => _incorrectEmail = true);
                _formKey.currentState!.validate();
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildResetStep(ColorScheme colorScheme) {
    return Column(
      children: [
        Pinput(
          controller: _codeController,
          length: 6,
          autofocus: true,
          onChanged: (_) => _incorrectCode = false,
          validator: (value) {
            if ((value?.length ?? 0) < 6 || _incorrectCode) {
              return 'Falscher Code';
            }
            return null;
          },
          defaultPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: Theme.of(context).textTheme.headlineMedium,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: Theme.of(context).textTheme.headlineMedium,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          submittedPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: Theme.of(context).textTheme.headlineMedium,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Passwort
        InputModalField(
          controller: _passwordController,
          label: 'Neues Passwort *',
          obscureText: _obscurePassword,
          toggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),

        // Bestätigen
        InputModalField(
          controller: _confirmPasswordController,
          label: 'Passwort bestätigen *',
          obscureText: _obscurePasswordConfirm,
          toggleObscure: () => setState(
              () => _obscurePasswordConfirm = !_obscurePasswordConfirm),
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

        _buildButton(
          label: 'Passwort zurücksetzen',
          colorScheme: colorScheme,
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final auth = context.read<AuthService>();
              final error = await auth.recoverPassword(
                _emailController.text.trim(),
                _codeController.text.trim(),
                _passwordController.text,
              );
              if (error.isEmpty) {
                widget.onClose();
              } else {
                setState(() => _incorrectCode = true);
                _formKey.currentState!.validate();
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
        ),
        validator: validator ??
            (value) =>
                value == null || value.isEmpty ? 'Bitte $label eingeben' : null,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
