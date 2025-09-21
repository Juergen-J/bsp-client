import 'dart:async';

import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:berlin_service_portal/widgets/services_grid.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/router.dart' show homeSearchQuery, homeSelectedCategoryId;
import '../model/service/user_service_short_dto.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CancelToken? _cancelToken;
  bool _mounted = true;

  void _safeSetState(VoidCallback fn) {
    if (!_mounted) return;
    if (mounted) setState(fn);
  }

  final List<UserServiceShortDto> _results = [];
  bool _loading = false;
  String? _error;

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
  }

  @override
  void dispose() {
    _mounted = false;
    _cancelToken?.cancel('dispose');
    homeSearchQuery.removeListener(_searchListener);
    homeSelectedCategoryId.removeListener(_categoryListener);
    _debounce?.cancel();
    super.dispose();
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
              onTap: (s) => debugPrint('Tapped ${s.name}'),
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
