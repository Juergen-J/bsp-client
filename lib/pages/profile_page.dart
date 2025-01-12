import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../services/openid_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> personalData = {};
  bool _isLoading = true;
  final String _host = FlavorConfig.instance.variables['beHost'];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final data = await _getMe();
    if (data != null) {
      setState(() {
        personalData = data;
        _initializeControllers(data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeControllers(Map<String, dynamic> data) {
    data.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
    });
  }

  Future<Map<String, dynamic>?> _getMe() async {
    try {
      final httpClient = await getAccessTokenHttpClient();
      if (httpClient == null) {
        print('HTTP client is null. Authentication might have failed.');
        return null;
      }
      final response =
          await httpClient.get(Uri.parse('http://$_host/v1/user-profile/me'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Request failed with status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching me: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);
    final locales = appState.supportedLocales;

    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Personal Info',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ExpansionTile(
                  title: Text(
                    'Change Language',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButton<Locale>(
                        value: appState.locale,
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            appState.changeLocale(newLocale);
                          }
                        },
                        items: locales.map((locale) {
                          return DropdownMenuItem(
                            value: locale,
                            child: Text(_getLanguageName(locale)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Personal Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    ...personalData.keys.map((key) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: TextFormField(
                          controller: _controllers[key],
                          decoration: InputDecoration(
                            labelText: key,
                            border: OutlineInputBorder(),
                            enabled: false,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _hasChanges ? null : null,
                        child: Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}

String _getLanguageName(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return 'English';
    case 'ru':
      return 'Русский';
    default:
      return locale.languageCode;
  }
}
