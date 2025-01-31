import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../service/auth_service.dart';

class StompClientNotifier extends ChangeNotifier {
  final String _host = FlavorConfig.instance.variables['beHost'];
  final AuthService _authService;

  StompClient? _stompClient;
  String report = '';
  String message = '';
  String? userId;

  StompClientNotifier(this._authService);

  void connectStompClient() async {
    await _authService.ensureTokenIsFresh();
    final token = _authService.accessToken;
    if (token == null) {
      throw Exception("No token found (user not logged in?)");
    }

    if (_stompClient == null) {
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
  }

  void _subscribeToMessageWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/messages',
      callback: (frame) {
        if (frame.body != null) {
          print('Message received: ${frame.body}');
          message = frame.body!;
          report = '';
          notifyListeners();
        }
      },
    );
  }

  void _subscribeToReportWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/message-reports',
      callback: (frame) {
        if (frame.body != null) {
          print('Message received: ${frame.body}');
          report = frame.body!;
          message = '';
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }

  void send({required String destination, required Object message}) {
    _stompClient?.send(
      destination: '/app/v1/send-message',
      body: jsonEncode(message),
    );
  }
}
