import 'dart:convert';
import 'dart:html' as html;
import 'package:berlin_service_portal/model/user_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/login_response.dart';

class AuthService extends ChangeNotifier {
  final Dio _dio = Dio();

  String? _accessToken;
  String? _refreshToken;
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

    if (storedAccessToken != null && storedRefreshToken != null) {
      _accessToken = storedAccessToken;
      _refreshToken = storedRefreshToken;

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
    if (_accessTokenExpiry != null) {
      html.window.localStorage['access_token_expiry'] =
          _accessTokenExpiry!.toIso8601String();
    }
    if (_refreshTokenExpiry != null) {
      html.window.localStorage['refresh_token_expiry'] =
          _refreshTokenExpiry!.toIso8601String();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'http://localhost:8090/v1/user/login',
        data: {
          "email": email,
          "password": password,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      //todo use in be object
      final decoded = jsonDecode(response.data) as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(decoded);

      _accessToken = loginResponse.accessToken;
      _refreshToken = loginResponse.refreshToken;

      final expiresIn = loginResponse.expiresIn;
      final refreshExpiresIn = loginResponse.refreshExpiresIn;

      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _refreshTokenExpiry =
          DateTime.now().add(Duration(seconds: refreshExpiresIn));

      // _decodeUserInfoFromToken(_accessToken!);

      _saveTokensToStorage();
      fetchUserInfoFromApi();
      notifyListeners();
    } on DioException catch (e) {
      rethrow;
    }
  }

  // void _decodeUserInfoFromToken(String token) {
  //   try {
  //     final decoded = JwtDecoder.decode(token);
  //     _userName = decoded['name'];
  //     _email = decoded['email'];
  //   } catch (e) {
  //     _userName = null;
  //     _email = null;
  //   }
  // }

  Future<void> fetchUserInfoFromApi() async {
    try {
      final response =
          await _dio.get('http://localhost:8090/v1/user-profile/me');
      final data = response.data;
      _userInfo = UserInfo.fromJson(data);
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // todo
        await logout();
      }
      rethrow;
    }
  }

  Future<void> _refreshTokenCall() async {
    // final response = await _dio.post('http://localhost:8090/v1/user/refresh', data: {
    //   'refresh_token': _refreshToken,
    // });
    // final data = response.data;
    // _accessToken = data['access_token'];
    // _refreshToken = data['refresh_token'];
    // _accessTokenExpiry = ...
    // _refreshTokenExpiry = ...
    // _decodeUserInfoFromToken(_accessToken!);
    // _saveToStorage();
    // notifyListeners();
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

    // todo call logout in BE
    notifyListeners();
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

// Опционально можем обрабатывать 401, если сервер вернёт
// @override
// void onError(DioError err, ErrorInterceptorHandler handler) {
//   if (err.response?.statusCode == 401) {
//     // Попробовать рефрешнуться, если есть смысл
//   }
//   super.onError(err, handler);
// }
}
