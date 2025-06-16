import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/image_attachment_dto.dart';
import '../../model/brand.dart';
import '../../model/device_type.dart';
import '../../model/short_device.dart';
import '../../service/auth_service.dart';
import '../../widgets/device_image_carousel.dart';
import 'base_modal_wrapper.dart';

class DeviceFormModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isMobile;
  final ShortDevice? editedDevice;
  final void Function(bool success)? onFinish;
  final bool readonly;

  const DeviceFormModal(
      {super.key,
      required this.onClose,
      required this.isMobile,
      this.editedDevice,
      this.onFinish,
      this.readonly = false});

  @override
  State<DeviceFormModal> createState() => _DeviceFormModalState();
}

class _DeviceFormModalState extends State<DeviceFormModal> {
  final _formKey = GlobalKey<FormState>();
  String deviceName = '';
  List<MapEntry<String, String>> parameters = [];

  DeviceType? selectedDeviceType;
  Brand? selectedBrand;
  ShortDevice? selectedModel;
  List<DeviceType> deviceTypeList = [];
  List<Brand> brandList = [];
  List<ShortDevice> deviceList = [];

  @override
  void initState() {
    super.initState();
    fetchDeviceTypes().then((_) {
      if (widget.editedDevice != null) {
        prefillForm(widget.editedDevice!);
      }
    });
  }

  Future<void> fetchDeviceTypes() async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    final response = await dio.get('http://$_host/v1/device-type');
    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        deviceTypeList = (response.data['content'] as List)
            .map((item) => DeviceType.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> fetchBrands(String deviceTypeId) async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    final response = await dio.get('http://$_host/v1/brand',
        queryParameters: {'deviceTypeId': deviceTypeId});
    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        brandList = (response.data['content'] as List)
            .map((item) => Brand.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> fetchDevicesByBrand(String deviceTypeId, String brandId) async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    final response = await dio.post(
      'http://$_host/v1/device/search',
      data: {'deviceTypeId': deviceTypeId, 'brandId': brandId},
    );
    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        deviceList = (response.data['content'] as List)
            .map((item) => ShortDevice.fromJson(item))
            .toList();
        if (deviceList.isEmpty) {
          deviceName = '${selectedBrand?.name ?? ''}';
        }
      });
    }
  }

  Future<void> addDeviceToMyListAndClose(String deviceId) async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    try {
      await dio.post('http://$_host/v1/device/$deviceId/add-to-my-list');
      widget.onClose();
    } catch (e) {
      print('Fehler beim Hinzufügen des Geräts: $e');
    }
  }

  Future<void> deleteDeviceFromMyListAndClose(String deviceId) async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    try {
      await dio.post('http://$_host/v1/device/$deviceId/remove-from-my-list');
      widget.onClose();
    } catch (e) {
      print('Fehler beim Löschen des Geräts: $e');
    }
  }

  Future<void> prefillForm(ShortDevice device) async {
    selectedDeviceType =
        deviceTypeList.firstWhere((dt) => dt.id == device.deviceType.id);

    if (selectedDeviceType != null) {
      await fetchBrands(selectedDeviceType!.id);
      selectedBrand = brandList.firstWhere((b) => b.id == device.brand.id);

      if (selectedBrand != null) {
        await fetchDevicesByBrand(selectedDeviceType!.id, selectedBrand!.id);
        selectedModel = deviceList.firstWhere((d) => d.id == device.id);

        if (selectedModel != null) {
          deviceName = '${selectedBrand!.name} ${selectedModel!.name}';
          parameters = selectedModel!.attributes
              .map((a) => MapEntry(a.propertyName, a.value))
              .toList();
        }
      }
    }

    setState(() {});
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.editedDevice == null
                    ? 'Gerät hinzufügen'
                    : 'Gerät bearbeiten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DeviceType>(
                decoration: const InputDecoration(labelText: "Gerätetyp"),
                items: deviceTypeList
                    .map((dt) => DropdownMenuItem(
                        value: dt, child: Text(dt.displayName)))
                    .toList(),
                value: selectedDeviceType,
                onChanged: widget.readonly
                    ? null
                    : (newValue) {
                        setState(() {
                          selectedDeviceType = newValue;
                          selectedBrand = null;
                          selectedModel = null;
                          brandList.clear();
                          deviceList.clear();
                          deviceName = '';
                          parameters.clear();
                        });
                        if (newValue != null) fetchBrands(newValue.id);
                      },
              ),
              const SizedBox(height: 16),
              if (selectedDeviceType != null)
                DropdownButtonFormField<Brand>(
                  decoration: const InputDecoration(labelText: "Marke"),
                  items: brandList
                      .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b.name)))
                      .toList(),
                  value: selectedBrand,
                  onChanged: widget.readonly
                      ? null
                      : (newValue) {
                          setState(() {
                            selectedBrand = newValue;
                            selectedModel = null;
                            deviceList.clear();
                            deviceName = newValue?.name ?? '';
                            parameters.clear();
                          });
                          if (newValue != null)
                            fetchDevicesByBrand(
                                selectedDeviceType!.id, newValue.id);
                        },
                ),
              const SizedBox(height: 16),
              if (selectedBrand != null && deviceList.isNotEmpty)
                DropdownButtonFormField<ShortDevice>(
                  decoration: const InputDecoration(labelText: "Modell"),
                  items: deviceList
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d.name)))
                      .toList(),
                  value: selectedModel,
                  onChanged: widget.readonly
                      ? null
                      : (newValue) {
                          setState(() {
                            selectedModel = newValue;
                            if (newValue != null) {
                              deviceName =
                                  '${selectedBrand!.name} ${newValue.name}';
                              parameters = newValue.attributes
                                  .map((a) => MapEntry(a.propertyName, a.value))
                                  .toList();
                            } else {
                              deviceName = selectedBrand?.name ?? '';
                              parameters.clear();
                            }
                          });
                        },
                ),
              const SizedBox(height: 16),
              if (selectedModel?.attachments.isNotEmpty == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bilder",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DeviceImageCarousel(
                      imageIds: selectedModel!.attachments
                          .map(
                              (a) => (a.details as ImageAttachmentDto).normalId)
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              const Text("Technische Daten",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  for (final entry in parameters)
                    TableRow(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(entry.key,
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(entry.value),
                      ),
                    ]),
                ],
              ),
              const SizedBox(height: 24),
              widget.editedDevice != null
                  ? ElevatedButton(
                      onPressed: () {
                        deleteDeviceFromMyListAndClose(widget.editedDevice!.id);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Aus meiner Liste entfernen'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (selectedModel != null) {
                          addDeviceToMyListAndClose(selectedModel!.id);
                        }
                      },
                      child: const Text('Zu meiner Liste hinzufügen'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
