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

  const ServiceEditFormModal({
    super.key,
    required this.onClose,
    required this.isMobile,
    this.onFinish,
    required this.serviceId,
  });

  @override
  State<ServiceEditFormModal> createState() => _ServiceEditFormModalState();
}

class _ServiceEditFormModalState extends State<ServiceEditFormModal> {
  final _formKey = GlobalKey<FormState>();

  UserServiceFullDto? service;
  List<XFile> pickedImages = [];
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error fetching service: $e')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      maxWidth: 800,
      builder: (context) => isLoading
          ? const Center(child: CircularProgressIndicator())
          : service == null
              ? const Center(child: Text('Service not found'))
              : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final s = service!;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Service',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: s.name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: s.price != 0 ? s.price.toString() : '',
                decoration: const InputDecoration(labelText: 'Price (€)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: s.description,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 24),
              Text('Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (s.attachments.isNotEmpty)
                DeviceImageCarousel(
                  imageIds: s.attachments
                      .where((a) => a.details is ImageAttachmentDto)
                      .map((a) => (a.details as ImageAttachmentDto).normalId)
                      .toList(),
                )
              else
                const Text("No images available."),
              const SizedBox(height: 24),
              Text('Address', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildAddressField('Postcode', s.address.postcode?.toString()),
              _buildAddressField('City', s.address.city),
              _buildAddressField('Street/No.', s.address.street1),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final dio =
                      Provider.of<AuthService>(context, listen: false).dio;
                  try {
                    await dio.delete('/v1/service/${s.id}');
                    widget.onFinish?.call(true);
                    widget.onClose();
                  } catch (e) {
                    print('Error deleting service: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting service: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(String label, String? value) {
    return TextFormField(
      initialValue: value ?? '',
      enabled: false,
      decoration: InputDecoration(labelText: label),
    );
  }
}
