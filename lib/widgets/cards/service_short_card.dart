import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/attachment/image_attachment_dto.dart';
import '../../model/service/user_service_short_dto.dart';
import '../../service/image_service.dart';

class ServiceShortCard extends StatefulWidget {
  final UserServiceShortDto service;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final List<String>? tags; // опционально: кастомные чипы
  final String? priceUnit;

  const ServiceShortCard({
    super.key,
    required this.service,
    this.onTap,
    this.onMessage,
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
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final tags = widget.tags ?? [widget.service.serviceType.displayName];
    final priceStr = _formatPrice(widget.service, widget.priceUnit ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // тонкая светлая рамка как на рефе
            color: cs.outlineVariant.withOpacity(0.6),
            width: 1,
          ),
          // мягкая «воздушная» тень на ховер
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  )
                ]
              : const [],
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
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(service: widget.service), // превью слева
                  const SizedBox(width: 16),
                  // центр: заголовок+цена, чипы, описание
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // заголовок + цена справа (одна строка)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.service.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              priceStr,
                              style: t.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // чипы
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

                        // описание
                        Text(
                          widget.service.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // иконка сообщения справа
                  IconButton(
                    onPressed: widget.onMessage,
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: cs.outline,
                    // более лёгкий оттенок, как на рефе
                    tooltip: 'Message',
                    splashRadius: 20,
                  ),
                ],
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

class _Thumb extends StatelessWidget {
  final UserServiceShortDto service;

  const _Thumb({required this.service});

  String? _smallId() {
    final main = service.attachments.where((a) => a.mainAttachment).firstOrNull;
    if (main?.details is ImageAttachmentDto) {
      return (main!.details as ImageAttachmentDto).smallId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = _smallId();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64, // крупнее, как на рефе
        height: 64,
        child: id == null
            ? Container(
                color: cs.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(Icons.image, color: cs.onSurfaceVariant),
              )
            : FutureBuilder<Widget>(
                future: Provider.of<ImageService>(context, listen: false)
                    .getImageWidget(id,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest, // «таблетка»
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
