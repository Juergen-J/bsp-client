import 'package:flutter/foundation.dart';

class AuthRedirectService extends ChangeNotifier {
  String? _pendingRedirect;

  String? get pendingRedirect => _pendingRedirect;

  void saveRedirect(String route) {
    _pendingRedirect = route;
  }

  void clearRedirect() {
    _pendingRedirect = null;
  }
}