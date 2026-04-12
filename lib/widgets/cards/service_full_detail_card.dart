import 'package:flutter/material.dart';

import '../../model/attachment/attachment_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/device/short_device_dto.dart';
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
  final ValueChanged<ShortDeviceDto>? onDeviceTap;

  const ServiceFullDetailCard({
    super.key,
    required this.full,
    this.onClose,
    this.onMessage,
    this.onFavorite,
    this.priceUnit,
    this.isFavorite = false,
    this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final price = _formatPrice(full, priceUnit ?? '');
    final allTags = _collectTagValues(full.attributes);
    final addrStr = _formatAddress(full);
    final hasAddress = addrStr.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          width: double.infinity,
          decoration: isMobile
              ? BoxDecoration(color: cs.surface)
              : BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
          child: isMobile
              ? _buildMobileContent(
                  context, theme, cs, price, allTags, addrStr, hasAddress)
              : _buildDesktopContent(
                  context, theme, cs, price, allTags, addrStr, hasAddress),
        );
      },
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    String price,
    List<String> allTags,
    String addrStr,
    bool hasAddress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sticky Actions at top ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _DetailActionIcon(
                icon: Icons.chat_bubble_outline,
                tooltip: 'Message',
                onTap: onMessage,
                color: cs.primary,
              ),
              const SizedBox(width: 12),
              _DetailActionIcon(
                icon: isFavorite ? Icons.star : Icons.star_border,
                tooltip: 'Favorite',
                onTap: onFavorite,
                color: isFavorite ? cs.primary : null,
              ),
              const SizedBox(width: 12),
              _DetailActionIcon(
                icon: Icons.close,
                tooltip: 'Close',
                onTap: onClose ?? () => Navigator.of(context).maybePop(),
                forceEnabled: true,
              ),
            ],
          ),
        ),

        // --- Gallery (Full Width) ---
        SizedBox(
          width: double.infinity,
          height: 250,
          child: DeviceImageCarousel(
            imageIds: _imageIdsFromAttachments(full.attachments),
          ),
        ),

        // --- Content ---
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                full.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...allTags.take(6).map((t) => _TagPill(text: t)),
                  if (hasAddress)
                    _TagPill(
                      text: addrStr,
                      color: cs.secondaryContainer,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                full.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildDevicesList(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    String price,
    List<String> allTags,
    String addrStr,
    bool hasAddress,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gallery
              SizedBox(
                width: 320,
                child: DeviceImageCarousel(
                  imageIds: _imageIdsFromAttachments(full.attachments),
                ),
              ),
              const SizedBox(width: 24),
              // Data
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
                                style: theme.textTheme.headlineSmall?.copyWith(
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
          ),
          const SizedBox(height: 24),
          Text(
            full.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildDevicesList(theme),
        ],
      ),
    );
  }

  Widget _buildDevicesList(ThemeData theme) {
    if (full.devices.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatible Devices:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: full.devices
              .map(
                (d) => _TagPill(
                  text: _s(d.name).isNotEmpty
                      ? _s(d.name)
                      : _s(d.deviceType.displayName),
                  onTap: onDeviceTap == null ? null : () => onDeviceTap!(d),
                ),
              )
              .toList(),
        ),
      ],
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
  final VoidCallback? onTap;

  const _TagPill({required this.text, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: pill,
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
    final iconColor = enabled ? (color ?? cs.outline) : cs.outlineVariant;

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
