import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/auth_service.dart';
import 'base_modal_wrapper.dart';
import 'modal_service.dart';
import 'modal_type.dart';

class LoginModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;

  const LoginModal({super.key, required this.onClose, required this.isMobile});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _incorrectCredentials = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Einloggen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const Text(
              'Logge dich ein, um gebrauchte Schätze zu finden und zu verkaufen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _emailController,
              label: 'E-Mail',
              icon: Icons.email,
              obscureText: false,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _passwordController,
              label: 'Passwort',
              icon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
              obscureText: _obscurePassword,
              toggleObscure: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
            ),
            const SizedBox(height: 16),
            if (_incorrectCredentials)
              Text(
                'Falscher Login oder Passwort',
                style: TextStyle(color: colorScheme.error),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Noch kein Account? '),
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                    context.read<ModalManager>().show(ModalType.register);
                  },
                  child: Text(
                    'Erstelle hier dein Konto.',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                  setState(() => _incorrectCredentials = false);
                  if (_formKey.currentState!.validate()) {
                    final auth = context.read<AuthService>();
                    final error = await auth.login(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                    if (error.isEmpty) {
                      widget.onClose();
                    } else if (error == 'unverified_mail') {
                      if (error == 'unverified_mail') {
                        context.read<ModalManager>().show(ModalType.verifyEmail,
                            data: _emailController.text.trim());
                      }
                    } else {
                      setState(() => _incorrectCredentials = true);
                    }
                  }
                },
                child: const Text('Einloggen'),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                widget.onClose();
                context.read<ModalManager>().show(ModalType.forgotPassword);
              },
              child: const Text(
                'Passwort vergessen?',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    VoidCallback? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: (value) =>
            value == null || value.isEmpty ? '$label eingeben' : null,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          suffixIcon: toggleObscure != null
              ? IconButton(icon: Icon(icon), onPressed: toggleObscure)
              : Icon(icon),
        ),
      ),
    );
  }
}
