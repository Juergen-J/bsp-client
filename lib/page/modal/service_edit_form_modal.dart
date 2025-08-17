import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/user_service_full_dto.dart';
import '../../service/auth_service.dart';
import '../../widgets/device_image_carousel.dart';
import '../modal/base_modal_wrapper.dart';

class ServiceEditFormModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;
  final void Function(bool success)? onFinish;
  final String serviceId;
  final Completer<bool>? completer;

  const ServiceEditFormModal({
    super.key,
    required this.onClose,
    required this.isMobile,
    this.onFinish,
    required this.serviceId,
    this.completer,
  });

  @override
  State<ServiceEditFormModal> createState() => _ServiceEditFormModalState();
}

class _ServiceEditFormModalState extends State<ServiceEditFormModal> {
  final _formKey = GlobalKey<FormState>();

  UserServiceFullDto? service;
  List<XFile> pickedImages =
      []; // (зарезервировано — если захочешь добавить upload)
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchService();
  }

  Future<void> _fetchService() async {
    final dio = Provider.of<AuthService>(context, listen: false).dio;
    try {
      final response = await dio.get('/v1/service/${widget.serviceId}');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          service = UserServiceFullDto.fromJson(response.data);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load service");
      }
    } catch (e) {
      print('Error fetching service: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      maxWidth: 840,
      builder: (context) => isLoading
          ? const Center(child: CircularProgressIndicator())
          : service == null
              ? const Center(child: Text('Service not found'))
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final s = service!;
    final imageIds = s.attachments
        .where((a) => a.details is ImageAttachmentDto)
        .map((a) => (a.details as ImageAttachmentDto).normalId)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Service',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // --- Meta: IDs, Status, Type ---
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _infoChip('Service ID', s.id),
                  _infoChip('User ID', s.userId),
                  _infoChip('Status', s.status.name),
                  _infoChip('Category', s.serviceType.displayName),
                ],
              ),

              const SizedBox(height: 24),
              Divider(),

              // --- Name ---
              const SizedBox(height: 16),
              TextFormField(
                initialValue: s.name,
                decoration: const InputDecoration(labelText: 'Name'),
                enabled: false,            // ← только просмотр
              ),

              const SizedBox(height: 16),

              // --- Price (expanded) ---
              Text('Price', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: s.price.amount.toString(),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: s.price.currencyCode ?? 'EUR',
                      decoration:
                          const InputDecoration(labelText: 'Currency code'),
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: s.price.currencyName ?? 'Euro',
                      decoration:
                          const InputDecoration(labelText: 'Currency name'),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Negotiable'),
                      child: Row(
                        children: [
                          Icon(s.price.negotiable
                              ? Icons.check_circle
                              : Icons.cancel),
                          const SizedBox(width: 8),
                          Text(s.price.negotiable ? 'Yes' : 'No'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                initialValue: s.description,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                enabled: false,            // ← только просмотр
              ),

              const SizedBox(height: 24),
              Divider(),

              // --- Images ---
              const SizedBox(height: 12),
              Text('Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (imageIds.isNotEmpty)
                DeviceImageCarousel(imageIds: imageIds)
              else
                const Text("No images available."),

              const SizedBox(height: 24),
              Divider(),

              // --- Address ---
              const SizedBox(height: 12),
              Text('Address', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _readonlyField('Postcode', s.address.postcode?.toString()),
              _readonlyField('City', s.address.city),
              _readonlyField('Street/No.', s.address.street1),

              const SizedBox(height: 24),
              Divider(),

              // --- Devices ---
              const SizedBox(height: 12),
              Text('Linked devices',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (s.devices.isEmpty)
                const Text('No linked devices.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.devices
                      .map((d) => Chip(
                            label: Text(d.name),
                            avatar: const Icon(Icons.devices_other, size: 18),
                          ))
                      .toList(),
                ),

              const SizedBox(height: 24),
              Divider(),

// --- Attributes ---
              const SizedBox(height: 12),
              Text('Attributes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (s.attributes.isEmpty)
                const Text('No attributes.')
              else
                Column(
                  children: s.attributes.map((a) {
                    final title = _prettyLabel(a.property);
                    final val = (a.value.isNotEmpty) ? a.value : '—';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text(val),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 28),

              // --- Danger zone: Delete ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final dio =
                            Provider.of<AuthService>(context, listen: false)
                                .dio;
                        try {
                          await dio.delete('/v1/service/${s.id}');
                          if (widget.completer != null && !(widget.completer!.isCompleted)) {
                            widget.completer!.complete(true);
                          }

                          widget.onFinish?.call(true);
                          widget.onClose();
                        } catch (e) {
                          // ignore: avoid_print
                          print('Error deleting service: $e');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error deleting service: $e')),
                          );
                        }
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- helpers ---

  Widget _readonlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value ?? '',
        enabled: false,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _prettyLabel(String raw) {
    // snake_case → "Snake case", camelCase → "Camel case"
    final s1 = raw.replaceAll('_', ' ');
    final s2 = s1.replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (m) => ' ${m[1]}');
    final out = s2.trim();
    return out.isEmpty ? 'Attribute' : '${out[0].toUpperCase()}${out.substring(1)}';
  }

}
