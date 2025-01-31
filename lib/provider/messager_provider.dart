import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../service/auth_service.dart';

class MessagesProvider extends ChangeNotifier {
  AuthService _authService;

  Dio get _dio => _authService.dio;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  int _messagePage = 0;
  int get messagePage => _messagePage;

  String? _selectedChatId;
  String? get selectedChatId => _selectedChatId;

  MessagesProvider(this._authService);

  bool get isLoggedIn => _authService.isLoggedIn;

  void clear() {
    _conversations.clear();
    _messages.clear();
    _selectedChatId = null;
    _messagePage = 0;
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
    if (!isLoggedIn || _selectedChatId == null) return;
    try {
      final response = await _dio.get(
          'http://localhost:8090/v1/chat/$_selectedChatId/message?page=$_messagePage');
      if (response.statusCode == 200) {
        final jsonData = response.data;
        final data = jsonData['content'] as List;
        if (_messagePage == 0) {
          _messages = [];
        }
        _messages.insertAll(
            0,
            data.map((item) => {
                  'messageId': item['messageId'],
                  'userId': item['userId'],
                  'username': item['username'],
                  'chatId': item['chatId'],
                  'message': item['message'],
                  'status': item['status'],
                }));
      } else {
        if (kDebugMode) {
          print('fetchMessages: status ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('fetchMessages error: $e');
      }
    }
    notifyListeners();
  }

  void selectChat(String chatId) {
    _selectedChatId = chatId;
    _messages.clear();
    _messagePage = 0;
    notifyListeners();
  }

  Future<void> loadMoreMessages() async {
    _messagePage++;
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
    _messages.add(message);
    notifyListeners();
  }
}
