import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/address_dto.dart';
import '../../model/device/short_device_dto.dart';
import '../../model/postal_suggestion_dto.dart';
import '../../model/service/currency_dto.dart';
import '../../model/service/new_user_service_dto.dart';
import '../../model/service/price_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/short_service_type_dto.dart';
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

  // Price (PriceDto)
  String priceAmount = '';
  String currencyCode = 'EUR';
  String currencyName = 'Euro';
  bool negotiable = false;

  // Currency
  List<CurrencyDto> currencies = [];
  CurrencyDto? selectedCurrency;
  bool _isLoadingCurrencies = false;

  // Address
  AddressDto address = AddressDto();
  List<ShortServiceTypeDto> serviceTypes = [];
  ShortServiceTypeDto? selectedType;

  List<ShortDeviceDto> myDevices = [];
  List<String> selectedDeviceIds = [];
  List<XFile> pickedImages = [];

  // Attribute editors
  final List<TextEditingController> _attrPropCtrls = [];
  final List<TextEditingController> _attrValCtrls = [];

  // Address controllers
  final _postcodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _street1Ctrl = TextEditingController();

  final _postcodeFocus = FocusNode();
  final _street1Focus = FocusNode();

  final _zipTargetKey = GlobalKey();

  Size get _zipTargetSize {
    final ctx = _zipTargetKey.currentContext;
    if (ctx == null) return const Size(420, 0);
    final box = ctx.findRenderObject() as RenderBox;
    return box.size;
  }

  double get _zipTargetHeight => _zipTargetSize.height;

  double get _zipTargetWidth => _zipTargetSize.width;

  // ZIP suggestions
  final LayerLink _zipFieldLink = LayerLink();
  OverlayEntry? _zipOverlay;
  List<PostalSuggestionDto> _zipSuggestions = [];
  bool _isLoadingZip = false;
  Timer? _zipDebounce;
  bool _zipOverlayVisible = false;
  bool _suppressZipListener = false;
  String? _lastAppliedZip;

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
    _loadMyDevices();

    _postcodeCtrl.text = address.postcode?.toString() ?? '';
    _cityCtrl.text = address.city ?? '';
    _stateCtrl.text = address.state ?? '';

    _postcodeCtrl.addListener(_onZipChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrencies());
  }

  @override
  void dispose() {
    _postcodeCtrl.removeListener(_onZipChanged);
    _zipDebounce?.cancel();

    _removeOverlayNow();

    for (final c in _attrPropCtrls) c.dispose();
    for (final c in _attrValCtrls) c.dispose();

    _postcodeCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _street1Ctrl.dispose();

    _postcodeFocus.dispose();
    _street1Focus.dispose();

    super.dispose();
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

  Future<void> _fetchZipSuggestions(String zip) async {
    try {
      setState(() => _isLoadingZip = true);
      final dio = Provider.of<AuthService>(context, listen: false).dio;
      final resp = await dio
          .get('/v1/postal-codes/suggest', queryParameters: {'zip': zip});

      List<PostalSuggestionDto> list = [];
      if (resp.statusCode == 200 && resp.data is List) {
        list = (resp.data as List)
            .map((e) => PostalSuggestionDto.fromJson(e))
            .toList();
      }

      _zipSuggestions = list;

      if (_zipSuggestions.length == 1 &&
          (_zipSuggestions.first.postcode ?? '').trim() == zip.trim()) {
        print("call _fetchZipSuggestions");
        _applyZipSuggestion(_zipSuggestions.first);
        _hideZipOverlay();
        return;
      }

      if (_zipSuggestions.isNotEmpty) {
        if (_zipOverlay == null) {
          _showZipOverlay();
        } else {
          _zipOverlay!.markNeedsBuild();
        }
      } else {
        _hideZipOverlay();
      }
    } catch (_) {
      _zipSuggestions = [];
      _hideZipOverlay();
    } finally {
      if (mounted) setState(() => _isLoadingZip = false);
    }
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isLoadingCurrencies = true);
    try {
      final dio = Provider.of<AuthService>(context, listen: false).dio;
      final locale = Localizations.localeOf(context).toLanguageTag();
      final resp =
          await dio.get('/v1/currency', queryParameters: {'locale': locale});

      List<CurrencyDto> list = [];
      if (resp.statusCode == 200 && resp.data is List) {
        list = (resp.data as List).map((e) => CurrencyDto.fromJson(e)).toList();
      }

      if (list.isEmpty) {
        list = [CurrencyDto(code: 'EUR', name: 'Euro')];
      }

      final current = list.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => list.first,
      );

      setState(() {
        currencies = list;
        selectedCurrency = current;
        currencyCode = current.code;
        currencyName = current.name;
      });
    } catch (e) {
      setState(() {
        currencies = [CurrencyDto(code: 'EUR', name: 'Euro')];
        selectedCurrency = currencies.first;
        currencyCode = 'EUR';
        currencyName = 'Euro';
      });
    } finally {
      if (mounted) setState(() => _isLoadingCurrencies = false);
    }
  }

  void _addEmptyAttributeRow() {
    setState(() {
      _attrPropCtrls.add(TextEditingController());
      _attrValCtrls.add(TextEditingController());
    });
  }

  void _removeAttributeRow(int index) {
    setState(() {
      _attrPropCtrls[index].dispose();
      _attrValCtrls[index].dispose();
      _attrPropCtrls.removeAt(index);
      _attrValCtrls.removeAt(index);
    });
  }

  List<ServiceAttributeDto> _collectAttributes() {
    final list = <ServiceAttributeDto>[];
    for (var i = 0; i < _attrPropCtrls.length; i++) {
      final prop = _attrPropCtrls[i].text.trim();
      final val = _attrValCtrls[i].text.trim();
      if (prop.isNotEmpty && val.isNotEmpty) {
        list.add(ServiceAttributeDto(prop, val));
      }
    }
    return list;
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
                  items: serviceTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                const SizedBox(height: 16),

                // PRICE
                Text('Price', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: priceAmount,
                        decoration: const InputDecoration(
                            labelText: 'Amount (e.g. 12.34)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: false),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter amount';
                          final normalized = v.replaceAll(',', '.');
                          final ok =
                              RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized);
                          return ok ? null : 'Invalid amount format';
                        },
                        onChanged: (v) => priceAmount = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<CurrencyDto>(
                        value: selectedCurrency,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                        items: currencies.map((c) {
                          final symbol =
                              NumberFormat.simpleCurrency(name: c.code)
                                  .currencySymbol;
                          return DropdownMenuItem(
                            value: c,
                            child: Text('$symbol ${c.name} — ${c.code}'),
                          );
                        }).toList(),
                        selectedItemBuilder: (_) => currencies.map((c) {
                          final symbol =
                              NumberFormat.simpleCurrency(name: c.code)
                                  .currencySymbol;
                          return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(symbol));
                        }).toList(),
                        onChanged: _isLoadingCurrencies
                            ? null
                            : (c) {
                                if (c == null) return;
                                setState(() {
                                  selectedCurrency = c;
                                  currencyCode = c.code;
                                  currencyName = c.name;
                                });
                              },
                        validator: (v) => v == null ? 'Select currency' : null,
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

                SizedBox(
                  key: _zipTargetKey,
                  child: CompositedTransformTarget(
                    link: _zipFieldLink,
                    child: TextFormField(
                      controller: _postcodeCtrl,
                      focusNode: _postcodeFocus,
                      decoration: const InputDecoration(
                        labelText: 'Postcode',
                        hintText: 'Напр., 12305',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(signed: false),
                      validator: (v) {
                        /* ... */
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'City'),
                  onChanged: (v) => address.city = v,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите город' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(labelText: 'State/Region'),
                  onChanged: (v) => address.state = v,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите регион/штат'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _street1Ctrl,
                  focusNode: _street1Focus,
                  decoration: const InputDecoration(labelText: 'Street/No.'),
                  onChanged: (v) => address.street1 = v,
                ),

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

                // ATTRIBUTES
                Text('Attributes',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_attrPropCtrls.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No attributes. Add some if needed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Column(
                  children: List.generate(_attrPropCtrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _attrPropCtrls[i],
                              decoration:
                                  const InputDecoration(labelText: 'Property'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _attrValCtrls[i],
                              decoration:
                                  const InputDecoration(labelText: 'Value'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeAttributeRow(i),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add attribute'),
                    onPressed: _addEmptyAttributeRow,
                  ),
                ),
                const SizedBox(height: 24),

                // SAVE
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final dio =
                        Provider.of<AuthService>(context, listen: false).dio;

                    final mainAttachmentName =
                        pickedImages.isNotEmpty ? pickedImages.first.name : '';

                    final normalizedAmount = priceAmount.replaceAll(',', '.');
                    final amountNum = num.parse(normalizedAmount);

                    address.postcode = int.tryParse(_postcodeCtrl.text.trim());
                    address.city = _cityCtrl.text.trim();
                    address.state = _stateCtrl.text.trim();
                    address.street1 = _street1Ctrl.text.trim();

                    final priceDto = PriceDto(
                      amountNum,
                      currencyCode,
                      currencyName,
                      negotiable,
                    );

                    final collectedAttrs = _collectAttributes();

                    final newService = NewUserServiceDto(
                      serviceTypeId: selectedType!.id,
                      name: name,
                      description: description,
                      mainAttachment: mainAttachmentName,
                      devices: selectedDeviceIds,
                      price: priceDto,
                      attributes: collectedAttrs,
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

  void _removeOverlayNow() {
    _zipOverlay?.remove();
    _zipOverlay = null;
    _zipOverlayVisible = false;
  }

  void _onZipChanged() {
    if (_suppressZipListener) return;

    final v = _postcodeCtrl.text.trim();
    address.postcode = int.tryParse(v);

    if (_lastAppliedZip != null && v == _lastAppliedZip) {
      _hideZipOverlay();
      return;
    }

    _zipDebounce?.cancel();

    if (v.length < 3) {
      _zipSuggestions = [];
      _hideZipOverlay();
      setState(() {});
      return;
    }
    _zipDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchZipSuggestions(v);
    });
  }

  void _showZipOverlay() {
    if (_zipOverlay != null) {
      _zipOverlay!.markNeedsBuild();
      return;
    }

    _zipOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideZipOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              child: CompositedTransformFollower(
                link: _zipFieldLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 48),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 420,
                    height: 260,
                    child: MouseRegion(
                      child: GestureDetector(
                        onTap: () {},
                        child: _buildZipSuggestionList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _insertOverlaySafely(_zipOverlay!);
  }

  void _hideZipOverlay() {
    debugPrint('overlay HIDE');
    _removeOverlaySafely();
  }

  Widget _buildZipSuggestionList() {
    if (_isLoadingZip) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_zipSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Нет подсказок'),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _zipSuggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = _zipSuggestions[i];
        return InkWell(
          onTap: () {
            print("click on item $i");
            _applyZipSuggestion(s);
          },
          child: ListTile(
            dense: true,
            title: Text('${s.postcode ?? ""}  •  ${s.city ?? ""}'),
            subtitle: Text(
                '${s.countryCode ?? ""} • ${s.countryName ?? ""}${(s.admin1 ?? "").isNotEmpty ? " • ${s.admin1}" : ""}'),
          ),
        );
      },
    );
  }

  void _applyZipSuggestion(PostalSuggestionDto s) {
    final postcode = (s.postcode ?? '').trim();
    final city = (s.city ?? '').trim();
    final state = (s.admin1 ?? '').trim();

    debugPrint('applyZip: postcode=$postcode city=$city state=$state');

    _hideZipOverlay();

    _suppressZipListener = true;
    _lastAppliedZip = postcode;

    setState(() {
      address.postcode = int.tryParse(postcode);
      address.city = city;
      address.state = state.isNotEmpty ? state : null;

      _postcodeCtrl.text = postcode;
      _cityCtrl.text = city;
      _stateCtrl.text = state;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _suppressZipListener = false;
    });
  }

  void _insertOverlaySafely(OverlayEntry entry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _zipOverlay == entry && !_zipOverlayVisible) {
        Overlay.of(context)?.insert(entry);
        _zipOverlayVisible = true;
      }
    });
  }

  void _removeOverlaySafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _zipOverlay?.remove();
      _zipOverlay = null;
      _zipOverlayVisible = false;
    });
  }
}
