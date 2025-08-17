import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/router.dart' show homeSearchQuery, homeSelectedCategoryId;
import '../model/service/user_service_short_dto.dart';
import '../service/auth_service.dart';
import '../widgets/cards/service_card.dart';
import 'modal/modal_service.dart';
import 'modal/modal_type.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    if (categoryId == null) return; // ждём, пока AppBar подтянет категории

    if (reset) {
      setState(() {
        _page = 0;
        _last = true;
        _results.clear();
      });
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final dio = Provider.of<AuthService>(context, listen: false).dio;
    try {
      final resp = await dio.post(
        '/v1/service/search',
        queryParameters: {
          'page': _page,
          'size': _size,
        },
        data: {
          'serviceTypeId': categoryId,
          'searchValue': homeSearchQuery.value,
        },
      );

      if (resp.statusCode == 200 && resp.data['content'] != null) {
        final items = (resp.data['content'] as List)
            .map((e) => UserServiceShortDto.fromJson(e))
            .toList();

        setState(() {
          _results.addAll(items);
          _last = (resp.data['last'] as bool?) ?? true;
          _loading = false;
        });
      } else {
        throw Exception('Bad response: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load services: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modalManager = context.read<ModalManager>();

    // Без ScrollView: скроллит внешний CustomScrollView в роутере
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          if (_error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading && _results.isEmpty) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          if (_results.isEmpty && !_loading)
            SizedBox(
              height: 180,
              child: Center(
                child: Text('No services found',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _results.map((service) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    minWidth: 260,
                    minHeight: 330,
                    maxHeight: 330,
                  ),
                  child: SizedBox(
                    height: 330,
                    child: ServiceCard(
                      service: service,
                      onTap: () {
                        modalManager.show(
                          ModalType.serviceEditForm,
                          data: {
                            'serviceId': service.id,
                          },
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          if (!_last) ...[
            if (_loading && _results.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more'),
                onPressed: _loading
                    ? null
                    : () {
                        setState(() => _page += 1);
                        _triggerSearch(reset: false);
                      },
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
