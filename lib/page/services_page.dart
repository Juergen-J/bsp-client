import 'dart:async';

import 'package:berlin_service_portal/model/service/user_service_short_dto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/auth_service.dart';
import '../widgets/cards/add_device_card.dart';
import '../widgets/cards/service_card.dart';
import 'modal/modal_service.dart';
import 'modal/modal_type.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<UserServiceShortDto> _services = [];

  @override
  void initState() {
    super.initState();
    fetchMyServices();
  }

  Future<void> fetchMyServices() async {
    final dio = Provider.of<AuthService>(context, listen: false).dio;
    final response = await dio.get('/v1/service/my');

    if (response.statusCode == 200 && response.data['content'] != null) {
      setState(() {
        _services = (response.data['content'] as List)
            .map((item) => UserServiceShortDto.fromJson(item))
            .toList();
      });
    } else {
      print('Error loading services: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Services")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _services.length + 1,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 330,
          ),
          itemBuilder: (context, index) {
            if (index == _services.length) {
              return AddDeviceCard(
                onTap: () async {
                  final modalManager = context.read<ModalManager>();
                  final resultCompleter = Completer<bool>();
                  modalManager.show(
                    ModalType.serviceCreateForm,
                    data: {
                      'service': null,
                      'readonly': false,
                      'completer': resultCompleter,
                    },
                  );

                  final result = await resultCompleter.future;
                  if (result == true) fetchMyServices();
                },
              );
            }

            final service = _services[index];
            return ServiceCard(
              service: service,
              onTap: () async {
                final modalManager = context.read<ModalManager>();
                final resultCompleter = Completer<bool>();
                modalManager.show(
                  ModalType.serviceEditForm,
                  data: service.id,
                );

                final result = await resultCompleter.future;
                if (result == true) fetchMyServices();
              },
            );
          },
        ),
      ),
    );
  }
}
