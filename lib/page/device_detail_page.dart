import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/device/short_device_dto.dart';
import '../service/auth_service.dart';
import '../widgets/cards/device_full_detail_card.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  final ShortDeviceDto? initialDevice;

  const DeviceDetailPage({
    super.key,
    required this.deviceId,
    this.initialDevice,
  });

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  ShortDeviceDto? _device;
  bool _loading = false;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _device = widget.initialDevice;
    _loadDevice();
  }

  @override
  void didUpdateWidget(covariant DeviceDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      _device = widget.initialDevice;
      _loadDevice();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  Future<void> _loadDevice() async {
    _cancelToken?.cancel('new-request');
    final token = CancelToken();
    _cancelToken = token;

    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = context.read<AuthService>().dio;

    try {
      final response = await dio.get(
        '/v1/device/${widget.deviceId}',
        cancelToken: token,
      );
      if (!mounted || _cancelToken != token) return;

      if (response.data is Map<String, dynamic>) {
        setState(() {
          _device = ShortDeviceDto.fromJson(
            response.data as Map<String, dynamic>,
          );
          _loading = false;
        });
      } else {
        throw Exception('Unexpected payload');
      }
    } on DioException catch (e) {
      if (!mounted || _cancelToken != token) return;
      setState(() {
        _loading = false;
        _error = _describeError(e);
      });
    } catch (e) {
      if (!mounted || _cancelToken != token) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load device: $e';
      });
    } finally {
      if (_cancelToken == token) {
        _cancelToken = null;
      }
    }
  }

  String _describeError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'Failed to load device details.';
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _device == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _device == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(onPressed: _handleBack, child: const Text('Back')),
              ElevatedButton(
                onPressed: _loadDevice,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    }

    if (_device == null) {
      return const SizedBox.shrink();
    }

    return DeviceFullDetailCard(
      device: _device!,
      loading: _loading,
      onBack: _handleBack,
      onRefresh: _loadDevice,
    );
  }
}
