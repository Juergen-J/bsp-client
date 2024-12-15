import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class StompClientNotifier extends ChangeNotifier{
  final String host = "localhost:8090";
  final String username = "1"; // Example username
  final String userId = "1"; // Example userId


  StompClient? _stompClient;
  String message = '';

  void connectStompClient() {
    if (_stompClient == null) {
      _stompClient = StompClient(
        config: StompConfig(
          url: 'ws://$host/chat',
          onConnect: _onStompConnected,
          onStompError: (frame) {
            print('Stomp error: ${frame.body}');
          },
          onWebSocketError: (error) {
            print('WebSocket error: $error');
          },
          onDisconnect: (frame) {
            print('Disconnected: ${frame.body}');
          },
          reconnectDelay: const Duration(seconds: 5),
        ),
      );

      _stompClient?.activate();
    }
  }

  void _onStompConnected(StompFrame frame) {
    print('Connected to WebSocket');
    _subscribeToWs();

    _stompClient?.send(
      destination: '/app/v1/add-user',
      body: jsonEncode({"username": username}),
    );
  }

  void _subscribeToWs() {
    _stompClient?.subscribe(
      destination: '/user/$username/topic/messages',
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