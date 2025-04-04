import 'dart:html' as html;
import 'package:berlin_service_portal/model/user_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_flavor/flutter_flavor.dart';

import '../model/login_response.dart';

class AuthService extends ChangeNotifier {
  final String _host = FlavorConfig.instance.variables['beHost'];
  final Dio _dio = Dio();

  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  DateTime? _accessTokenExpiry;
  DateTime? _refreshTokenExpiry;

  UserInfo? _userInfo;

  String? get accessToken => _accessToken;

  bool get isLoggedIn => _accessToken != null && _refreshToken != null;

  UserInfo? getUserInfo() => _userInfo;

  Dio get dio => _dio;

  AuthService() {
    _dio.interceptors.add(AuthInterceptor(this));
    _init();
  }

  Future<void> _init() async {
    await _loadTokensFromStorage();
  }

  Future<void> _loadTokensFromStorage() async {
    final storedAccessToken = html.window.localStorage['access_token'];
    final storedRefreshToken = html.window.localStorage['refresh_token'];
    final storedAccessTokenExpiry =
        html.window.localStorage['access_token_expiry'];
    final storedRefreshTokenExpiry =
        html.window.localStorage['refresh_token_expiry'];
    final idToken = html.window.localStorage['id_token'];

    if (storedAccessToken != null &&
        storedRefreshToken != null &&
        idToken != null) {
      _accessToken = storedAccessToken;
      _refreshToken = storedRefreshToken;
      _idToken = idToken;

      if (storedAccessTokenExpiry != null) {
        _accessTokenExpiry = DateTime.tryParse(storedAccessTokenExpiry);
      }
      if (storedRefreshTokenExpiry != null) {
        _refreshTokenExpiry = DateTime.tryParse(storedRefreshTokenExpiry);
      }

      // _decodeUserInfoFromToken(_accessToken!);
      fetchUserInfoFromApi();
      notifyListeners();
    }
  }

  void _saveTokensToStorage() {
    if (_accessToken != null) {
      html.window.localStorage['access_token'] = _accessToken!;
    }
    if (_refreshToken != null) {
      html.window.localStorage['refresh_token'] = _refreshToken!;
    }
    if (_idToken != null) {
      html.window.localStorage['id_token'] = _idToken!;
    }
    if (_accessTokenExpiry != null) {
      html.window.localStorage['access_token_expiry'] =
          _accessTokenExpiry!.toIso8601String();
    }
    if (_refreshTokenExpiry != null) {
      html.window.localStorage['refresh_token_expiry'] =
          _refreshTokenExpiry!.toIso8601String();
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'http://localhost:8090/v1/user/login',
        data: {
          "email": email,
          "password": password,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      final loginResponse = LoginResponse.fromJson(response.data);

      _accessToken = loginResponse.accessToken;
      _refreshToken = loginResponse.refreshToken;
      _idToken = loginResponse.idToken;

      final expiresIn = loginResponse.expiresIn;
      final refreshExpiresIn = loginResponse.refreshExpiresIn;

      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _refreshTokenExpiry =
          DateTime.now().add(Duration(seconds: refreshExpiresIn));

      // _decodeUserInfoFromToken(_accessToken!);

      _saveTokensToStorage();
      fetchUserInfoFromApi();
      notifyListeners();
      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        if (e.response.toString() == "unverified_mail") {
          return "unverified_mail";
        } else {
          return 'incorrect_password';
        }
      }

      return '';
    }
  }

  Future<String> signUp(
      String email, String password, String firstName, String lastName) async {
    try {
      final response = await Dio().post(
        'http://localhost:8090/v1/user/signup',
        data: {
          "email": email,
          "firstName": firstName,
          "lastName": lastName,
          "password": password,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      if (response.statusCode == 204) {
      } else {
        if (kDebugMode) {
          print('signup: status code ${response.statusCode}');
        }
      }
      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return 'email_exist';
      }
      return '';
    }
  }

  Future<String> verifyEmail(String email, String code) async {
    try {
      final response = await Dio().post(
        'http://localhost:8090/v1/user/verify-email',
        data: {
          "email": email,
          "code": code,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 204) {
      } else {
        if (kDebugMode) {
          print('verification email: status code ${response.statusCode}');
        }
      }
      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return 'incorrect_code';
      }
      return '';
    }
  }

  Future<String> recoverPassword(
      String email, String code, String password) async {
    try {
      final response = await Dio().post(
        'http://localhost:8090/v1/user/recover-password',
        data: {
          "email": email,
          "password": password,
          "code": code,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 204) {
      } else {
        if (kDebugMode) {
          print('recovery password: status code ${response.statusCode}');
        }
      }
      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return 'incorrect_code';
      }
      return '';
    }
  }

  Future<String> sendPasswordRecoveryCode(String email) async {
    try {
      final response = await Dio().post(
        'http://localhost:8090/v1/user/send-forgot-password-code',
        data: email,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );

      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return 'incorrect_email';
      }
      return '';
    }
  }

  Future<void> resendVerifyEmail(String email) async {
    try {
      final response = await Dio().post(
        'http://localhost:8090/v1/user/resend-verify-email',
        data: email,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );

      if (response.statusCode == 204) {
      } else {
        if (kDebugMode) {
          print(
              'resend verification email: status code ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        rethrow;
      }
    }
  }

  Future<void> fetchUserInfoFromApi() async {
    try {
      final response =
          await _dio.get('http://localhost:8090/v1/user-profile/me');
      final data = response.data;
      _userInfo = UserInfo.fromJson(data);
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
      }
      rethrow;
    }
  }

  Future<void> _refreshTokenCall() async {
    try {
      final response = await _dio.post(
        'http://localhost:8090/v1/user/refresh-token',
        data: _refreshToken,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];

      final expiresIn = data['expires_in'];
      final refreshExpiresIn = data['refresh_expires_in'];

      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _refreshTokenExpiry =
          DateTime.now().add(Duration(seconds: refreshExpiresIn));

      _saveTokensToStorage();
      notifyListeners();
    } on DioException catch (e) {
      print(
          'Refresh token error: ${e.response?.statusCode} - ${e.response?.data}');
      await logout();
    }
  }

  Future<void> refreshTokenIfNeeded() async {
    if (!isLoggedIn) return;
    final now = DateTime.now();

    if (_accessTokenExpiry == null ||
        now.isAfter(
            _accessTokenExpiry!.subtract(const Duration(seconds: 30)))) {
      if (_refreshTokenExpiry != null && now.isBefore(_refreshTokenExpiry!)) {
        await _refreshTokenCall();
      } else {
        await logout();
      }
    }
  }

  Future<void> ensureTokenIsFresh() async {
    await refreshTokenIfNeeded();
  }

  /// Logout
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiry = null;
    _refreshTokenExpiry = null;

    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('refresh_token');
    html.window.localStorage.remove('access_token_expiry');
    html.window.localStorage.remove('refresh_token_expiry');

    await logoutFromApi();
    notifyListeners();
  }

  Future<void> logoutFromApi() async {
    try {
      await _dio.post(
        'http://localhost:8090/v1/user/logout',
        data: _idToken,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );
      notifyListeners();
    } on DioException catch (e) {
      print('Logout error: ${e.response?.statusCode} - ${e.response?.data}');
    }
  }
}

class AuthInterceptor extends Interceptor {
  final AuthService authService;

  AuthInterceptor(this.authService);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    await authService.ensureTokenIsFresh();

    final token = authService.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      authService._refreshTokenCall();
    }
    super.onError(err, handler);
  }
}
