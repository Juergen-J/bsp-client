import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../service/auth_service.dart';

class MessagesProvider extends ChangeNotifier {
  // Сервис авторизации, откуда возьмём Dio и информацию об авторизации
  AuthService _authService;

  Dio get _dio => _authService.dio;

  // Списки данных
  List<Map<String, dynamic>> _conversations = [];

  List<Map<String, dynamic>> get conversations => _conversations;

  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  // Для «пагинации» или других параметров
  int _messagePage = 0;

  int get messagePage => _messagePage;

  String? _selectedChatId;

  String? get selectedChatId => _selectedChatId;

  // Конструктор пустой, т.к. мы свяжем провайдер с AuthService через ProxyProvider
  MessagesProvider(this._authService);

  bool get isLoggedIn => _authService.isLoggedIn;

  /// Сбрасываем все данные (вызывается при логауте)
  void clear() {
    _conversations.clear();
    _messages.clear();
    _selectedChatId = null;
    _messagePage = 0;
    notifyListeners();
  }

  // Пример: загрузить список конверсий
  Future<void> fetchConversations() async {
    if (!isLoggedIn) return; // если не залогинен - ничего не делаем
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
        // Для первой загрузки (страница 0) заменяем список:
        if (_messagePage == 0) {
          _messages = [];
        }
        // Добавляем в начало или в конец в зависимости от вашей логики
        // Предположим, вы добавляете «сверху» при пролистывании вверх:
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
