import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_modal.dart';
import 'modal_service.dart';
import 'modal_type.dart';

class ModalOverlay extends StatelessWidget {
  const ModalOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final modalManager = Provider.of<ModalManager>(context);
    final modalType = modalManager.currentModal;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget? content;
    switch (modalType) {
      case ModalType.login:
        content = LoginModal(
          onClose: modalManager.close,
          isMobile: isMobile,
        );
        break;
      // case ModalType.register:
      //   content = RegisterModal(onClose: modalManager.close);
      //   break;
      // case ModalType.forgotPassword:
      //   content = ForgotPasswordModal(onClose: modalManager.close);
      //   break;
      // case ModalType.verifyEmail:
      //   content = VerifyEmailModal(onClose: modalManager.close);
      //   break;
      default:
        content = null;
    }

    return IgnorePointer(
      ignoring: modalType == null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: modalType == null
            ? const SizedBox.shrink()
            : Stack(
                key: ValueKey(modalType), // для смены между окнами
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  Center(child: content),
                ],
              ),
      ),
    );
  }
}
