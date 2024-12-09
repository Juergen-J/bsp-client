import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late StompClient _stompClient;
  final TextEditingController _controller = TextEditingController();
  final String userId = "1"; // Example userId
  final String username = "1"; // Example username
  final String host = "localhost:8090";

  List<Map<String, dynamic>> _conversations = [];
  String? _selectedChatId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _connectStompClient();
  }

  Future<void> _fetchConversations() async {
    try {
      final response =
          await Dio().get('http://$host/v1/user/$userId/message-report');
      final data = response.data['content'] as List;
      setState(() {
        _conversations = data
            .map((item) => {
                  'chatId': item['chatId'],
                  'countUnreadMessages': item['countUnreadMessages'],
                  'lastMessage': item['lastMessage'],
                  'lastMessageDate': item['lastMessageDate'],
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching conversations: $e');
    }
  }

  void _connectStompClient() {

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

    _stompClient.activate();
  }

  void _onStompConnected(StompFrame frame) {
    print('Connected to WebSocket');
    _subscribeToWs();

    //todo ?
    _stompClient.send(
      destination: '/app/v1/add-user',
      body: jsonEncode({"username": username}),
    );
  }

  void _subscribeToWs() {
    _stompClient.subscribe(
      destination: '/user/$username/topic/messages',
      callback: (frame) {
        if (frame.body != null) {
          print('Message received: ${frame.body}');
          setState(() {
            final message = jsonDecode(frame.body!);
            print(message);
            setState(() {
              _messages.add(message);
            });
          });
        }
      },
    );
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await Dio().get(
          'http://localhost:8090/v1/user/$userId/chat/$_selectedChatId/message');
      final rawData =
          response.data is String ? jsonDecode(response.data) : response.data;
      final data = rawData['content'] as List;
      setState(() {
        _messages = data
            .map((item) => {
                  'messageId': item['messageId'],
                  'username': item['username'],
                  'chatId': item['chatId'],
                  'message': item['message'],
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _selectedChatId != null) {
      final message = {
        "username": username,
        "chatId": _selectedChatId,
        "message": _controller.text
      };

      _stompClient.send(
        destination: '/app/v1/send-message',
        body: jsonEncode(message),
      );

      _controller.clear();
    }
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_stompClient.isActive) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
      ),
      body: Row(
        children: [
          // Sidebar for conversations
          Container(
            width: 250,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return ListTile(
                  title: Text(conversation['lastMessage'] ?? 'No message'),
                  subtitle:
                      Text('Unread: ${conversation['countUnreadMessages']}'),
                  trailing: Text(
                      conversation['lastMessageDate']?.substring(0, 10) ?? ''),
                  onTap: () {
                    setState(() {
                      _selectedChatId = conversation['chatId'];
                      _fetchMessages();
                    });
                  },
                  selected: _selectedChatId == conversation['chatId'],
                );
              },
            ),
          ),
          // Main chat area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return ListTile(
                          title: Text(message['message'] ?? ''),
                          subtitle:
                              Text('From: ${message['username'] ?? 'Unknown'}'),
                        );
                      },
                    ),
                  ),
                  Form(
                    child: TextFormField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Send a message',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ),
    );
  }
}

class Message {}