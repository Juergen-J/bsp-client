import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/brand.dart';
import '../model/device_type.dart';
import '../model/short_device.dart';
import '../service/auth_service.dart';

class DeviceFormPage extends StatefulWidget {
  final ShortDevice? editedDevice;

  const DeviceFormPage({Key? key, this.editedDevice}) : super(key: key);

  @override
  State<DeviceFormPage> createState() => _DeviceFormPageState();
}

class _DeviceFormPageState extends State<DeviceFormPage> {
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
      context.pop();
    } catch (e) {
      print('Error adding device: $e');
    }
  }

  Future<void> deleteDeviceFromMyListAndClose(String deviceId) async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];

    try {
      await dio.post('http://$_host/v1/device/$deviceId/remove-from-my-list');
      context.pop();
    } catch (e) {
      print('Error deleting device: $e');
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
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.editedDevice == null ? 'Add Device' : 'Edit Device')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<DeviceType>(
                decoration: const InputDecoration(labelText: "Device Type"),
                items: deviceTypeList
                    .map((dt) => DropdownMenuItem(
                        value: dt, child: Text(dt.displayName)))
                    .toList(),
                value: selectedDeviceType,
                onChanged: (newValue) {
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
                  decoration: const InputDecoration(labelText: "Brand"),
                  items: brandList
                      .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b.name)))
                      .toList(),
                  value: selectedBrand,
                  onChanged: (newValue) {
                    setState(() {
                      selectedBrand = newValue;
                      selectedModel = null;
                      deviceList.clear();
                      deviceName = newValue?.name ?? '';
                      parameters.clear();
                    });
                    if (newValue != null)
                      fetchDevicesByBrand(selectedDeviceType!.id, newValue.id);
                  },
                ),
              const SizedBox(height: 16),
              if (selectedBrand != null && deviceList.isNotEmpty)
                DropdownButtonFormField<ShortDevice>(
                  decoration: const InputDecoration(labelText: "Model"),
                  items: deviceList
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d.name)))
                      .toList(),
                  value: selectedModel,
                  onChanged: (newValue) {
                    setState(() {
                      selectedModel = newValue;
                      if (newValue != null) {
                        deviceName = '${selectedBrand!.name} ${newValue.name}';
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
              const Text("Technical Specs",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: parameters.length,
                itemBuilder: (context, index) => Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: parameters[index].key,
                        decoration: const InputDecoration(labelText: "Key"),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: parameters[index].value,
                        decoration: const InputDecoration(labelText: "Value"),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              widget.editedDevice != null
                  ? ElevatedButton(
                      onPressed: () {
                        deleteDeviceFromMyListAndClose(widget.editedDevice!.id);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete from My Devices'),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (selectedModel != null) {
                          addDeviceToMyListAndClose(selectedModel!.id);
                        }
                      },
                      child: const Text('Add to My Devices'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
