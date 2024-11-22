import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:berlin_service_portal/services/openid_client.dart';

import '../app/app_state.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userInfo = Provider.of<AppState>(context).userInfo;
    // String userName = userInfo?.name ?? 'Гость';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userInfo != null) ...[
              Text('Hello ${userInfo.name}'),
              Text(userInfo.email ?? ''),
              OutlinedButton(
                  child: const Text('Logout'),
                  onPressed: () async {
                    Provider.of<AppState>(context, listen: false)
                        .clearUserInfo();
                  })
            ],
            if (userInfo == null)
              OutlinedButton(
                  child: const Text('Login'),
                  onPressed: () async {
                    try {
                      var userInfo = await auth();
                      Provider.of<AppState>(context, listen: false)
                          .setUserInfo(userInfo);
                    } catch (e) {
                      print('Authentication failed: $e');
                    }
                  }),
            // Text(
            //   AppLocalizations.of(context)!.hello(userName),
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
          ],
        ),
      )
    ]);
  }
}
