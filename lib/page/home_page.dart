import 'dart:async';

import 'package:berlin_service_portal/model/service/user_service_full_dto.dart';
import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/router.dart' show homeSearchQuery, homeSelectedCategoryId;
import '../model/service/user_service_short_dto.dart';
import '../provider/messager_provider.dart';
import '../widgets/cards/service_full_detail_card.dart';
import '../widgets/services_grid.dart';

class HomePage extends StatefulWidget {
  final String? selectedServiceId;

  const HomePage({super.key, this.selectedServiceId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CancelToken? _cancelToken;
  CancelToken? _detailsCancelToken;
  bool _mounted = true;
  String? _currentDetailsRequestId;

  void _safeSetState(VoidCallback fn) {
    if (!_mounted) return;
    if (mounted) setState(fn);
  }

  final List<UserServiceShortDto> _results = [];
  bool _loading = false;
  String? _error;

  String? _selectedServiceId;
  UserServiceFullDto? _selectedServiceFull;
  bool _loadingDetails = false;
  String? _detailsError;

  // пагинация
  int _page = 0;
  final int _size = 20;
  bool _last = true;

  // дебаунс поиска
  Timer? _debounce;

  late VoidCallback _searchListener;
  late VoidCallback _categoryListener;

  @override
  void initState() {
    super.initState();
    _searchListener = () => _onQueryChanged(homeSearchQuery.value);
    _categoryListener = () => _triggerSearch(reset: true);

    homeSearchQuery.addListener(_searchListener);
    homeSelectedCategoryId.addListener(_categoryListener);

    // если категория уже выбрана AppBar’ом — сразу грузим
    _triggerSearch(reset: true);

    final initialServiceId = widget.selectedServiceId;
    if (initialServiceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectServiceById(initialServiceId);
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _cancelToken?.cancel('dispose');
    _detailsCancelToken?.cancel('dispose');
    homeSearchQuery.removeListener(_searchListener);
    homeSelectedCategoryId.removeListener(_categoryListener);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = widget.selectedServiceId;
    final oldId = oldWidget.selectedServiceId;

    if (newId == oldId) return;

    if (newId == null) {
      _clearSelectedServiceState();
    } else if (newId != _selectedServiceId) {
      _selectServiceById(newId);
    }
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _triggerSearch(reset: true);
    });
  }

  Future<void> _triggerSearch({bool reset = false}) async {
    final categoryId = homeSelectedCategoryId.value;
    if (categoryId == null) return;

    // отменяем предыдущий запрос
    _cancelToken?.cancel('new-request');
    _cancelToken = CancelToken();

    if (reset) {
      _safeSetState(() {
        _page = 0;
        _last = true;
        _results.clear();
      });
    }

    _safeSetState(() {
      _loading = true;
      _error = null;
    });

    final dio = Provider.of<AuthService>(context, listen: false).dio;

    try {
      final resp = await dio.post(
        '/v1/service/search',
        queryParameters: {'page': _page, 'size': _size},
        data: {
          'serviceTypeId': categoryId,
          'searchValue': homeSearchQuery.value,
        },
        cancelToken: _cancelToken,
      );

      if (resp.statusCode == 200 && resp.data['content'] != null) {
        final items = (resp.data['content'] as List)
            .map((e) => UserServiceShortDto.fromJson(e))
            .toList();

        _safeSetState(() {
          _results.addAll(items);
          _last = (resp.data['last'] as bool?) ?? true;
          _loading = false;
        });
      } else {
        throw Exception('Bad response: ${resp.statusCode}');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // тихо игнорим отменённый запрос
        return;
      }
      _safeSetState(() {
        _loading = false;
        _error = 'Network error: ${e.message}';
      });
    } catch (e) {
      _safeSetState(() {
        _loading = false;
        _error = 'Failed to load services: $e';
      });
    }
  }

  Future<void> _selectServiceById(String id) async {
    _detailsCancelToken?.cancel('new-request');
    final detailsToken = CancelToken();
    _detailsCancelToken = detailsToken;
    _currentDetailsRequestId = id;

    _safeSetState(() {
      _selectedServiceId = id;
      _loadingDetails = true;
      _detailsError = null;
      _selectedServiceFull = null;
    });

    final dio = Provider.of<AuthService>(context, listen: false).dio;

    try {
      final resp = await dio.get('/v1/service/$id', cancelToken: detailsToken);
      if (_currentDetailsRequestId != id) return;
      if (resp.statusCode == 200 && resp.data != null) {
        _safeSetState(() {
          _selectedServiceFull =
              UserServiceFullDto.fromJson(resp.data as Map<String, dynamic>);
          _loadingDetails = false;
        });
      } else {
        throw Exception('Bad response: ${resp.statusCode}');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (_currentDetailsRequestId != id) return;
      _safeSetState(() {
        _loadingDetails = false;
        _detailsError = 'Network error: ${e.message}';
      });
    } catch (e) {
      if (_currentDetailsRequestId != id) return;
      _safeSetState(() {
        _loadingDetails = false;
        _detailsError = 'Failed to load service: $e';
      });
    }
  }

  void _openServiceDetails(UserServiceShortDto service) {
    _selectServiceById(service.id);
    final router = GoRouter.of(context);
    final target = '/service/${service.id}';
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath != target) {
      router.go(target);
    }
  }

  void _clearSelectedService() {
    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    _clearSelectedServiceState();
    if (currentPath != '/home') {
      router.go('/home');
    }
  }

  void _clearSelectedServiceState() {
    _detailsCancelToken?.cancel('clear');
    _detailsCancelToken = null;
    _currentDetailsRequestId = null;

    _safeSetState(() {
      _selectedServiceId = null;
      _selectedServiceFull = null;
      _loadingDetails = false;
      _detailsError = null;
    });
  }

  void _retryLoadSelectedService() {
    final id = _selectedServiceId ?? widget.selectedServiceId;
    if (id == null) {
      _clearSelectedService();
      return;
    }
    _selectServiceById(id);
  }

  void _triggerConversationForOwner(String ownerUserId) {
    unawaited(_startConversationWith(ownerUserId));
  }

  Future<void> _startConversationWith(String ownerUserId) async {
    final loggedIn = await requireLoginIfNeeded(context);
    if (!mounted || !loggedIn) return;

    final auth = context.read<AuthService>();
    final currentUserId = auth.getUserInfo()?.id;
    if (currentUserId != null && currentUserId == ownerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message your own service.')),
      );
      return;
    }

    final messagesProv = context.read<MessagesProvider>();

    try {
      await auth.ensureTokenIsFresh();
      final response = await auth.dio.post(
        '/v1/chat',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: [ownerUserId],
      );

      final chatId = _extractChatId(response.data);
      await messagesProv.fetchConversations();
      if (chatId != null) {
        messagesProv.selectChat(chatId);
        await messagesProv.fetchMessages();
      }

      if (!mounted) return;
      GoRouter.of(context).go('/messages');
    } on DioException catch (e) {
      final chatId = _extractChatId(e.response?.data);
      await messagesProv.fetchConversations();

      if (chatId != null) {
        messagesProv.selectChat(chatId);
        await messagesProv.fetchMessages();
        if (mounted) {
          GoRouter.of(context).go('/messages');
        }
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_describeChatError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start conversation.')),
      );
    }
  }

