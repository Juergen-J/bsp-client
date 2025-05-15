import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import 'modal_style_provider.dart';

class BaseModalWrapper extends StatelessWidget {
  final WidgetBuilder builder;
  final bool isMobile;
  final double maxWidth;
  final VoidCallback? onClose;

  const BaseModalWrapper({
    super.key,
    required this.builder,
    required this.isMobile,
    this.maxWidth = 600,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final modalWidth =
        isMobile ? MediaQuery.of(context).size.width * 0.9 : maxWidth;

    return ModalStyleProvider(
      style: ModalStyle(inputFieldDecoration: inputFieldDecoration),
      child: Builder(
        builder: (context) => Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  width: modalWidth,
                  padding: appState.modalPadding,
                  decoration: appState.modalDecoration,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      builder(context),
                      if (onClose != null)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Material(
                            type: MaterialType.transparency,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: onClose,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InputModalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final VoidCallback? toggleObscure;
  final FormFieldValidator<String>? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const InputModalField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
    this.icon,
    this.toggleObscure,
    this.validator,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputDecoration = ModalStyleProvider.of(context).inputFieldDecoration;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 60.0,
        decoration: inputDecoration.copyWith(
          color: inputDecoration.color,
          borderRadius: inputDecoration.borderRadius,
          boxShadow: inputDecoration.boxShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator ??
                (value) =>
                    value == null || value.isEmpty ? '$label eingeben' : null,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              labelText: label,
              labelStyle: TextStyle(color: colorScheme.onSurface),
              prefixIcon: toggleObscure == null && icon != null
                  ? Icon(icon, color: colorScheme.onSurface)
                  : null,
              suffixIcon: toggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: toggleObscure,
                    )
                  : null,
              errorStyle: const TextStyle(height: 1.2, color: Colors.red),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ),
    );
  }
}
