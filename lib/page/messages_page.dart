import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';
import '../app/stomp_client_notifier.dart';
import '../provider/messager_provider.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  BuildContext? _listViewContext;
  late StompClient? _stompClient;
  final ScrollController _scrollControllerMessage = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showMessagesOnly = false;

  late StompClientNotifier stompProvider;
  late final Future<bool> _loginCheckFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    stompProvider = Provider.of<StompClientNotifier>(context, listen: false);

    if (stompProvider.stompClient == null || !stompProvider.isConnected) {
      stompProvider.connectStompClient();
    }
  }

  @override
  void initState() {
    super.initState();
    _loginCheckFuture = requireLoginIfNeeded(context);
    _scrollControllerMessage.addListener(_scrollMessageListener);

    stompProvider = Provider.of<StompClientNotifier>(context, listen: false);
    stompProvider.connectStompClient();
    stompProvider.addListener(() {
      final messagesProv = context.read<MessagesProvider>();

      if (stompProvider.message.isNotEmpty) {
        final messageMap = jsonDecode(stompProvider.message);
        messagesProv.addMessage(messageMap);

        if (messageMap['userId'] == stompProvider.userId) {
          _scrollDownChat();
        }

        messagesProv.fetchConversations();
        _runManualListObserve();
      }

      if (stompProvider.report.isNotEmpty) {
        final report = jsonDecode(stompProvider.report);
        messagesProv.fetchConversations();
      }
    });
  }

  void _scrollMessageListener() {
    if (_scrollControllerMessage.position.pixels ==
        _scrollControllerMessage.position.minScrollExtent) {
      context.read<MessagesProvider>().loadMoreMessages();
    }
  }

  void _sendMessage() {
    final messagesProv = context.read<MessagesProvider>();
    if (_controller.text.isNotEmpty && messagesProv.selectedChatId != null) {
      final message = {
        "chatId": messagesProv.selectedChatId,
        "message": _controller.text
      };
      stompProvider.send(
        destination: '/app/v1/send-message',
        message: message,
      );
      _controller.clear();
    }
  }

  void _scrollDownChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollControllerMessage.hasClients) {
        _scrollControllerMessage.animateTo(
          _scrollControllerMessage.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _runManualListObserve() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ListViewOnceObserveNotification().dispatch(_listViewContext);
    });
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _controller.dispose();
    _searchController.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 110,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nachrichten"),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nachricht finden',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ],
        ),
        leading: _showMessagesOnly
            ? IconButton(
                icon: Icon(Icons.arrow_back),
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
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000),
                child: Row(
                  children: [
                    Container(
                      width: 300,
                      color: colorScheme.surfaceContainerHighest,
                      child: _buildConversationsView(colorScheme),
                    ),
                    Expanded(child: _buildMessagesView(colorScheme)),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildConversationsView(ColorScheme colorScheme) {
    final messagesProv = context.watch<MessagesProvider>();
    final conversations = messagesProv.conversations;

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final countUnreadMessages = conversation['countUnreadMessages'] ?? 0;

        return Card(
          color: colorScheme.surface,
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: () {
              final msgProv = context.read<MessagesProvider>();
              msgProv.selectChat(conversation['chatId']);
              msgProv.fetchMessages();

              setState(() {
                _showMessagesOnly = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        child: Icon(Icons.person, color: colorScheme.onPrimary),
                      ),
                      if (countUnreadMessages > 0)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation['chatName'] ?? 'No name',
                          style: TextStyle(
                            fontWeight: countUnreadMessages > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          conversation['lastMessage'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    calculateConversationDate(conversation['lastMessageDate']),
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesView(ColorScheme colorScheme) {
    final messagesProv = context.watch<MessagesProvider>();
    final messages = messagesProv.messages;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondaryContainer,
                  colorScheme.surface,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: ListViewObserver(
              onObserve: (resultMap) {
                List<String> unreadMessagesId = [];
                var items = resultMap.displayingChildModelList;
                for (var item in items) {
                  if (messages[item.index]["status"] == "CREATED") {
                    unreadMessagesId.add(messages[item.index]["messageId"]);
                    messages[item.index]["status"] = "VIEWED";
                  }
                }
                if (unreadMessagesId.isNotEmpty) {
                  messagesProv.markAsViewed(unreadMessagesId);
                  messagesProv.fetchConversations();
                }
              },
              child: messages.isNotEmpty
                  ? ListView.builder(
                      controller: _scrollControllerMessage,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        _listViewContext = context;
                        final userInfo =
                            Provider.of<AuthService>(context).getUserInfo();
                        final message = messages[index];
                        final isCurrentUser = message['userId'] == userInfo?.id;

                        return Container(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(
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
