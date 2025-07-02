import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../service/auth_service.dart';

class StompClientNotifier extends ChangeNotifier {
  final String _host = FlavorConfig.instance.variables['beHost'];
  final AuthService _authService;

  StompClient? _stompClient;
  final Queue<String> messageQueue = Queue<String>();
  bool _processingMessages = false;
  final Queue<String> statusQueue = Queue<String>();
  bool _processingStatuses = false;
  final Queue<String> reportQueue = Queue<String>();
  bool _processingReports = false;

  String userStatus = '';
  String report = '';
  String message = '';
  String? userId;
  bool get isConnected => _stompClient?.connected ?? false;
  StompClient? get stompClient => _stompClient;


  StompClientNotifier(this._authService);

  void connectStompClient() async {
    if(!_authService.isLoggedIn){
      print('user not logged');
      return;
    }
    await _authService.ensureTokenIsFresh();
    final token = _authService.accessToken;
    if (token == null) {
      throw Exception("No token found (user not logged in?)");
    }

    if (_stompClient == null || !_stompClient!.isActive) {
      _stompClient = StompClient(
        config: StompConfig(
          url: 'ws://$_host/chat',
          onConnect: _onStompConnected,
          beforeConnect: () async {
            print('waiting to connect...');
            await Future.delayed(const Duration(milliseconds: 5));
            print('connecting...');
          },
          stompConnectHeaders: {'X-Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'X-Authorization': 'Bearer $token'},
          onStompError: (frame) {
            print('Stomp error: ${frame.body}');
          },
          onWebSocketError: (error) {
            print('WebSocket error: $error');
          },
          onDisconnect: (frame) {
            print('Disconnected: ${frame.body}');
          },
          reconnectDelay: const Duration(seconds: 60),
        ),
      );

      _stompClient?.activate();
      final userInfo = _authService.getUserInfo();
      userId = userInfo?.id;
    }
  }

  void _onStompConnected(StompFrame frame) {
    print('Connected to WebSocket');
    _subscribeToMessageWs();
    _subscribeToReportWs();
    _subscribeToUserStatusWs();
  }

  void _subscribeToMessageWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/messages',
      callback: (frame) async {
        if (frame.body != null) {
          print('Message received: ${frame.body}');
          if (frame.body != null) {
            messageQueue.add(frame.body!);
            if (_processingMessages) return;

            _processingMessages = true;
            while (messageQueue.isNotEmpty) {
              final msg = messageQueue.removeFirst();
              message = msg;
              report = '';
              userStatus = '';
              notifyListeners();
              await Future.delayed(Duration(milliseconds: 10));
            }
            _processingMessages = false;
          }
        }
      },
    );
  }

  void _subscribeToReportWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/message-reports',
      callback: (frame) async {
        if (frame.body != null) {
          reportQueue.add(frame.body!);
          if (_processingReports) return;

          _processingReports = true;
          while (reportQueue.isNotEmpty) {
            final msg = reportQueue.removeFirst();
            message = '';
            report = msg;
            userStatus = '';
            notifyListeners();
            await Future.delayed(Duration(milliseconds: 10));
          }
          _processingReports = false;
        }
      },
    );
  }

  void _subscribeToUserStatusWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/user-status',
      callback: (frame) async {
        if (frame.body != null) {
          statusQueue.add(frame.body!);
          if (_processingStatuses) return;

          _processingStatuses = true;
          while (statusQueue.isNotEmpty) {
            final msg = statusQueue.removeFirst();
            message = '';
            report = '';
            userStatus = msg;
            notifyListeners();
            await Future.delayed(Duration(milliseconds: 10));
          }
          _processingStatuses = false;
        }
      },
    );
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _stompClient = null;
    super.dispose();
  }

  void send({required String destination, required Object message}) {
    _stompClient?.send(
      destination: '/app/v1/send-message',
      body: jsonEncode(message),
    );
  }
}
