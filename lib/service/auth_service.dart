import 'dart:html' as html;
import 'package:berlin_service_portal/model/user_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../model/login_response.dart';
import '../page/modal/modal_service.dart';
import '../page/modal/modal_type.dart';

class AuthService extends ChangeNotifier {
  final String _host;
  final Dio _dio = Dio();

  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  DateTime? _accessTokenExpiry;
  DateTime? _refreshTokenExpiry;

  UserInfo? _userInfo;

  bool _isRefreshing = false;

  String? get accessToken => _accessToken;

  bool get isLoggedIn => _accessToken != null && _refreshToken != null;

  UserInfo? getUserInfo() => _userInfo;

  Dio get dio => _dio;

  String get host => _host;

  bool _isInitialized = false;

  AuthService(this._host) {
    _dio.options.baseUrl = "http://$_host";
    _dio.interceptors.add(AuthInterceptor(this));
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadTokensFromStorage();
  }

  void Function()? onLogoutCallback;
  void Function()? onLoginCallback;

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

      if (_refreshTokenExpiry != null &&
          DateTime.now().isAfter(_refreshTokenExpiry!)) {
        if (kDebugMode) {
          print('Refresh token expired, logging out');
        }
        await logout();
        return;
      }

      try {
        await fetchUserInfoFromApi();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to fetch user info on init: $e');
        }
        await logout();
      }
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

      _saveTokensToStorage();
      await fetchUserInfoFromApi();
      notifyListeners();
      onLoginCallback?.call();
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

  Future<bool> refreshTokenCall() async {
    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _accessToken != null;
    }

    _isRefreshing = true;

    try {
      if (_refreshTokenExpiry != null &&
          DateTime.now().isAfter(_refreshTokenExpiry!)) {
        if (kDebugMode) {
          print('Refresh token expired, logging out');
        }
        await logout();
        return false;
      }

      final rawDio = Dio();
      rawDio.options.baseUrl = _dio.options.baseUrl;

      final response = await rawDio.post(
        '/v1/user/refresh-token',
        data:  _refreshToken,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );

      final data = response.data;
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];
      _idToken ??= data['id_token'];

      final expiresIn = data['expires_in'];
      final refreshExpiresIn = data['refresh_expires_in'];

      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _refreshTokenExpiry =
          DateTime.now().add(Duration(seconds: refreshExpiresIn));

      _saveTokensToStorage();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      print(
          'Refresh token error: ${e.response?.statusCode} - ${e.response?.data}');
      await logout();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refreshTokenIfNeeded() async {
    if (!isLoggedIn) return;
    final now = DateTime.now();

    if (_accessTokenExpiry == null ||
        now.isAfter(
            _accessTokenExpiry!.subtract(const Duration(seconds: 30)))) {
      if (_refreshTokenExpiry != null && now.isBefore(_refreshTokenExpiry!)) {
        await refreshTokenCall();
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
    if (_idToken != null) {
      await logoutFromApi();
    }

    onLogoutCallback?.call();


    _accessToken = null;
    _refreshToken = null;
    _idToken = null;
    _accessTokenExpiry = null;
    _refreshTokenExpiry = null;
    _userInfo = null;
    _isRefreshing = false;

    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('refresh_token');
    html.window.localStorage.remove('id_token');
    html.window.localStorage.remove('access_token_expiry');
    html.window.localStorage.remove('refresh_token_expiry');

    notifyListeners();
  }

  Future<void> logoutFromApi() async {
    try {
      await _dio.post(
        'http://localhost:8090/v1/user/logout',
        data: _idToken,
        options: Options(headers: {"Content-Type": "text/plain"}),
      );
    } on DioException catch (e) {
      print('Logout error: ${e.response?.statusCode} - ${e.response?.data}');
    }
  }
}

Future<bool> requireLoginIfNeeded(BuildContext context) async {
  final auth = Provider.of<AuthService>(context, listen: false);
  final modal = Provider.of<ModalManager>(context, listen: false);

  if (auth.isLoggedIn) return true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    modal.show(ModalType.login);
  });

  const timeout = Duration(seconds: 10);
  final startTime = DateTime.now();

  while (!auth.isLoggedIn) {
    await Future.delayed(const Duration(milliseconds: 250));

    if (!context.mounted) return false;
    if (DateTime.now().difference(startTime) > timeout) break;
  }

  return auth.isLoggedIn;
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
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    if (err.response?.statusCode == 401 &&
        authService.isLoggedIn &&
        !requestOptions.extra.containsKey('retry')) {
      final refreshSuccess = await authService.refreshTokenCall();

      if (refreshSuccess) {
        final newToken = authService.accessToken;
        if (newToken != null) {
          try {
            final newRequest =
                await _retryWithNewToken(requestOptions, newToken);
            return handler.resolve(newRequest);
          } catch (retryError) {
            if (kDebugMode) {
              print('Retry request failed: $retryError');
            }
          }
        }
      }
    }

    return super.onError(err, handler);
  }

  Future<Response<dynamic>> _retryWithNewToken(
      RequestOptions requestOptions, String newToken) {
    final newOptions = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $newToken',
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      extra: {...requestOptions.extra, 'retry': true},
    );

    final dio = Dio();
    dio.options.baseUrl = authService.host.startsWith('http')
        ? authService.host
        : "http://${authService.host}";

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: newOptions,
    );
  }
}
