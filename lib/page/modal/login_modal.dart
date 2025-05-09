import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_state.dart';
import '../../service/auth_service.dart';
import 'base_modal_wrapper.dart';
import 'modal_service.dart';
import 'modal_style_provider.dart';
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
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _incorrectCredentials = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      builder: (context) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Einloggen',
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Logge dich ein, um gebrauchte Schätze zu finden\nund zu verkaufen.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            InputModalField(
              controller: _emailController,
              label: 'E-Mail',
              icon: Icons.email_outlined,
              obscureText: false,
            ),
            const SizedBox(height: 16),
            InputModalField(
              controller: _passwordController,
              label: 'Passwort',
              icon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
              obscureText: _obscurePassword,
              toggleObscure: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
              focusNode: _passwordFocusNode,
            ),
            const SizedBox(height: 12),
            if (_incorrectCredentials)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Falscher Login oder Passwort',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Noch kein Account? Erstelle ',
                    style: textTheme.labelSmall),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      widget.onClose();
                      context.read<ModalManager>().show(ModalType.register);
                    },
                    child: Text(
                      'hier',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Text(' dein Konto.', style: textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
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
                child: const Text(
                  'Einloggen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    widget.onClose();
                    context.read<ModalManager>().show(ModalType.forgotPassword);
                  },
                  child: Text(
                    'Passwort vergessen?',
                    style: textTheme.labelSmall?.copyWith(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
