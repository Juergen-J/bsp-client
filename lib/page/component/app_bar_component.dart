import 'package:berlin_service_portal/app/app_state.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart' show homeSearchQuery, homeSelectedCategoryId;
import '../../util/user_info_sammler.dart';
import 'account_menu_overlay.dart';
import 'context_menu.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final GlobalKey avatarKey;
  final GlobalKey languageKey;

  final double contentWidth;
  final double height;

  const CustomAppBar({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.avatarKey,
    required this.languageKey,
    required this.contentWidth,
    required this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final _searchController = TextEditingController();

  List<ShortServiceTypeDto> _categories = [];
  String? _selectedCategoryId; // становится ненулевым после загрузки
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = homeSearchQuery.value;
    _selectedCategoryId = homeSelectedCategoryId.value; // может быть null
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final dio = Provider.of<AuthService>(context, listen: false).dio;
      final resp = await dio.get('/v1/service-type');
      if (resp.statusCode == 200 && resp.data['content'] != null) {
        final items = (resp.data['content'] as List)
            .map((e) => ShortServiceTypeDto.fromJson(e))
            .toList();

        var selectedId = _selectedCategoryId;
        if (items.isNotEmpty) {
          final containsSelected =
              selectedId != null && items.any((c) => c.id == selectedId);
          if (!containsSelected) {
            selectedId = items.first.id;
            homeSelectedCategoryId.value = selectedId;
          }
        } else {
          selectedId = null;
          homeSelectedCategoryId.value = null;
        }

        setState(() {
          _categories = items;
          _selectedCategoryId = selectedId;
          _loadingCats = false;
        });
      } else {
        setState(() => _loadingCats = false);
      }
    } catch (_) {
      setState(() => _loadingCats = false);
    }
  }

  void _applySearch() {
    // ТОЛЬКО тут дергаем поиск
    final q = _searchController.text.trim();
    // Если хочешь игнорировать 1-символьные — раскомментируй:
    // if (q.isNotEmpty && q.length < 2) return;
    homeSearchQuery.value = q; // пусть Home сам справится с пустой строкой
    // категория применяется через homeSelectedCategoryId, но без автопоиска
  }

  void _onSelectCategory(String? id) {
    if (id == null && _categories.isNotEmpty) {
      id = _categories.first.id;
    }
    setState(() => _selectedCategoryId = id);
    homeSelectedCategoryId.value = id;
    // ВНИМАНИЕ: поиск не запускаем — будет учтен на следующем Enter/лупе
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = Provider.of<AppState>(context);
    final locale = appState.locale;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      child: Center(
        child: Container(
          width: widget.contentWidth,
          height: widget.preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // logo
              Row(
                children: [
                  Text(
                    'lok',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'tu',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // search + category filter в одной капсуле
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // кнопка запуска поиска
                      IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.search),
                        onPressed: _applySearch,
                      ),
                      const SizedBox(width: 4),

                      // категория
                      if (_loadingCats)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategoryId,
                            isDense: true,
                            items: <DropdownMenuItem<String>>[
                              ..._categories.map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    c.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: _onSelectCategory,
                          ),
                        ),

                      const SizedBox(width: 8),
                      // разделитель
                      Container(width: 1, height: 20, color: Colors.black12),
                      const SizedBox(width: 8),

                      // поле поиска (без автозапросов, только Enter)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search…',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _applySearch(),
                        ),
                      ),

                      IconButton(
                        icon: Icon(Icons.location_pin,
                            color: colorScheme.primary),
                        onPressed: () async {
                          await fetchLocation();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // language + theme + account
              Row(
                children: [
                  Stack(alignment: Alignment.center, children: [
                    IconButton(
                      key: widget.languageKey,
                      icon: SvgPicture.asset(
                        'assets/icons/language.svg',
                        colorFilter: ColorFilter.mode(
                          colorScheme.onPrimary,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        showContextMenuForWidget<Locale>(
                          context: context,
                          key: widget.languageKey,
                          items: appState.supportedLocales.map((loc) {
                            return PopupMenuItem(
                              value: loc,
                              child: Text(loc.languageCode.toUpperCase()),
                            );
                          }).toList(),
                        ).then((selectedLocale) {
                          if (selectedLocale != null) {
                            appState.changeLocale(selectedLocale);
                          }
                        });
                      },
                    ),
                    IgnorePointer(
                      child: Text(
                        locale.languageCode.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ]),
                  IconButton(
                    icon: Icon(
                      widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: colorScheme.onPrimary,
                    ),
                    onPressed: widget.onThemeToggle,
                  ),
                  IconButton(
                    key: widget.avatarKey,
                    tooltip: 'Account',
                    icon: SvgPicture.asset(
                      'assets/icons/profile.svg',
                      colorFilter: ColorFilter.mode(
                        colorScheme.onPrimary,
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () =>
                        AccountMenuOverlay.show(context, widget.avatarKey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
