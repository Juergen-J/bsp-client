import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
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
  BuildContext? _listViewContext;
  late StompClient _stompClient;
  final ScrollController _scrollControllerMessage = ScrollController();
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

  Future<void> _markAsViewed(String? chatId, List<String> messageIds) async {
    try {
      final httpClient = await getAccessTokenHttpClient();
      if (httpClient == null) {
        print('HTTP client is null. Authentication might have failed.');
        return;
      }

      final response = await httpClient.put(
          Uri.parse('http://$_host/v1/chat/$chatId/message/mark-as-viewed'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(messageIds));
      if (response.statusCode == 204) {
      } else {
        print('Error : $response');
      }
    } catch (e) {
      print('Error marked messages as viewed: $e');
    }
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
        print('Data: $data');
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
      print('Message added: ${stompProvider.message}');
      setState(() {
        final message = jsonDecode(stompProvider.message);
        _messages.add(message);

        if (message['userId'] == stompProvider.userId) {
          _scrollDownChat();
        }
        _fetchConversations();
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
                    'status': item['status'],
                  })
              .toList();
          _scrollDownChat();
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

  void _scrollDownChat() {
    WidgetsBinding.instance
        .addPostFrameCallback((_){
      if (_scrollControllerMessage.hasClients) {
        _scrollControllerMessage.animateTo(
          _scrollControllerMessage.position.maxScrollExtent,
          duration: Duration(microseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _controller.dispose();
    _scrollControllerMessage.dispose();
    super.dispose();
  }

  String calculateConversationDate(String? conversationDateFromMessage) {
    if (conversationDateFromMessage == null) {
      return '';
    }
    DateTime conversationDate;
    try {
      conversationDate = DateTime.parse(conversationDateFromMessage);
    } catch (e) {
      return 'Error by date parse';
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
      return DateFormat('EEEE', 'en_EN').format(conversationDate);
    }

    return DateFormat('dd.MM.yyyy').format(conversationDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            if (_showMessagesOnly) {
              return _buildMessagesView();
            } else {
              return _buildConversationsView();
            }
          } else {
            return Row(
              children: [
                Container(
                  width: 300,
                  color: Colors.grey[200],
                  child: _buildConversationsView(),
                ),
                Expanded(child: _buildMessagesView()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildConversationsView() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final countUnreadMessages = conversation['countUnreadMessages'] ?? 0;
        return MouseRegion(
          onEnter: (_) => setState(() {}),
          onExit: (_) => setState(() {}),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Stack(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[700],
                  ),
                ),
                if (countUnreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12)),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        countUnreadMessages.toString(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ]),
              title: Text(
                conversation['chatName'] ?? 'No name',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(conversation['lastMessage'] ?? 'No message'),
              trailing: Text(
                  calculateConversationDate(conversation['lastMessageDate'])),
              onTap: () {
                setState(() {
                  _selectedChatId = conversation['chatId'];
                  _fetchMessages();
                  _showMessagesOnly = true;
                });
              },
              selected: _selectedChatId == conversation['chatId'],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListViewObserver(
            onObserve: (resultMap) {
              List<String> unreadMessagesId = [];
              var items = resultMap.displayingChildModelList;
              for (var item in items) {
                if (_messages[item.index]["status"] == "CREATED") {
                  unreadMessagesId.add(_messages[item.index]["messageId"]);
                  _messages[item.index]["status"] = "VIEWED";
                }
              }
              if (unreadMessagesId.isNotEmpty) {
                _markAsViewed(_selectedChatId, unreadMessagesId);
                _fetchConversations();
              }
            },
            child: ListView.builder(
              controller: _scrollControllerMessage,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                _listViewContext = context;
                var userInfo = Provider.of<AppState>(context).userInfo;
                final message = _messages[index];
                final isCurrentUser = message['userId'] == userInfo!.subject;
                return Container(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['message'] ?? '',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
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
    );
  }
}
