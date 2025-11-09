import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/service_attribute_dto.dart';
import '../../model/service/user_service_short_dto.dart';
import '../../service/image_service.dart';

class ServiceShortCard extends StatefulWidget {
  final UserServiceShortDto service;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onFavorite;
  final String? priceUnit;

  const ServiceShortCard({
    super.key,
    required this.service,
    this.onTap,
    this.onMessage,
    this.onFavorite,
    this.priceUnit,
  });

  @override
  State<ServiceShortCard> createState() => _ServiceShortCardState();
}

class _ServiceShortCardState extends State<ServiceShortCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tags = widget.service.attributes
        .where((attr) =>
            attr.property.trim().isNotEmpty || attr.value.trim().isNotEmpty)
        .toList();
    final priceStr = _formatPrice(widget.service, widget.priceUnit ?? '');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: cs.onSurfaceVariant.withOpacity(0.6), width: 1),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: cs.primary.withOpacity(0.08),
              highlightColor: Colors.transparent,
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SquareThumb(service: widget.service),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // === ОДНА ЛИНИЯ: title + price + actions ===
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // title
                              Expanded(
                                child: Text(
                                  widget.service.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // price
                              Text(
                                priceStr,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              // actions
                              _ActionIcon(
                                icon: Icons.chat_bubble_outline,
                                tooltip: 'Message',
                                onTap: widget.onMessage,
                              ),
                              const SizedBox(width: 4),
                              _ActionIcon(
                                icon: widget.service.favorite
                                    ? Icons.star
                                    : Icons.star_border,
                                tooltip: 'Favorite',
                                onTap: widget.onFavorite,
                                color: widget.service.favorite
                                    ? cs.primary
                                    : cs.outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (tags.isNotEmpty)
                            _TagsHeading(attributes: tags),
                          const SizedBox(height: 10),
                          Text(
                            widget.service.description,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(UserServiceShortDto s, String unitSuffix) {
    final amount = s.price.amount;
    final currency = s.price.currencyCode;
    final unit = s.price.negotiable ? unitSuffix : '';
    return '$amount $currency $unit';
  }
}

class _SquareThumb extends StatelessWidget {
  final UserServiceShortDto service;

  const _SquareThumb({required this.service});

  String? _smallId() {
    final mains = service.attachments.where((a) => a.mainAttachment);
    final main = mains.isNotEmpty ? mains.first : null;
    if (main?.details is ImageAttachmentDto) {
      return (main!.details as ImageAttachmentDto).smallId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = _smallId();

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: id == null
            ? Container(
                color: cs.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(Icons.image, color: cs.onSurfaceVariant),
              )
            : FutureBuilder<Widget>(
                future: Provider.of<ImageService>(context, listen: false)
                    .getImageWidget(
                  id,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child:
                          Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                    );
                  }
                  return snap.data!;
                },
              ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 28,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Tooltip(
          message: tooltip,
          child: Icon(icon,
              size: 20,
              color: color ?? cs.outline), // компактно и на одной линии с текстом
        ),
      ),
    );
  }
}

class _TagsHeading extends StatelessWidget {
  final List<ServiceAttributeDto> attributes;

  const _TagsHeading({required this.attributes});

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < attributes.length; i++) ...[
              _Tag(attribute: attributes[i]),
              if (i != attributes.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final ServiceAttributeDto attribute;

  const _Tag({required this.attribute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final property = attribute.property.trim();
    final value = attribute.value.trim();
    final text = [
      if (property.isNotEmpty) property,
      if (value.isNotEmpty) value,
    ].join(': ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSecondary,
        ),
      ),
    );
  }
}
