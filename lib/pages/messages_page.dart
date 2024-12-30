import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import '../app/app_state.dart';
import '../services/openid_client.dart';
import '../app/stomp_client_notifier.dart';

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late StompClient _stompClient;
  final TextEditingController _controller = TextEditingController();
  final String _host = FlavorConfig.instance.variables['beHost'];

  List<Map<String, dynamic>> _conversations = [];
  String? _selectedChatId;
  List<Map<String, dynamic>> _messages = [];
  bool _showMessagesOnly = false;
  late StompClientNotifier stompProvider;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _newConnectStompClient();
  }

  Future<void> _fetchConversations() async {
    try {
      final httpClient = await getAccessTokenHttpClient();
      if (httpClient == null) {
        print('HTTP client is null. Authentication might have failed.');
        return;
      }

      final response =
          await httpClient.get(Uri.parse('http://$_host/v1/message-report'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['content'] as List;
        setState(() {
          _conversations = data
              .map((item) => {
                    'chatId': item['chatId'],
                    'chatName': item['chatName'],
                    'countUnreadMessages': item['countUnreadMessages'],
                    'lastMessage': item['lastMessage'],
                    'lastMessageDate': item['lastMessageDate'],
                  })
              .toList();
        });
      } else {
        print('Request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    }
  }

  void _newConnectStompClient() {
    stompProvider = Provider.of<StompClientNotifier>(context, listen: false);
    stompProvider.connectStompClient();
    stompProvider.addListener(() {
      setState(() {
        final message = jsonDecode(stompProvider.message);
        _messages.add(message);
      });
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final httpClient = await getAccessTokenHttpClient();
      if (httpClient == null) {
        print('HTTP client is null. Authentication might have failed.');
        return;
      }
      final response = await httpClient
          .get(Uri.parse('http://$_host/v1/chat/$_selectedChatId/message'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['content'] as List;
        setState(() {
          _messages = data
              .map((item) => {
                    'messageId': item['messageId'],
                    'userId': item['userId'],
                    'username': item['username'],
                    'chatId': item['chatId'],
                    'message': item['message'],
                  })
              .toList();
        });
      } else {
        print('Request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _selectedChatId != null) {
      final message = {"chatId": _selectedChatId, "message": _controller.text};

      stompProvider.send(
        destination: '/app/v1/send-message',
        message: message,
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

  String calculateConversationDate(String? conversationDateFromMessage) {
    if (conversationDateFromMessage == null) return '';
    DateTime conversationDate;
    try {
      conversationDate = DateTime.parse(conversationDateFromMessage);
    } catch (e) {
      return 'Invalid date';
    }

    DateTime now = DateTime.now();
    if (conversationDate.year == now.year &&
        conversationDate.month == now.month &&
        conversationDate.day == now.day) {
      return DateFormat.Hm().format(conversationDate);
    }

    DateTime yesterday = now.subtract(Duration(days: 1));
    if (conversationDate.year == yesterday.year &&
        conversationDate.month == yesterday.month &&
        conversationDate.day == yesterday.day) {
      return 'yesterday';
    }

    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    if (conversationDate.isAfter(startOfWeek)) {
      return DateFormat('EEEE').format(conversationDate);
    }

    return DateFormat('dd.MM.yyyy').format(conversationDate);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text("Messages"),
        leading: _showMessagesOnly
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showMessagesOnly = false;
                  });
                },
              )
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            return _showMessagesOnly
                ? _buildMessagesView(colorScheme)
                : _buildConversationsView(colorScheme);
          } else {
            return Row(
              children: [
                Container(
                  width: 300,
                  color: colorScheme.surfaceContainerHighest,
                  child: _buildConversationsView(colorScheme),
                ),
                Expanded(child: _buildMessagesView(colorScheme)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildConversationsView(ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final countUnreadMessages = conversation['countUnreadMessages'] ?? 0;

        return Card(
          color: colorScheme.surface,
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.person, color: colorScheme.onPrimary),
                ),
                if (countUnreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$countUnreadMessages',
                        style: TextStyle(color: colorScheme.onError),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              conversation['chatName'] ?? 'No name',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              conversation['lastMessage'] ?? 'No message',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            onTap: () {
              setState(() {
                _selectedChatId = conversation['chatId'];
                _fetchMessages();
                _showMessagesOnly = true;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMessagesView(ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        color: colorScheme.onInverseSurface, // Фон для всей области сообщений
        child: Column(
          children: [
            Expanded(
              child: _messages.isNotEmpty
                  ? ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isCurrentUser = message['userId'] ==
                            Provider.of<AppState>(context).userInfo!.subject;

                        return Container(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message['message'] ?? '',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Send a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
