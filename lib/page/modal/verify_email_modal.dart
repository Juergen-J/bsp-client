import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../service/auth_service.dart';
import 'base_modal_wrapper.dart';

class VerifyEmailModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;
  final String email;

  const VerifyEmailModal({
    super.key,
    required this.onClose,
    required this.isMobile,
    required this.email,
  });

  @override
  State<VerifyEmailModal> createState() => _VerifyEmailModalState();
}

class _VerifyEmailModalState extends State<VerifyEmailModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _incorrectCode = false;

  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;

    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      builder: (context) => Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('E-Mail bestätigen',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Wir haben dir eine E-Mail mit einem Bestätigungscode an ${widget.email} gesendet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Pinput(
              controller: _codeController,
              length: 6,
              autofocus: true,
              onChanged: (_) => _incorrectCode = false,
              validator: (value) {
                if ((value?.length ?? 0) < 6 || _incorrectCode) {
                  return 'Code ist ungültig';
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
                  border: Border.all(color: colorScheme.primary, width: 2),
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
                  if (_formKey.currentState!.validate()) {
                    final auth = context.read<AuthService>();
                    final error = await auth.verifyEmail(
                      widget.email.trim(),
                      _codeController.text.trim(),
                    );
                    if (error.isNotEmpty) {
                      setState(() => _incorrectCode = true);
                      _formKey.currentState!.validate();
                    } else {
                      widget.onClose();
                    }
                  }
                },
                child: const Text('E-Mail bestätigen'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Keine E-Mail erhalten? ', style: Theme.of(context).textTheme.labelSmall),
                GestureDetector(
                  onTap: () async {
                    final auth = context.read<AuthService>();
                    await auth.resendVerifyEmail(widget.email.trim());
                  },
                  child: Text(
                    'Erneut senden',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
