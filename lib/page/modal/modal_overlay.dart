import 'dart:async';
import 'dart:ui';

import 'package:berlin_service_portal/page/modal/register_modal.dart';
import 'package:berlin_service_portal/page/modal/service_create_form_modal.dart';
import 'package:berlin_service_portal/page/modal/service_edit_form_modal.dart';
import 'package:berlin_service_portal/page/modal/verify_email_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/device/short_device_dto.dart';
import '../../service/document_service.dart';
import 'device_form_modal.dart';
import 'forgot_password_modal.dart';
import 'login_modal.dart';
import 'document_modal.dart';
import 'modal_service.dart';
import 'modal_type.dart';

class ModalOverlay extends StatelessWidget {
  const ModalOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final modalManager = Provider.of<ModalManager>(context);
    final stack = modalManager.stack;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (stack.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: stack.map<Widget>((entry) {
        return _ModalItem(
          key: ObjectKey(entry),
          entry: entry,
          isMobile: isMobile,
          onClose: modalManager.close,
        );
      }).toList(),
    );
  }
}

class _ModalItem extends StatelessWidget {
  final ModalEntry entry;
  final bool isMobile;
  final VoidCallback onClose;

  const _ModalItem({
    super.key,
    required this.entry,
    required this.isMobile,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content;

    switch (entry.type) {
      case ModalType.login:
        content = LoginModal(
          onClose: onClose,
          isMobile: isMobile,
        );
        break;
      case ModalType.register:
        content = RegisterModal(
          onClose: onClose,
          isMobile: isMobile,
        );
        break;
      case ModalType.forgotPassword:
        content = ForgotPasswordModal(onClose: onClose, isMobile: isMobile);
        break;
      case ModalType.verifyEmail:
        content = VerifyEmailModal(
          onClose: onClose,
          isMobile: isMobile,
          email: entry.data as String? ?? '',
        );
        break;
      case ModalType.deviceForm:
        final data = entry.data as Map?;
        content = DeviceFormModal(
          onClose: () {
            onClose();
            final completer = data?['completer'] as Completer?;
            completer?.complete(false);
          },
          isMobile: isMobile,
          editedDevice: data?['device'] as ShortDeviceDto?,
          readonly: data?['readonly'] == true,
          onFinish: (bool success) {
            onClose();
            final completer = data?['completer'] as Completer?;
            completer?.complete(success);
          },
        );
        break;
      case ModalType.serviceCreateForm:
        final data = entry.data as Map?;
        content = ServiceCreateFormModal(
          onClose: () {
            onClose();
            final completer = data?['completer'] as Completer?;
            completer?.complete(false);
          },
          isMobile: isMobile,
          onFinish: (bool success) {
            onClose();
            final completer = data?['completer'] as Completer?;
            completer?.complete(success);
          },
        );
        break;
      case ModalType.serviceEditForm:
        final data = entry.data as Map?;
        final serviceId = data?['serviceId'] as String? ?? '';
        final completer = data?['completer'] as Completer<bool>?;
        if (serviceId.isNotEmpty) {
          content = ServiceEditFormModal(
            onClose: () {
              onClose();
              if (completer != null && !completer.isCompleted) {
                completer.complete(false);
              }
            },
            isMobile: isMobile,
            serviceId: serviceId,
            onFinish: (bool success) {
              onClose();
              if (completer != null && !completer.isCompleted) {
                completer.complete(success);
              }
            },
          );
        } else {
          content = const Center(child: Text("Invalid service ID"));
        }
        break;
      case ModalType.document:
        final type = entry.data as StaticDocumentType?;
        if (type != null) {
          content = DocumentModal(
            documentType: type,
            onClose: onClose,
            isMobile: isMobile,
          );
        }
        break;
      default:
        content = null;
    }

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        Center(child: content),
      ],
    );
  }
}
