import 'package:flutter/cupertino.dart';
import 'package:openid_client/openid_client.dart';

class AppState extends ChangeNotifier {
  final List<Locale> supportedLocales = [Locale('en'), Locale('ru')];
  Locale _locale = Locale('en');
  UserInfo? _userInfo;

  Locale get locale => _locale;
  UserInfo? get userInfo => _userInfo;

  void changeLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
  void setUserInfo(UserInfo userInfo) {
    _userInfo = userInfo;
    notifyListeners();
    print('UserInfo set: ${_userInfo?.name}, ${_userInfo?.email}');
  }

  void clearUserInfo() {
    _userInfo = null;
    notifyListeners();
    print('UserInfo cleared');
  }

}
