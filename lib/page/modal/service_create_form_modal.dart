import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http_parser/http_parser.dart';

import '../../model/address_dto.dart';
import '../../model/device/short_device_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/short_service_type_dto.dart';
import '../../model/service/new_user_service_dto.dart';
import '../../service/auth_service.dart';
import '../../widgets/image_upload_widget.dart';
import '../modal/base_modal_wrapper.dart';

class ServiceCreateFormModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;
  final void Function(bool success)? onFinish;

  const ServiceCreateFormModal({
    super.key,
    required this.onClose,
    required this.isMobile,
    this.onFinish,
  });

  @override
  State<ServiceCreateFormModal> createState() => _ServiceCreateFormModalState();
}

class _ServiceCreateFormModalState extends State<ServiceCreateFormModal> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  double price = 0;
  AddressDto address = AddressDto();
  List<ServiceAttributeDto> attributes = [];
  List<ShortServiceTypeDto> serviceTypes = [];
  ShortServiceTypeDto? selectedType;

  List<ShortDeviceDto> myDevices = [];
  List<String> selectedDeviceIds = [];
  List<XFile> pickedImages = [];

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
    _loadMyDevices();
  }

  Future<void> _loadServiceTypes() async {
    final dio = Provider.of<AuthService>(context, listen: false).dio;
    final response = await dio.get('/v1/service-type');
    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        serviceTypes = (response.data['content'] as List)
            .map((e) => ShortServiceTypeDto.fromJson(e))
            .toList();
        if (selectedType == null && serviceTypes.isNotEmpty) {
          selectedType = serviceTypes.first;
        }
      });
    }
  }

  Future<void> _loadMyDevices() async {
    final dio = Provider.of<AuthService>(context, listen: false).dio;
    final response = await dio.get('/v1/device/my');
    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        myDevices = (response.data['content'] as List)
            .map((e) => ShortDeviceDto.fromJson(e))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      maxWidth: 800,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Service',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ShortServiceTypeDto>(
                  value: selectedType,
                  items: serviceTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedType = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: price != 0 ? price.toString() : '',
                  decoration: const InputDecoration(labelText: 'Price (€)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => price = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (v) => description = v,
                ),
                const SizedBox(height: 24),
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ImageUploadWidget(
                  onFilesPicked: (files) =>
                      setState(() => pickedImages = files),
                  initialFiles: pickedImages,
                ),
                const SizedBox(height: 24),
                Text('Address', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildAddressField('Postcode', address.postcode?.toString(),
                    (v) => address.postcode = int.tryParse(v)),
                _buildAddressField(
                    'City', address.city, (v) => address.city = v),
                _buildAddressField(
                    'Street/No.', address.street1, (v) => address.street1 = v),
                const SizedBox(height: 24),
                if (myDevices.isNotEmpty) ...[
                  Text('Linked devices (optional)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...myDevices.map((device) {
                    final isSelected = selectedDeviceIds.contains(device.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedDeviceIds.add(device.id);
                          } else {
                            selectedDeviceIds.remove(device.id);
                          }
                        });
                      },
                      title: Text(device.name),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final dio =
                        Provider.of<AuthService>(context, listen: false).dio;

                    final newService = NewUserServiceDto(
                      serviceTypeId: selectedType!.id,
                      name: name,
                      description: description,
                      mainAttachment: pickedImages.isNotEmpty
                          ? pickedImages.first.name
                          : '',
                      devices: selectedDeviceIds,
                      price: price,
                      attributes: attributes,
                      address: address,
                    );

                    final attachments = <MultipartFile>[];

                    for (final file in pickedImages) {
                      final bytes = await file.readAsBytes();
                      attachments.add(
                        MultipartFile.fromBytes(
                          bytes,
                          filename: file.name,
                          contentType: MediaType('image', 'jpeg'),
                        ),
                      );
                    }

                    final formData = FormData.fromMap({
                      "data": MultipartFile.fromString(
                        jsonEncode(newService.toJson()),
                        filename: "data.json",
                        contentType: MediaType("application", "json"),
                      ),
                      "attachments": attachments,
                    });

                    try {
                      await dio.post('/v1/service/my', data: formData);
                      widget.onFinish?.call(true);
                      widget.onClose();
                    } catch (e) {
                      print('Error creating service: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating service: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(
      String label, String? initial, void Function(String) onChanged) {
    return TextFormField(
      initialValue: initial ?? '',
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}
