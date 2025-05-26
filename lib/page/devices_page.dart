import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/brand.dart';
import '../model/device_type.dart';
import '../model/short_device.dart';
import '../service/auth_service.dart';
import '../widgets/cards/add_device_card.dart';
import '../widgets/cards/device_card.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<ShortDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    loadMockDevices();
  }

  Future<void> fetchMyDevices() async {
    final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
    final String _host = FlavorConfig.instance.variables['beHost'];
    final response = await dio.get('http://$_host/v1/device/my');

    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        _devices = (response.data['content'] as List)
            .map((item) => ShortDevice.fromJson(item))
            .toList();
      });
    } else {
      print(
          'Error loading devices: ${response.statusCode} - ${response.statusMessage}');
    }
  }

  void loadMockDevices() {
    setState(() {
      _devices = [
        ShortDevice(
          id: '1',
          name: 'Prusa i3 MK3',
          deviceType: DeviceType(
              id: 'printer', displayName: '3D Printer', systemName: ''),
          brand: Brand(id: 'prusa', name: 'Prusa'),
          attributes: [],
          imagePath: 'assets/images/Foto.png',
        ),
        ShortDevice(
          id: '2',
          name: 'Ender 3 Pro',
          deviceType: DeviceType(
              id: 'printer', displayName: '3D Printer', systemName: ''),
          brand: Brand(id: 'creality', name: 'Creality'),
          attributes: [],
          imagePath: 'assets/images/Foto.png',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _devices.length + 1,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300, // ширина карточки = максимум 300
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 330, // фиксированная высота карточки
          ),
          itemBuilder: (context, index) {
            if (index == _devices.length) {
              return AddDeviceCard(
                onTap: () async {
                  final result = await context.push('/device-form');
                  if (result == true) loadMockDevices();
                },
              );
            }

            final device = _devices[index];
            return DeviceCard(
              device: device,
              onTap: () async {
                final result =
                    await context.push('/device-form', extra: device);
                if (result == true) loadMockDevices();
              },
            );
          },
        ),
      ),
    );
  }
}