  String _describeChatError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Unable to start conversation.';
      case 401:
        return 'Please log in to continue.';
      case 404:
        return 'Service owner not found.';
      case 409:
        return 'Conversation already exists.';
      default:
        return 'Failed to start conversation. Please try again later.';
    }
  }

  String? _extractChatId(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String) {
          final normalized = key.toLowerCase();
          if (normalized == 'chatid' || normalized == 'chat_id') {
            final text = value?.toString();
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        }
      }
      for (final value in raw.values) {
        final nested = _extractChatId(value);
        if (nested != null) return nested;
      }
    } else if (raw is Iterable) {
      for (final item in raw) {
        final nested = _extractChatId(item);
        if (nested != null) return nested;
      }
    } else if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.contains(' ')) return null;
      if (RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],

          // верхний индикатор при первом лоаде
          if (_loading && _results.isEmpty) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],

          if (_selectedServiceId == null) ...[
            // сетка или пустое состояние
            if (_results.isEmpty && !_loading)
              SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Nothing found',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ServicesGrid(
                services: _results,
                onTap: _openServiceDetails,
                onMessage: (s) => _triggerConversationForOwner(s.userId),
                onFavorite: (s) => _triggerConversationForOwner(s.userId),
              ),

            const SizedBox(height: 12),

            // нижний индикатор при догрузке + кнопка Load more
            if (!_last) ...[
              if (_loading && _results.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(),
                ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 220,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                    onPressed: _loading
                        ? null
                        : () {
                            _safeSetState(() => _page += 1);
                            _triggerSearch(reset: false);
                          },
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            if (_loadingDetails)
              const Center(child: CircularProgressIndicator())
            else if (_detailsError != null)
              Column(
                children: [
                  Text(
                    _detailsError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: _clearSelectedService,
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _retryLoadSelectedService,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ],
              )
            else if (_selectedServiceFull != null)
              SingleChildScrollView(
                child: ServiceFullDetailCard(
                  full: _selectedServiceFull!,
                  priceUnit: 'VB',
                  onClose: _clearSelectedService,
                  onMessage: () => _triggerConversationForOwner(
                      _selectedServiceFull!.userId),
                  onFavorite: () => _triggerConversationForOwner(
                      _selectedServiceFull!.userId),
                ),
              )
            else
              const SizedBox.shrink(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
