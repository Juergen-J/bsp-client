import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/user_service_short_dto.dart';
import '../../service/image_service.dart';

class ServiceShortCard extends StatefulWidget {
  final UserServiceShortDto service;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onFavorite;
  final List<String>? tags;
  final String? priceUnit;

  const ServiceShortCard({
    super.key,
    required this.service,
    this.onTap,
    this.onMessage,
    this.onFavorite,
    this.tags,
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
    final colorScheme = theme.colorScheme;

    final tags = widget.tags ?? [widget.service.serviceType.displayName];
    final priceStr = _formatPrice(widget.service, widget.priceUnit ?? '');

    return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: colorScheme.primary.withOpacity(0.08),
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.service.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  priceStr,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags
                                    .where((e) => e.trim().isNotEmpty)
                                    .map((e) => _Tag(text: e))
                                    .toList(),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              widget.service.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onMessage,
                        icon: const Icon(Icons.chat_bubble_outline),
                        color: colorScheme.onSurface,
                        tooltip: 'Message',
                        splashRadius: 20,
                      ),
                      IconButton(
                        onPressed: widget.onFavorite,
                        icon: const Icon(Icons.star_border),
                        color: colorScheme.onSurface,
                        tooltip: 'Favorite',
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
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

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
