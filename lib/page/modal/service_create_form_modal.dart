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
import '../../model/service/price_dto.dart'; // ← NEW
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

  // --- PRICE (PriceDto) ---
  String priceAmount = ''; // хранится как строка для точности
  String currencyCode = 'EUR';
  String currencyName = 'Euro';
  bool negotiable = false;

  AddressDto address = AddressDto();
  List<ServiceAttributeDto> attributes = []; // UI-хук оставлен ниже (TODO)
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
                Text('Add Service',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),

                // NAME
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  onChanged: (v) => name = v,
                ),
                const SizedBox(height: 16),

                // CATEGORY
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
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                const SizedBox(height: 16),

                // --- PRICE (PriceDto fields) ---
                Text('Price', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: priceAmount,
                  decoration:
                      const InputDecoration(labelText: 'Amount (e.g. 12.34)'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    final normalized = v.replaceAll(',', '.');
                    final ok =
                        RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized);
                    return ok ? null : 'Invalid amount format';
                  },
                  onChanged: (v) => priceAmount = v,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: currencyCode,
                        decoration:
                            const InputDecoration(labelText: 'Currency code'),
                        onChanged: (v) => currencyCode = v.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: currencyName,
                        decoration:
                            const InputDecoration(labelText: 'Currency name'),
                        onChanged: (v) => currencyName = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: negotiable,
                  onChanged: (v) => setState(() => negotiable = v ?? false),
                  title: const Text('Negotiable'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),

                // DESCRIPTION
                TextFormField(
                  initialValue: description,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter description'
                      : null,
                  onChanged: (v) => description = v,
                ),
                const SizedBox(height: 24),

                // IMAGES
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ImageUploadWidget(
                  onFilesPicked: (files) =>
                      setState(() => pickedImages = files),
                  initialFiles: pickedImages,
                ),
                const SizedBox(height: 24),

                // ADDRESS
                Text('Address', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildAddressField('Postcode', address.postcode?.toString(),
                    (v) => address.postcode = int.tryParse(v)),
                _buildAddressField(
                    'City', address.city, (v) => address.city = v),
                _buildAddressField(
                    'Street/No.', address.street1, (v) => address.street1 = v),
                const SizedBox(height: 24),

                // DEVICES
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
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],

                const SizedBox(height: 24),

                // ATTRIBUTES (hook / optional UI)
                // TODO: добавь свой редактор атрибутов, если нужно.
                // Сейчас отправится пустой список attributes.

                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final dio =
                        Provider.of<AuthService>(context, listen: false).dio;

                    // Подготовим mainAttachment как имя первого файла (если нужно — замени на id после загрузки)
                    final mainAttachmentName =
                        pickedImages.isNotEmpty ? pickedImages.first.name : '';

                    // Нормализуем amount (замена запятой на точку)
                    final normalizedAmount = priceAmount.replaceAll(',', '.');
                    final amountNum = num.parse(normalizedAmount);

                    // Собираем PriceDto
                    final priceDto = PriceDto(
                      amountNum, // amount: String
                      currencyCode,
                      currencyName,
                      negotiable,
                    );

                    final newService = NewUserServiceDto(
                      serviceTypeId: selectedType!.id,
                      name: name,
                      description: description,
                      mainAttachment: mainAttachmentName,
                      devices: selectedDeviceIds,
                      price: priceDto,
                      attributes: attributes,
                      address: address,
                    );

                    // Файлы-вложения
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
                      // ignore: avoid_print
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
