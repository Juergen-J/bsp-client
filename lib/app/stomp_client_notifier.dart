import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:openid_client/openid_client.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/openid_client.dart';

class StompClientNotifier extends ChangeNotifier {
  final String _host = FlavorConfig.instance.variables['beHost'];

  StompClient? _stompClient;
  String message = '';
  String? userId;

  Future<void> getCurrentUserId() async {
    UserInfo? userInfo = await getUserInfo();
    userId = userInfo?.subject;
  }

  void connectStompClient() async {
    userId = null;
    final String? token = await getToken();
    if (token == null) {
      throw Exception("Token not found");
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
    }
    await getCurrentUserId();
  }

  void _onStompConnected(StompFrame frame) {
    print('Connected to WebSocket');
    _subscribeToWs();
  }

  void _subscribeToWs() {
    _stompClient?.subscribe(
      destination: '/user/topic/messages',
      callback: (frame) {
        if (frame.body != null) {
          print('Message received: ${frame.body}');
          message = frame.body!;
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

