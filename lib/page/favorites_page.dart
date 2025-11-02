import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/service/user_service_short_dto.dart';
import '../provider/messager_provider.dart';
import '../service/auth_service.dart';
import '../service/favorite_service.dart';
import '../widgets/services_grid.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final List<UserServiceShortDto> _favorites = [];
  final Set<String> _favoriteMutations = {};
  final int _size = 20;

  FavoriteService? _favoriteService;
  CancelToken? _cancelToken;
  bool _loading = false;
  String? _error;
  int _page = 0;
  bool _last = true;
  bool _ignoreNextFavoriteEvent = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<FavoriteService>();
    if (!identical(_favoriteService, service)) {
      _favoriteService?.removeListener(_handleFavoritesChanged);
      _favoriteService = service;
      _favoriteService?.addListener(_handleFavoritesChanged);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    _favoriteService?.removeListener(_handleFavoritesChanged);
    super.dispose();
  }

  Future<void> _loadFavorites({required bool reset}) async {
    final auth = context.read<AuthService>();

    if (!auth.isLoggedIn) {
      final loggedIn = await requireLoginIfNeeded(context);
      if (!mounted || !loggedIn) {
        _safeSetState(() {
          _loading = false;
          _error = 'Login required to view favorites.';
          _favorites.clear();
        });
        return;
      }
    }

    _cancelToken?.cancel('new-request');
    final requestToken = CancelToken();
    _cancelToken = requestToken;

    if (reset) {
      _safeSetState(() {
        _page = 0;
        _last = true;
        _favorites.clear();
      });
    }

    _safeSetState(() {
      _loading = true;
      _error = null;
    });

    try {
      await auth.ensureTokenIsFresh();
      final response = await auth.dio.get(
        '/v1/service/favorites',
        queryParameters: {'page': _page, 'size': _size},
        cancelToken: requestToken,
      );

      if (!mounted || requestToken.isCancelled) return;

      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final content = data['content'];
        if (content is List) {
          final items = content
              .map(
                (e) => UserServiceShortDto.fromJson(e as Map<String, dynamic>),
              )
              .toList();

          _safeSetState(() {
            _favorites.addAll(items);
            _last = (data['last'] as bool?) ?? true;
            _loading = false;
          });
          return;
        }
      }

      throw Exception('Unexpected response structure');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _safeSetState(() {
        _loading = false;
        _error = 'Network error: ${e.message}';
      });
    } catch (e) {
      _safeSetState(() {
        _loading = false;
        _error = 'Failed to load favorites: $e';
      });
    }
  }

  Future<void> _toggleFavorite(UserServiceShortDto service) async {
    if (_favoriteMutations.contains(service.id)) return;

    final loggedIn = await requireLoginIfNeeded(context);
    if (!mounted || !loggedIn) return;

    final index = _favorites.indexWhere((s) => s.id == service.id);
    if (index == -1) return;

    final auth = context.read<AuthService>();
    final favorites = context.read<FavoriteService>();
    final previous = _favorites[index];
    final nextFavorite = !previous.favorite;

    _favoriteMutations.add(service.id);

    if (nextFavorite) {
      _safeSetState(() {
        _favorites[index] = previous.copyWith(favorite: true);
      });
    } else {
      _safeSetState(() {
        _favorites.removeAt(index);
      });
    }

    try {
      await auth.ensureTokenIsFresh();
      _ignoreNextFavoriteEvent = true;
      if (nextFavorite) {
        await favorites.addFavorite(service.id);
      } else {
        await favorites.removeFavorite(service.id);
      }
    } on DioException catch (e) {
      _safeSetState(() {
        if (nextFavorite) {
          if (index < _favorites.length && _favorites[index].id == service.id) {
            _favorites[index] = _favorites[index].copyWith(
              favorite: !nextFavorite,
            );
          }
        } else {
          _favorites.insert(index, previous);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_favoriteErrorMessage(e, nextFavorite))),
        );
      }
    } catch (_) {
      _safeSetState(() {
        if (nextFavorite) {
          if (index < _favorites.length && _favorites[index].id == service.id) {
            _favorites[index] = _favorites[index].copyWith(
              favorite: !nextFavorite,
            );
          }
        } else {
          _favorites.insert(index, previous);
        }
      });

      if (mounted) {
        const snackBar = SnackBar(
          content: Text('Failed to update favorites. Please try again later.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } finally {
      _ignoreNextFavoriteEvent = false;
      _favoriteMutations.remove(service.id);
    }
  }

  void _openServiceDetails(UserServiceShortDto service) {
    GoRouter.of(context).go('/service/${service.id}');
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
      if (!mounted) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_describeChatError(e))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start conversation.')),
      );
    }
  }

  String _favoriteErrorMessage(DioException e, bool attemptedFavorite) {
    final action = attemptedFavorite
        ? 'add to favorites'
        : 'remove from favorites';
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Unable to $action.';
      case 401:
        return 'Please log in to manage favorites.';
      case 404:
        return 'Service not found.';
      default:
        return 'Failed to $action. Please try again later.';
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
      final direct = raw['chatId'];
      if (direct is String) return direct;

      final nested = raw['data'];
      if (nested is Map) {
        final innerId = nested['chatId'];
        if (innerId is String) return innerId;
      }

      for (final value in raw.values) {
        final nestedId = _extractChatId(value);
        if (nestedId != null) return nestedId;
      }
    } else if (raw is List) {
      for (final item in raw) {
        final nestedId = _extractChatId(item);
        if (nestedId != null) return nestedId;
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

  void _handleFavoritesChanged() {
    if (_ignoreNextFavoriteEvent) {
      _ignoreNextFavoriteEvent = false;
      return;
    }
    _loadFavorites(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => _loadFavorites(reset: _favorites.isEmpty),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            if (_loading && _favorites.isEmpty) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (_favorites.isEmpty && !_loading)
              SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'No favorite services yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ServicesGrid(
                services: _favorites,
                onTap: _openServiceDetails,
                onMessage: (s) => _triggerConversationForOwner(s.userId),
                onFavorite: _toggleFavorite,
              ),
            const SizedBox(height: 12),
            if (!_last) ...[
              if (_loading && _favorites.isNotEmpty)
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
                            _safeSetState(() {
                              _page += 1;
                            });
                            _loadFavorites(reset: false);
                          },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
