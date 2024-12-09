import 'package:berlin_service_portal/pages/messages_page.dart';
import 'package:berlin_service_portal/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
      case 1:
        page = MessagesPage();
      case 2:
        page = SettingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.message), label: 'Messages'),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: AppLocalizations.of(context)!.hello("boris"),
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                )
              ],
            );
          } else {
            return DefaultTabController(
              initialIndex: selectedIndex,
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("App"),
                  leading: Icon(Icons.abc),
                  bottom: const TabBar(tabs: <Widget>[
                    Tab(
                      icon: Icon(Icons.home),
                      text: "Home",
                    ),
                    Tab(
                      icon: Icon(Icons.message),
                      text: "Messages",
                    ),
                    Tab(
                      icon: Icon(Icons.settings),
                      text: "Settings",
                    )
                  ]),
                ),
                body: TabBarView(children: <Widget>[
                  HomePage(),
                  MessagesPage(),
                  SettingsPage()
                ]),
              ),
            );
          }
        },
      ),
    );
  }
}
