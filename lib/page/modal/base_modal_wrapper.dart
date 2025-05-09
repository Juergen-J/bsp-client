import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';

class BaseModalWrapper extends StatelessWidget {
  final Widget child;
  final bool isMobile;
  final double maxWidth;
  final VoidCallback? onClose;

  const BaseModalWrapper({
    super.key,
    required this.child,
    required this.isMobile,
    this.maxWidth = 600,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final modalWidth =
        isMobile ? MediaQuery.of(context).size.width * 0.9 : maxWidth;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              width: modalWidth,
              padding: appState.modalPadding,
              decoration: appState.modalDecoration,
/*
              width: modalWidth,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                // border: Border.all(
                //   color: Theme.of(context).colorScheme.primary,
                //   width: 1.5,
                // ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(212, 217, 233, 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),*/
              child: Stack(
                children: [
                  child,
                  if (onClose != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
