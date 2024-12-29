import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import 'home_page.dart';
import '../pages/messages_page.dart';
import '../pages/settings_page.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var selectedIndex = 0;
  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var appState = Provider.of<AppState>(context);

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page = MessagesPage();
        break;
      case 2:
        page = SettingsPage();
        break;
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double contentWidth =
            constraints.maxWidth > 1200 ? 1200 : constraints.maxWidth;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56.0),
            child: Center(
              child: Container(
                width: contentWidth,
                child: AppBar(
                  title: const Text("App"),
                  actions: [
                    IconButton(
                      icon: Icon(appState.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode),
                      onPressed: appState.toggleTheme,
                    ),
                    GestureDetector(
                      key: _avatarKey,
                      onTap: _showContextMenu,
                      child: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          body: Center(
            child: Container(
              width: contentWidth,
              child: constraints.maxWidth < 450
                  ? Column(
                      children: [
                        Expanded(child: _buildMainArea(colorScheme, page)),
                        SafeArea(
                          child: _buildBottomNavigationBar(context),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildNavigationRail(constraints),
                        VerticalDivider(thickness: 1, width: 1),
                        Expanded(child: _buildMainArea(colorScheme, page)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainArea(ColorScheme colorScheme, Widget page) {
    return ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
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
    );
  }

  Widget _buildNavigationRail(BoxConstraints constraints) {
    return NavigationRail(
      extended: constraints.maxWidth > 800,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.message),
          label: Text('Messages'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (value) {
        setState(() {
          selectedIndex = value;
        });
      },
    );
  }

  void _showContextMenu() {
    final RenderBox avatarBox =
        _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final Offset avatarPosition = avatarBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        avatarPosition.dx,
        avatarPosition.dy + avatarBox.size.height,
        avatarPosition.dx + avatarBox.size.width,
        0,
      ),
      items: [
        PopupMenuItem(
          child: Text("Profile"),
        ),
        PopupMenuItem(
          child: Text("Logout"),
        ),
      ],
    );
  }
}
