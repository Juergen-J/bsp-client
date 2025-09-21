import 'dart:async';

import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:berlin_service_portal/widgets/services_grid.dart';
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
  bool get _hasAncestorScroll => PrimaryScrollController.of(context) != null;

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
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          ServicesGrid(
            services: _results,
            onTap: (s) {
              debugPrint('Tapped ${s.name}');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
