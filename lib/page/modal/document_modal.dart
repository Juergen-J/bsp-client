import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/document_service.dart';
import 'base_modal_wrapper.dart';

class DocumentModal extends StatefulWidget {
  final StaticDocumentType documentType;
  final VoidCallback onClose;
  final bool isMobile;

  const DocumentModal({
    super.key,
    required this.documentType,
    required this.onClose,
    required this.isMobile,
  });

  @override
  State<DocumentModal> createState() => _DocumentModalState();
}

class _DocumentModalState extends State<DocumentModal> {
  late Future<Uint8List> _documentFuture;
  String? _viewType;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _documentFuture = context
        .read<DocumentService>()
        .fetchDocumentBytes(widget.documentType);
  }

  @override
  void dispose() {
    if (_pdfUrl != null) {
      html.Url.revokeObjectUrl(_pdfUrl!);
    }
    super.dispose();
  }

  void _registerView(Uint8List bytes) {
    if (_viewType != null) return;

    final blob = html.Blob([bytes], 'application/pdf');
    _pdfUrl = html.Url.createObjectUrlFromBlob(blob);
    _viewType = 'pdf-view-${widget.documentType.value}-${DateTime.now().millisecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType!, (int viewId) {
      return html.IFrameElement()
        ..src = _pdfUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalWrapper(
      onClose: widget.onClose,
      isMobile: widget.isMobile,
      maxWidth: 1000,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getTitle(widget.documentType),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: FutureBuilder<Uint8List>(
                future: _documentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading document: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    _registerView(snapshot.data!);
                    return HtmlElementView(viewType: _viewType!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getTitle(StaticDocumentType type) {
    switch (type) {
      case StaticDocumentType.impressum:
        return 'Impressum';
      case StaticDocumentType.privacyPolicy:
        return 'Datenschutzerklärung';
      case StaticDocumentType.termsAndConditions:
        return 'AGB';
    }
  }
}
