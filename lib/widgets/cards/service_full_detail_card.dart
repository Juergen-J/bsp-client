import 'package:flutter/material.dart';

import '../../model/attachment/attachment_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/user_service_full_dto.dart';
import '../device_image_carousel.dart'; // путь поправь под свой проект

class ServiceFullDetailCard extends StatelessWidget {
  final UserServiceFullDto full;
  final VoidCallback? onClose;
  final VoidCallback? onMessage;
  final VoidCallback? onFavorite;
  final String? priceUnit;
  final bool isFavorite;

  const ServiceFullDetailCard({
    super.key,
    required this.full,
    this.onClose,
    this.onMessage,
    this.onFavorite,
    this.priceUnit,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final price = _formatPrice(full, priceUnit ?? '');
    final allTags = _collectTagValues(full.attributes);
    final addrStr = _formatAddress(full);
    final hasAddress = addrStr.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              // ===== Верхняя часть =====
              Widget top() {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Левая колонка: галерея ----
                    SizedBox(
                      width: compact ? 260 : 320,
                      child: DeviceImageCarousel(
                        imageIds: _imageIdsFromAttachments(full.attachments),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // ---- Правая колонка: данные ----
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      full.name,
                                      style:
                                          theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      price,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _DetailActionIcon(
                                    icon: Icons.chat_bubble_outline,
                                    tooltip: 'Message',
                                    onTap: onMessage,
                                  ),
                                  const SizedBox(width: 4),
                                  _DetailActionIcon(
                                    icon: isFavorite ? Icons.star : Icons.star_border,
                                    tooltip: 'Favorite',
                                    onTap: onFavorite,
                                    color: isFavorite ? cs.primary : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _DetailActionIcon(
                                    icon: Icons.close,
                                    tooltip: 'Close',
                                    onTap: onClose ??
                                        () => Navigator.of(context).maybePop(),
                                    forceEnabled: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Теги и адрес
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...allTags.take(4).map((t) => _TagPill(text: t)),
                              if (hasAddress)
                                _TagPill(
                                  text: addrStr,
                                  color: cs.secondaryContainer,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // ===== Средняя часть =====
              Widget middle() {
                return Text(
                  full.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                );
              }

              // ===== Нижняя часть =====
              Widget bottom() {
                if (full.devices.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compatible Devices:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: full.devices
                          .map((d) => _TagPill(
                                text: _s(d.name).isNotEmpty
                                    ? _s(d.name)
                                    : _s(d.deviceType.displayName),
                              ))
                          .toList(),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  top(),
                  const SizedBox(height: 24),
                  middle(),
                  const SizedBox(height: 28),
                  bottom(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- helpers ----------------

  String _formatPrice(UserServiceFullDto s, String unitSuffix) {
    final amount = s.price.amount;
    final currency = s.price.currencyCode;
    final suffix = s.price.negotiable ? unitSuffix : '';
    return '$amount $currency${suffix.isEmpty ? '' : '/$suffix'}';
  }

  String _formatAddress(UserServiceFullDto s) {
    final a = s.address;
    final line1 = [
      if (_nonEmpty(a.street1)) _s(a.street1),
      if (_nonEmpty(a.street2)) _s(a.street2),
    ].join(', ');
    final line2 = [
      if (_nonEmpty(a.postcode) && _s(a.postcode) != '0') _s(a.postcode),
      if (_nonEmpty(a.city)) _s(a.city),
    ].join(' ');
    final line3 = _s(a.state);
    return [line1, line2, line3].where((v) => v.isNotEmpty).join(' · ');
  }

  List<String> _collectTagValues(List<ServiceAttributeDto> attributes) {
    final values = <String>{};
    for (final attr in attributes) {
      final v = attr.value.trim();
      if (v.isEmpty) continue;
      for (final chunk in v.split(',')) {
        final c = chunk.trim();
        if (c.isNotEmpty) values.add(c);
      }
    }
    return values.toList();
  }

  List<String> _imageIdsFromAttachments(List<AttachmentDto> atts) {
    final images = <({bool main, String normal, String small})>[];
    for (final a in atts) {
      final d = a.details;
      if (d is ImageAttachmentDto) {
        images.add((
          main: a.mainAttachment,
          normal: d.normalId,
          small: d.smallId,
        ));
      }
    }

    if (images.isEmpty) return const [];
    images.sort((a, b) {
      if (a.main == b.main) return 0;
      return a.main ? -1 : 1;
    });

    return images
        .map((e) => (e.normal.isNotEmpty ? e.normal : e.small))
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

// ---------------- supporting widgets ----------------

class _TagPill extends StatelessWidget {
  final String text;
  final Color? color;

  const _TagPill({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool forceEnabled;
  final Color? color;

  const _DetailActionIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.forceEnabled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = forceEnabled || onTap != null;
    final iconColor =
        enabled ? (color ?? cs.outline) : cs.outlineVariant;

    final button = SizedBox(
      width: 30,
      height: 30,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 18,
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );

    return Tooltip(message: tooltip, child: button);
  }
}

// ---------------- tiny utils ----------------
String _s(Object? v) => (v?.toString() ?? '').trim();

bool _nonEmpty(Object? v) => _s(v).isNotEmpty;
