import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:berlin_service_portal/services/openid_client.dart';

import '../app/app_state.dart';
import '../services/chat_service.dart';
import 'open_map_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userInfo = Provider.of<AppState>(context).userInfo;
    var userId;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userInfo != null) ...[
              Text('Hello ${userInfo.name}'),
              Text(userInfo.email ?? ''),
              Text(userInfo.subject ?? ''),
              OutlinedButton(
                  child: const Text('Logout'),
                  onPressed: () async {
                    await logoutUser();
                    Provider.of<AppState>(context, listen: false)
                        .clearUserInfo();
                  }),
              SizedBox(
                height: 10,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter User ID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  userId = value;
                },
              ),
              OutlinedButton(
                  onPressed: () async {
                    await createChatWith([userId]);
                  },
                  child: const Text('Create chat'))
            ],
            if (userInfo == null)
              OutlinedButton(
                  child: const Text('Login'),
                  onPressed: () async {
                    try {
                      await auth();
                    } catch (e) {
                      print('Authentication failed: $e');
                    }
                  }),
            Container(
              width: 500,
              height: 500,
              child: MapWithLocationPage(),
            )
          ],
        ),
      )
    ]);
  }
}
