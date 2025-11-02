import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/address_dto.dart';
import '../../model/attachment/attachment_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/currency_dto.dart';
import '../../model/service/new_user_service_dto.dart';
import '../../model/service/price_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/user_service_full_dto.dart';
import '../../service/auth_service.dart';
import '../../service/image_service.dart';
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
  bool isLoading = true;
  bool _isSaving = false;

  final _descriptionCtrl = TextEditingController();
  final _priceAmountCtrl = TextEditingController();
  bool _negotiable = false;

  String _currencyCode = 'EUR';
  String _currencyName = 'Euro';
  List<CurrencyDto> _currencies = [];
  CurrencyDto? _selectedCurrency;
  bool _isLoadingCurrencies = false;

  final _postcodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _street1Ctrl = TextEditingController();
  final _street2Ctrl = TextEditingController();

  final List<TextEditingController> _attrPropCtrls = [];
  final List<TextEditingController> _attrValCtrls = [];

  final List<XFile> _newAttachments = [];
  final Set<String> _removeAttachmentIds = <String>{};
  String? _mainAttachmentRef;

  AddressDto? _addressSnapshot;
  List<String> _deviceIds = [];

  @override
  void initState() {
    super.initState();
    _fetchService();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _priceAmountCtrl.dispose();
    _postcodeCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _street1Ctrl.dispose();
    _street2Ctrl.dispose();
    for (final controller in _attrPropCtrls) {
      controller.dispose();
    }
    for (final controller in _attrValCtrls) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchService() async {
    final dio = Provider.of<AuthService>(context, listen: false).dio;
    try {
      final response = await dio.get('/v1/service/${widget.serviceId}');
      if (response.statusCode == 200 && response.data != null) {
        final fetched = UserServiceFullDto.fromJson(response.data);
        _rebuildAttributeControllers(fetched.attributes);
        setState(() {
          service = fetched;
          isLoading = false;
          _descriptionCtrl.text = fetched.description;
          _priceAmountCtrl.text = fetched.price.amount.toString();
          _currencyCode = fetched.price.currencyCode;
          _currencyName = fetched.price.currencyName;
          _negotiable = fetched.price.negotiable;
          _postcodeCtrl.text = fetched.address.postcode?.toString() ?? '';
          _cityCtrl.text = fetched.address.city ?? '';
          _stateCtrl.text = fetched.address.state ?? '';
          _street1Ctrl.text = fetched.address.street1 ?? '';
          _street2Ctrl.text = fetched.address.street2 ?? '';
          _addressSnapshot = AddressDto(
            street1: fetched.address.street1,
            street2: fetched.address.street2,
            city: fetched.address.city,
            state: fetched.address.state,
            postcode: fetched.address.postcode,
            longitude: fetched.address.longitude,
            latitude: fetched.address.latitude,
          );
          _deviceIds = fetched.devices.map((d) => d.id).toList();
          _mainAttachmentRef = _findInitialMainAttachment(fetched);
        });
        await _loadCurrencies();
      } else {
        throw Exception('Failed to load service');
      }
    } catch (e) {
      debugPrint('Error fetching service: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service: $e')),
      );
    }
  }

  Future<void> _loadCurrencies() async {
    if (!mounted) return;
    setState(() => _isLoadingCurrencies = true);
    try {
      final dio = Provider.of<AuthService>(context, listen: false).dio;
      final locale = Localizations.localeOf(context).toLanguageTag();
      final resp =
          await dio.get('/v1/currency', queryParameters: {'locale': locale});

      var list = <CurrencyDto>[];
      if (resp.statusCode == 200 && resp.data is List) {
        list = (resp.data as List).map((e) => CurrencyDto.fromJson(e)).toList();
      }

      if (list.isEmpty) {
        list = [CurrencyDto(code: 'EUR', name: 'Euro')];
      }

      final current = list.firstWhere(
        (c) => c.code == _currencyCode,
        orElse: () => list.first,
      );

      if (!mounted) return;
      setState(() {
        _currencies = list;
        _selectedCurrency = current;
        _currencyCode = current.code;
        _currencyName = current.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currencies = [CurrencyDto(code: 'EUR', name: 'Euro')];
        _selectedCurrency = _currencies.first;
        _currencyCode = _selectedCurrency!.code;
        _currencyName = _selectedCurrency!.name;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrencies = false);
      }
    }
  }

  void _rebuildAttributeControllers(List<ServiceAttributeDto> attrs) {
    for (final controller in _attrPropCtrls) {
      controller.dispose();
    }
    for (final controller in _attrValCtrls) {
      controller.dispose();
    }
    _attrPropCtrls
      ..clear()
      ..addAll(attrs.map((a) => TextEditingController(text: a.property)));
    _attrValCtrls
      ..clear()
      ..addAll(attrs.map((a) => TextEditingController(text: a.value)));
  }

  void _addAttributeRow({String property = '', String value = ''}) {
    setState(() {
      _attrPropCtrls.add(TextEditingController(text: property));
      _attrValCtrls.add(TextEditingController(text: value));
    });
  }

  void _removeAttributeRow(int index) {
    if (index < 0 || index >= _attrPropCtrls.length) return;
    final propCtrl = _attrPropCtrls.removeAt(index);
    final valCtrl = _attrValCtrls.removeAt(index);
    propCtrl.dispose();
    valCtrl.dispose();
    setState(() {});
  }

  List<ServiceAttributeDto> _collectAttributes() {
    final attributes = <ServiceAttributeDto>[];
    for (var i = 0; i < _attrPropCtrls.length; i++) {
      final property = _attrPropCtrls[i].text.trim();
      final value = _attrValCtrls[i].text.trim();
      if (property.isEmpty && value.isEmpty) continue;
      attributes.add(ServiceAttributeDto(property, value));
    }
    return attributes;
  }

  String? _computeMainAttachmentCandidate({String? preferred}) {
    final candidates = _availableAttachmentRefs();
    if (candidates.isEmpty) {
      return null;
    }
    if (preferred != null && candidates.contains(preferred)) {
      return preferred;
    }
    if (_mainAttachmentRef != null && candidates.contains(_mainAttachmentRef)) {
      return _mainAttachmentRef;
    }
    return candidates.first;
  }

  String? _findInitialMainAttachment(UserServiceFullDto s) {
    for (final attachment in s.attachments) {
      if (attachment.mainAttachment) {
        return attachment.id;
      }
    }
    return s.attachments.isNotEmpty ? s.attachments.first.id : null;
  }

  Set<String> _availableAttachmentRefs() {
    final refs = <String>{};
    if (service != null) {
      for (final attachment in service!.attachments) {
        if (!_removeAttachmentIds.contains(attachment.id)) {
          refs.add(attachment.id);
        }
      }
    }
    refs.addAll(_newAttachments.map((file) => file.name));
    return refs;
  }

  Future<void> _pickNewAttachment() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _newAttachments.add(image);
        _mainAttachmentRef =
            _computeMainAttachmentCandidate(preferred: image.name);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _removeNewAttachment(XFile file) {
    setState(() {
      _newAttachments.remove(file);
      _mainAttachmentRef = _computeMainAttachmentCandidate();
    });
  }

  void _toggleRemoveExistingAttachment(String attachmentId) {
    setState(() {
      if (_removeAttachmentIds.contains(attachmentId)) {
        _removeAttachmentIds.remove(attachmentId);
      } else {
        _removeAttachmentIds.add(attachmentId);
      }
      _mainAttachmentRef = _computeMainAttachmentCandidate();
    });
  }

  void _setMainAttachment(String candidate) {
    final allowed = _availableAttachmentRefs();
    if (!allowed.contains(candidate)) return;
    setState(() {
      _mainAttachmentRef = candidate;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || service == null || _isSaving) {
      return;
    }

    final currentService = service!;
    setState(() => _isSaving = true);

    try {
      final dio = Provider.of<AuthService>(context, listen: false).dio;

      final normalizedAmount =
          _priceAmountCtrl.text.trim().replaceAll(',', '.');
      final parsedAmount = num.tryParse(normalizedAmount);

      final priceDto = PriceDto(
        parsedAmount ?? currentService.price.amount,
        _currencyCode,
        _currencyName,
        _negotiable,
      );

      final address = AddressDto(
        street1:
            _street1Ctrl.text.trim().isEmpty ? null : _street1Ctrl.text.trim(),
        street2:
            _street2Ctrl.text.trim().isEmpty ? null : _street2Ctrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        postcode: int.tryParse(_postcodeCtrl.text.trim()),
        longitude: _addressSnapshot?.longitude,
        latitude: _addressSnapshot?.latitude,
      );

      final attributes = _collectAttributes();

      final dto = NewUserServiceDto(
        serviceTypeId: currentService.serviceType.id,
        name: currentService.name,
        description: _descriptionCtrl.text.trim(),
        mainAttachment: _mainAttachmentRef ?? '',
        devices: _deviceIds,
        price: priceDto,
        attributes: attributes,
        address: address,
      );

      final newFiles = <MultipartFile>[];
      for (final file in _newAttachments) {
        final bytes = await file.readAsBytes();
        newFiles.add(
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(dto.toJson()),
          filename: 'data.json',
          contentType: MediaType('application', 'json'),
        ),
      };

      if (newFiles.isNotEmpty) {
        formMap['new-attachments'] = newFiles;
      }
      if (_removeAttachmentIds.isNotEmpty) {
        formMap['remove-attachments'] = _removeAttachmentIds.toList();
      }

      final formData = FormData.fromMap(formMap);

      await dio.put('/v1/service/${currentService.id}', data: formData);

      widget.onFinish?.call(true);
      if (widget.completer != null && !widget.completer!.isCompleted) {
        widget.completer!.complete(true);
      }
      if (mounted) {
        widget.onClose();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data ?? e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalWrapper(
      isMobile: widget.isMobile,
      onClose: widget.onClose,
      maxWidth: 840,
      builder: (context) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (service == null) {
          return const Center(child: Text('Service not found'));
        }
        return _buildForm(context);
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final currentService = service!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit service', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              _buildReadOnlyField('Name', currentService.name),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildPriceSection(theme),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildAddressSection(theme),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildAttributesSection(theme),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildAttachmentsSection(context, currentService),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDeleteButton(context, currentService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      enabled: false,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceAmountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) {
                    return 'Amount is required';
                  }
                  final normalized = raw.replaceAll(',', '.');
                  if (num.tryParse(normalized) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<CurrencyDto>(
                value: _selectedCurrency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _currencies.map((c) {
                  final symbol =
                      NumberFormat.simpleCurrency(name: c.code).currencySymbol;
                  return DropdownMenuItem(
                    value: c,
                    child: Text('$symbol ${c.name} — ${c.code}'),
                  );
                }).toList(),
                selectedItemBuilder: (_) => _currencies.map((c) {
                  final symbol =
                      NumberFormat.simpleCurrency(name: c.code).currencySymbol;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(symbol),
                  );
                }).toList(),
                onChanged: _isLoadingCurrencies
                    ? null
                    : (currency) {
                        if (currency == null) return;
                        setState(() {
                          _selectedCurrency = currency;
                          _currencyCode = currency.code;
                          _currencyName = currency.name;
                        });
                      },
                validator: (value) {
                  if (_currencies.isEmpty) {
                    return null;
                  }
                  return value == null ? 'Select currency' : null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: _negotiable,
              onChanged: (value) => setState(() => _negotiable = value),
            ),
            const SizedBox(width: 8),
            const Text('Negotiable'),
            if (_isLoadingCurrencies) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Address', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _postcodeCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Postcode'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityCtrl,
          decoration: const InputDecoration(labelText: 'City'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _stateCtrl,
          decoration: const InputDecoration(labelText: 'State'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _street1Ctrl,
          decoration: const InputDecoration(labelText: 'Street / No.'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _street2Ctrl,
          decoration: const InputDecoration(labelText: 'Street line 2'),
        ),
      ],
    );
  }

  Widget _buildAttributesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attributes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_attrPropCtrls.isEmpty) const Text('No attributes.'),
        ...List.generate(_attrPropCtrls.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _attrPropCtrls[index],
                    decoration: const InputDecoration(labelText: 'Property'),
                    validator: (value) {
                      final prop = value?.trim() ?? '';
                      final val = _attrValCtrls[index].text.trim();
                      if (prop.isEmpty && val.isNotEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _attrValCtrls[index],
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeAttributeRow(index),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _addAttributeRow(),
            icon: const Icon(Icons.add),
            label: const Text('Add attribute'),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(
      BuildContext context, UserServiceFullDto currentService) {
    final theme = Theme.of(context);
    final imageService = Provider.of<ImageService>(context, listen: false);

    final existingTiles = currentService.attachments
        .map((attachment) =>
            _buildExistingAttachmentTile(context, attachment, imageService))
        .toList();

    final newTiles = _newAttachments
        .map((file) => _buildNewAttachmentTile(context, file))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (existingTiles.isEmpty && newTiles.isEmpty)
          const Text('No images attached.'),
        if (existingTiles.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: existingTiles,
          ),
        if (newTiles.isNotEmpty) ...[
          if (existingTiles.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: newTiles,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickNewAttachment,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add image'),
        ),
        if (_mainAttachmentRef != null) ...[
          const SizedBox(height: 8),
          Text(
            'Main image: $_mainAttachmentRef',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildExistingAttachmentTile(
    BuildContext context,
    AttachmentDto attachment,
    ImageService imageService,
  ) {
    final imageDetails = attachment.details;
    final imageId =
        imageDetails is ImageAttachmentDto ? imageDetails.normalId : null;
    final isRemoved = _removeAttachmentIds.contains(attachment.id);
    final isMain = _mainAttachmentRef == attachment.id;
    final borderColor =
        isMain ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: isMain ? 2 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageId == null
                ? const Icon(Icons.broken_image)
                : FutureBuilder<Widget>(
                    future: imageService.getImageWidget(
                      imageId,
                      fit: BoxFit.cover,
                      width: 110,
                      height: 110,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return snapshot.data!;
                      }
                      if (snapshot.hasError) {
                        return const Icon(Icons.broken_image);
                      }
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
          ),
          if (isRemoved)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _toggleRemoveExistingAttachment(attachment.id),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: isRemoved ? Colors.green : Colors.black54,
                child: Icon(
                  isRemoved ? Icons.restore : Icons.delete,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: isRemoved ? null : () => _setMainAttachment(attachment.id),
              child: Icon(
                Icons.star,
                color: isMain ? Colors.amber : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAttachmentTile(BuildContext context, XFile file) {
    final theme = Theme.of(context);
    final isMain = _mainAttachmentRef == file.name;

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMain ? theme.colorScheme.primary : Colors.grey.shade300,
          width: isMain ? 2 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              file.path,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewAttachment(file),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _setMainAttachment(file.name),
              child: Icon(
                Icons.star,
                color: isMain ? Colors.amber : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
      BuildContext context, UserServiceFullDto currentService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final dio = Provider.of<AuthService>(context, listen: false).dio;
              try {
                await dio.delete('/v1/service/${currentService.id}');
                if (widget.completer != null &&
                    !widget.completer!.isCompleted) {
                  widget.completer!.complete(true);
                }
                widget.onFinish?.call(true);
                widget.onClose();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting service: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ),
      ],
    );
  }
}
