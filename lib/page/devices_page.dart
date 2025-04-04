import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/short_device.dart';
import '../service/auth_service.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<ShortDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    fetchMyDevices();
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            if (index == _devices.length) {
              return GestureDetector(
                onTap: () async {
                  final resul = await context.push('/device-form');
                  if (resul == true) fetchMyDevices();
                },
                child: Card(
                  color: Colors.green[50],
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 40, color: Colors.green),
                        SizedBox(height: 8),
                        Text("Add new device",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }

            final device = _devices[index];
            return GestureDetector(
              onTap: () async {
                final result =
                    await context.push('/device-form', extra: device);
                if (result == true) fetchMyDevices();
              },
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.print,
                            size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(device.deviceType.displayName),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
