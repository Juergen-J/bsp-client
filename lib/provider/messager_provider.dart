import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../service/auth_service.dart';

class MessagesProvider extends ChangeNotifier {
  final AuthService _authService;

  MessagesProvider(this._authService);

  Dio get _dio => _authService.dio;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  int _messagePage = 0;
  int get messagePage => _messagePage;

  String? _selectedChatId;
  String? get selectedChatId => _selectedChatId;

  bool get isLoggedIn => _authService.isLoggedIn;

  bool _isLoadingMessages = false;
  bool _hasMoreMessages = true;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMessages => _isLoadingMessages;

  void clear() {
    _conversations.clear();
    _messages.clear();
    _selectedChatId = null;
    _messagePage = 0;
    _isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> fetchConversations() async {
    if (!isLoggedIn) return;
    try {
      final response =
          await _dio!.get('http://localhost:8090/v1/message-report');
      if (response.statusCode == 200) {
        final jsonData = response.data;
        final data = jsonData['content'] as List;
        _conversations = data
            .map((item) => {
                  'chatId': item['chatId'],
                  'chatName': item['chatName'],
                  'countUnreadMessages': item['countUnreadMessages'],
                  'lastMessage': item['lastMessage'],
                  'lastMessageDate': item['lastMessageDate'],
                })
            .toList();
      } else {
        if (kDebugMode) {
          print('fetchConversations: status code ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('fetchConversations error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> fetchMessages() async {
    if (!isLoggedIn || _selectedChatId == null || _isLoadingMessages || !_hasMoreMessages) return;

    _isLoadingMessages = true;

    try {
      final response = await _dio.get(
        'http://localhost:8090/v1/chat/$_selectedChatId/message?page=$_messagePage',
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        final data = jsonData['content'] as List;

        if (_messagePage == 0) {
          _messages = [];
        }

        final messages = data.map((item) => {
          'messageId': item['messageId'],
          'userId': item['userId'],
          'username': item['username'],
          'chatId': item['chatId'],
          'message': item['message'],
          'status': item['status'],
        }).toList();

        _messages.addAll(messages);
        if (jsonData['last'] == true || messages.isEmpty) {
          _hasMoreMessages = false;
        }
      } else {
        if (kDebugMode) {
          print('fetchMessages: status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('fetchMessages error: $e');
      }
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void selectChat(String chatId) {
    _selectedChatId = chatId;
    _messages.clear();
    _messagePage = 0;
    _hasMoreMessages = true;
    notifyListeners();
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMessages || !_hasMoreMessages) return;
    _messagePage++;
    print('Loading more messages, page: $_messagePage');
    await fetchMessages();
  }

  Future<void> markAsViewed(List<String> messageIds) async {
    if (!isLoggedIn || _selectedChatId == null) return;
    try {
      final response = await _dio.put(
        'http://localhost:8090/v1/chat/$_selectedChatId/message/mark-as-viewed',
        data: messageIds,
      );
      if (response.statusCode != 204) {
        print('Error markAsViewed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error markAsViewed: $e');
    }
  }

  void addMessage(Map<String, dynamic> message) {
    _messages.insert(0, message);
    notifyListeners();
  }
}
