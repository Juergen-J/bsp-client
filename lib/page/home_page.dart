import 'package:flutter/material.dart';
import '../service/chat_service.dart';
import 'open_map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var userId;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (1 == 1) ...[
              Text('Hello User'),
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
                    await createChatWith(context, [userId]);
                  },
                  child: const Text('Create chat'))
            ],
            Container(
              width: 500,
              height: 500,
              child: Placeholder(),
            )
          ],
        ),
      )
    ]);
  }
}
