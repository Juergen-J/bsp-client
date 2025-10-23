import 'package:berlin_service_portal/widgets/cards/service_full_detail_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/service/user_service_full_dto.dart';
import '../../service/auth_service.dart';

class ServiceFullDetailDialog extends StatefulWidget {
  final String serviceId;
  final VoidCallback? onClose;
  final VoidCallback? onMessage;
  final String? priceUnit;

  const ServiceFullDetailDialog({
    super.key,
    required this.serviceId,
    this.onClose,
    this.onMessage,
    this.priceUnit,
  });

  @override
  State<ServiceFullDetailDialog> createState() =>
      _ServiceFullDetailDialogState();
}

class _ServiceFullDetailDialogState extends State<ServiceFullDetailDialog> {
  CancelToken? _cancelToken;
  UserServiceFullDto? _full;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  Future<void> _load() async {
    _cancelToken?.cancel('new-request');
    _cancelToken = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = Provider.of<AuthService>(context, listen: false).dio;

    try {
      final resp = await dio.get(
        '/v1/service/${widget.serviceId}',
        cancelToken: _cancelToken,
      );
      if (resp.statusCode == 200 && resp.data != null) {
        setState(() {
          _full =
              UserServiceFullDto.fromJson(resp.data as Map<String, dynamic>);
          _loading = false;
        });
      } else {
        throw Exception('Bad response: ${resp.statusCode}');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      setState(() {
        _loading = false;
        _error = 'Network error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load service: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Stack(
        children: [
          if (_full != null)
            ServiceFullDetailCard(
              full: _full!,
              priceUnit: widget.priceUnit,
              onClose: widget.onClose,
              onMessage: widget.onMessage,
            )
          else
            // скелетон/лоадер до прихода данных
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Loading service…'),
                  SizedBox(height: 16),
                ],
              ),
            ),
          if (_loading)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ErrorBar(message: _error!, onRetry: _load),
            ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBar({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: TextStyle(color: cs.onErrorContainer))),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
