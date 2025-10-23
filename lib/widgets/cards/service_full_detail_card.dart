import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/attachment_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/user_service_full_dto.dart';
import '../../service/image_service.dart';

class ServiceFullDetailCard extends StatelessWidget {
  final UserServiceFullDto full;
  final VoidCallback? onClose;
  final VoidCallback? onMessage;
  final String? priceUnit;

  const ServiceFullDetailCard({
    super.key,
    required this.full,
    this.onClose,
    this.onMessage,
    this.priceUnit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final price = _formatPrice(full, priceUnit ?? '');
    final mainImageId = _extractPrimaryImageId(full.attachments);

    final categoryAttrs =
        full.attributes.where((a) => a.property.trim().isEmpty).toList();
    final detailAttrs =
        full.attributes.where((a) => a.property.trim().isNotEmpty).toList();

    final topTags = _collectTagValues(categoryAttrs);
    final groupedAttributes = _groupAttributes(detailAttrs);
    if (topTags.isEmpty && groupedAttributes.isNotEmpty) {
      final firstKey = groupedAttributes.keys.first;
      topTags.addAll(groupedAttributes[firstKey]!);
      groupedAttributes.remove(firstKey);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 18))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final imageRadius = compact ? 20.0 : 24.0;
            final image = ClipRRect(
              borderRadius: BorderRadius.circular(imageRadius),
              child: _HeroImage(
                  imageId: mainImageId, aspectRatio: compact ? 16 / 9 : 4 / 3),
            );

            final actionButtons = <Widget>[
              if (onMessage != null)
                _CircleIconButton(
                    icon: Icons.chat_bubble_outline,
                    tooltip: 'Message',
                    onPressed: onMessage),
              _CircleIconButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: onClose ?? () => Navigator.of(context).maybePop()),
            ];

            Widget buildDetails() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(full.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              full.serviceType.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Wrap(
                          spacing: 12, runSpacing: 12, children: actionButtons),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ArrowBadge(color: cs.primary),
                      const SizedBox(width: 16),
                      Text(price,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      if (full.price.negotiable) ...[
                        const SizedBox(width: 8),
                        Text('Negotiable',
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                  if (topTags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            topTags.map((v) => _TagPill(text: v)).toList()),
                  ],
                  const SizedBox(height: 24),
                  Text(full.description,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(height: 1.5, color: cs.onSurfaceVariant)),

                  // Address
                  const SizedBox(height: 28),
                  if (_hasAddress(full)) ...[
                    Text(
                      'Address:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatAddress(full),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],

                  // Devices
                  if (full.devices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Devices:',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: full.devices
                          .map((d) => _TagPill(text: d.name))
                          .toList(),
                    ),
                  ],

                  // Grouped attributes
                  if (groupedAttributes.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    ...groupedAttributes.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${entry.key}:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface)),
                              const SizedBox(height: 12),
                              Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: entry.value
                                      .map((v) => _TagPill(text: v))
                                      .toList()),
                            ],
                          ),
                        )),
                  ],
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (compact) ...[
                    image,
                    const SizedBox(height: 24),
                    buildDetails(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                            flex: 4,
                            child: SizedBox(height: 260, child: image)),
                        const SizedBox(width: 32),
                        Expanded(flex: 5, child: buildDetails()),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _collectTagValues(List<ServiceAttributeDto> attributes) {
    final values = <String>{};
    for (final attr in attributes) {
      final value = attr.value.trim();
      if (value.isEmpty) continue;
      for (final chunk in value.split(',')) {
        final trimmed = chunk.trim();
        if (trimmed.isNotEmpty) values.add(trimmed);
      }
    }
    return values.toList();
  }

  LinkedHashMap<String, List<String>> _groupAttributes(
      List<ServiceAttributeDto> attributes) {
    final grouped = LinkedHashMap<String, List<String>>();
    for (final attr in attributes) {
      final property = attr.property.trim();
      final value = attr.value.trim();
      if (property.isEmpty || value.isEmpty) continue;

      final list = grouped.putIfAbsent(property, () => <String>[]);
      for (final chunk in value.split(',')) {
        final t = chunk.trim();
        if (t.isEmpty || list.contains(t)) continue;
        list.add(t);
      }
    }
    return grouped;
  }

  String? _extractPrimaryImageId(List<AttachmentDto> attachments) {
    final mains = attachments.where((a) => a.mainAttachment);
    final AttachmentDto? main = mains.isNotEmpty
        ? mains.first
        : (attachments.isNotEmpty ? attachments.first : null);
    if (main?.details is ImageAttachmentDto) {
      final img = main!.details as ImageAttachmentDto;
      return img.normalId.isNotEmpty ? img.normalId : img.smallId;
    }
    return null;
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageId;
  final double aspectRatio;

  const _HeroImage({this.imageId, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: imageId == null
          ? Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(Icons.image, color: cs.onSurfaceVariant, size: 42))
          : FutureBuilder<Widget>(
              future: Provider.of<ImageService>(context, listen: false)
                  .getImageWidget(imageId!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (!snap.hasData) {
                  return Container(
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                  );
                }
                return snap.data!;
              },
            ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;

  const _TagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Text(text,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _CircleIconButton({required this.icon, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                  color: cs.shadow.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6))
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        ),
      ),
    );
    return (tooltip?.isNotEmpty ?? false)
        ? Tooltip(message: tooltip!, child: btn)
        : btn;
  }
}

class _ArrowBadge extends StatelessWidget {
  final Color color;

  const _ArrowBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        color: color.withOpacity(0.08),
      ),
      child: Icon(Icons.arrow_forward, color: color, size: 20),
    );
  }
}

bool _hasAddress(UserServiceFullDto s) {
  final a =
      s.address; // если address вдруг null в рантайме — подстрахуемся ниже
  final hasStreet = _nonEmpty(a?.street1) || _nonEmpty(a?.street2);
  final hasCityState = _nonEmpty(a?.city) || _nonEmpty(a?.state);
  final hasPostcode = _s(a?.postcode).isNotEmpty && _s(a?.postcode) != '0';
  return hasStreet || hasCityState || hasPostcode;
}

String _s(Object? v) => (v?.toString() ?? '').trim();

String _formatPrice(UserServiceFullDto s, String unitSuffix) {
  final amount = s.price.amount;
  final currency = s.price.currencyCode;
  final suffix = s.price.negotiable ? unitSuffix : '';
  return '$amount $currency $suffix'.trim();
}

bool _nonEmpty(Object? v) => _s(v).isNotEmpty;

String _formatAddress(UserServiceFullDto s) {
  final a = s.address;

  // Линия 1: улицы
  final line1 = [
    if (_nonEmpty(a?.street1)) _s(a?.street1),
    if (_nonEmpty(a?.street2)) _s(a?.street2),
  ].join(', ');

  // Линия 2: индекс + город
  final line2 = [
    if (_nonEmpty(a?.postcode) && _s(a?.postcode) != '0') _s(a?.postcode),
    if (_nonEmpty(a?.city)) _s(a?.city),
  ].join(' ');

  // Линия 3: регион/земля/штат
  final line3 = _s(a?.state);

  return [line1, line2, line3].where((v) => v.isNotEmpty).join(' · ');
}
