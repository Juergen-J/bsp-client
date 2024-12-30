import 'package:flutter/material.dart';
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
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  BuildContext? _listViewContext;
  late StompClient _stompClient;
  final ScrollController _scrollControllerMessage = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final String _host = FlavorConfig.instance.variables['beHost'];

  List<Map<String, dynamic>> _conversations = [];
  String? _selectedChatId;
  List<Map<String, dynamic>> _messages = [];
  int _messagePage = 0;
  bool _showMessagesOnly = false;
  late StompClientNotifier stompProvider;

  @override
  void initState() {
    super.initState();
    _scrollControllerMessage.addListener(_scrollMessageListener);
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

  void _scrollMessageListener() {
    if (_scrollControllerMessage.position.pixels == _scrollControllerMessage.position.minScrollExtent) {
      _messagePage = _messagePage + 1;
      _fetchMessages();
    }
  }

  void _newConnectStompClient() {
    stompProvider = Provider.of<StompClientNotifier>(context, listen: false);
    stompProvider.connectStompClient();
    stompProvider.addListener(() {
      print('Message added: ${stompProvider.message}');
      print('Report added: ${stompProvider.report}');
      setState(() {
        if (stompProvider.message != '') {
          final message = jsonDecode(stompProvider.message);
          _messages.add(message);

          if (message['userId'] == stompProvider.userId) {
            _scrollDownChat();
          }
          _fetchConversations();
          _runManualListObserve();
        }
        if (stompProvider.report != '') {
          final report = jsonDecode(stompProvider.report);
          _fetchConversations();
        }

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
          .get(Uri.parse('http://$_host/v1/chat/$_selectedChatId/message?page=$_messagePage'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['content'] as List;
        setState(() {
          for(final item in data){
            _messages.insert(0, {
              'messageId': item['messageId'],
              'userId': item['userId'],
              'username': item['username'],
              'chatId': item['chatId'],
              'message': item['message'],
              'status': item['status'],
            });
          }
          if (_messagePage == 0) {
            _scrollDownChat();
          }
          _runManualListObserve();
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

  void _runManualListObserve() {
    WidgetsBinding.instance
        .addPostFrameCallback((_){
          print("attempt ${DateTime.now()}");
      ListViewOnceObserveNotification().dispatch(_listViewContext);
    });
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _controller.dispose();
    _scrollControllerMessage.removeListener(_scrollMessageListener);
    _scrollControllerMessage.dispose();
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
                _messages = [];
                  _messagePage = 0;_fetchMessages();
                _showMessagesOnly = true;
              });
            },
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
              print("observe ${DateTime.now()}");
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
