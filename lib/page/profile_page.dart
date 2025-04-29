import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:berlin_service_portal/model/user_info.dart';

import '../service/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserInfo? _userInfo;
  bool _isLoading = true;
  bool _hasChanges = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    // _idController.dispose();

    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() => _isLoading = true);

    if (authService.isLoggedIn) {
      try {
        await authService.ensureTokenIsFresh();

        await authService.fetchUserInfoFromApi();

        final userInfo = authService.getUserInfo();
        if (userInfo != null) {
          setState(() {
            _userInfo = userInfo;
            _initializeControllers();
          });
        }
      } catch (e) {
        debugPrint('Error bei fetching userInfo: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  void _initializeControllers() {
    if (_userInfo == null) return;
    _firstNameController.text = _userInfo!.firstname;
    _lastNameController.text = _userInfo!.lastname;
    _emailController.text = _userInfo!.email;

    // _idController.text = _userInfo!.id;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Personal Info',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ExpansionTile(
                  title: const Text(
                    'Personal Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    //   child: TextFormField(
                    //     controller: _idController,
                    //     decoration: const InputDecoration(
                    //       labelText: 'ID',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //     enabled: false,
                    //   ),
                    // ),

                    // First Name
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _hasChanges = true);
                        },
                      ),
                    ),

                    // Last Name
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _hasChanges = true);
                        },
                      ),
                    ),

                    // Email
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _hasChanges = true);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _hasChanges ? _saveChanges : null,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  Future<void> _saveChanges() async {
    if (_userInfo == null) return;
    final authService = Provider.of<AuthService>(context, listen: false);

    final updatedUserInfo = UserInfo(
      id: _userInfo!.id,
      firstname: _firstNameController.text,
      lastname: _lastNameController.text,
      email: _emailController.text,
    );

    // await authService.updateUserInfo(updatedUserInfo);

    setState(() {
      _userInfo = updatedUserInfo;
      _hasChanges = false;
    });
  }
}
