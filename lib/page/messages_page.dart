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
  bool _isScrollAnimating = false;


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
    if (stompProvider.stompClient == null || !stompProvider.isConnected) {
      stompProvider.connectStompClient();
    }
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

      if (stompProvider.userStatus.isNotEmpty) {
        final userStatus = jsonDecode(stompProvider.userStatus);
        final userId = userStatus['userId'];
        final chatId = userStatus['chatId'];
        final status = userStatus['status'];

        final isOnline = status == 'ONLINE';
        messagesProv.updateUserOnlineStatus(userId, chatId, isOnline);

      }

      if (stompProvider.report.isNotEmpty) {
        final report = jsonDecode(stompProvider.report);
        messagesProv.fetchConversations();
      }
    });
  }

  void _scrollMessageListener() async {
    final scrollPos = _scrollControllerMessage.position;
    final messagesProv = context.read<MessagesProvider>();

    if (_isScrollAnimating) return;

    if (scrollPos.pixels >= scrollPos.maxScrollExtent - 150 &&
        !messagesProv.isLoadingMessages &&
        messagesProv.hasMoreMessages) {

      final prevExtentAfter = scrollPos.extentAfter;
      final oldMessageCount = messagesProv.messages.length;

      _isScrollAnimating = true;

      await messagesProv.loadMoreMessages();

      final newMessageCount = messagesProv.messages.length;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (newMessageCount == oldMessageCount) {
          _isScrollAnimating = false;
          return;
        }

        final newExtentAfter = _scrollControllerMessage.position.extentAfter;
        final offsetDiff = newExtentAfter - prevExtentAfter;
        final newOffset = _scrollControllerMessage.offset + offsetDiff;

        if (_scrollControllerMessage.hasClients) {
          await _scrollControllerMessage.animateTo(
            newOffset,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }

        _isScrollAnimating = false;
      });
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
          0,
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
        toolbarHeight: 56,
        leading: _showMessagesOnly
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  final messagesProv = context.read<MessagesProvider>();
                  messagesProv.resetActiveChat();
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
                    Container(
                      width: 1,
                      color: Colors.grey[300],
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
    final messagesProv = context.watch<MessagesProvider>();
    final conversations = messagesProv.conversations;
    final selectedChatId = messagesProv.selectedChatId;

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final countUnreadMessages = conversation['countUnreadMessages'] ?? 0;
        final chatId = conversation['chatId'];
        final isSelected = chatId == selectedChatId;
        final isOnline = conversation['isOnline'] == true;
        final bgColor = isSelected ? colorScheme.onSecondaryFixed : colorScheme.surface;
        final infoColor = isSelected ? colorScheme.surface : colorScheme.onSecondaryFixed;
        final avatarBgColor = isSelected ? colorScheme.surface : colorScheme.onSecondaryFixed;
        final avatarColor = isSelected ? colorScheme.onSecondaryFixed : colorScheme.surface;

        return Card(
          color: bgColor,
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
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: avatarBgColor,
                        child: Icon(
                          Icons.person,
                          color: avatarColor,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isOnline ? colorScheme.primary : colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOnline ? colorScheme.surface : colorScheme.primary,
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                      if (countUnreadMessages > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$countUnreadMessages',
                              style: TextStyle(
                                color: colorScheme.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          conversation['lastMessage'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: infoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    calculateConversationDate(conversation['lastMessageDate']),
                    style: TextStyle(
                      color: infoColor,
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
    final selectedChatId = messagesProv.selectedChatId;
    final messages = messagesProv.messages;
    final userInfo = Provider.of<AuthService>(context, listen: false).getUserInfo();
    if (selectedChatId == null) {
      return Center(
        child: Text(
          'Bitte wählen Sie einen Chat aus',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
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
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        _listViewContext = context;
                        final message = messages[index];
                        final isCurrentUser = message['userId'] == userInfo?.id;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: colorScheme.surfaceVariant,
                                        child: Icon(Icons.person, size: 16, color: colorScheme.onSecondaryFixed),
                                      ),
                                    ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? colorScheme.secondary
                                            : colorScheme.onSecondaryFixed,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        message['message'] ?? '',
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Nachricht schreiben...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
