import 'package:flutter/material.dart';

import '../../model/attachment/attachment_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/device/attribute_present.dart';
import '../../model/device/short_device_dto.dart';
import '../device_image_carousel.dart';

class DeviceFullDetailCard extends StatelessWidget {
  final ShortDeviceDto device;
  final bool loading;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;

  const DeviceFullDetailCard({
    super.key,
    required this.device,
    this.loading = false,
    this.onBack,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageIds = _imageIdsFromAttachments(device.attachments);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 20),
            color: cs.shadow.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final imageSection = _DeviceImageSection(imageIds: imageIds);
            final infoSection = _DeviceInfoSection(
              device: device,
              loading: loading,
              onBack: onBack,
              onRefresh: onRefresh,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  infoSection,
                  const SizedBox(height: 24),
                  imageSection,
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(flex: 3, child: imageSection),
                      const SizedBox(width: 24),
                      Flexible(flex: 4, child: infoSection),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                _DeviceAttributesSection(attributes: device.attributes),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeviceInfoSection extends StatelessWidget {
  final ShortDeviceDto device;
  final bool loading;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;

  const _DeviceInfoSection({
    required this.device,
    required this.loading,
    this.onBack,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  Text(
                    device.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: 'Brand', value: device.brand.name),
                      _InfoChip(
                        label: 'Type',
                        value: device.deviceType.displayName,
                      ),
                      if ((device.skuCode ?? '').trim().isNotEmpty)
                        _InfoChip(label: 'SKU', value: device.skuCode!.trim()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(height: 8),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loading ? null : onRefresh,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Device overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'Brand', value: device.brand.name),
        _InfoRow(label: 'Model', value: device.name),
        _InfoRow(label: 'Device type', value: device.deviceType.displayName),
        if ((device.skuCode ?? '').trim().isNotEmpty)
          _InfoRow(label: 'SKU code', value: device.skuCode!.trim()),
      ],
    );
  }
}

class _DeviceImageSection extends StatelessWidget {
  final List<String> imageIds;

  const _DeviceImageSection({required this.imageIds});

  @override
  Widget build(BuildContext context) {
    if (imageIds.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Center(
          child: Icon(
            Icons.devices_other_rounded,
            size: 72,
            color: Colors.grey,
          ),
        ),
      );
    }

    return DeviceImageCarousel(imageIds: imageIds);
  }
}

class _DeviceAttributesSection extends StatelessWidget {
  final List<AttributePresent> attributes;

  const _DeviceAttributesSection({required this.attributes});

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: attributes
              .map<Widget>(
                (attr) =>
                    _AttributeCard(title: attr.propertyName, value: attr.value),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AttributeCard extends StatelessWidget {
  final String title;
  final String value;

  const _AttributeCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        color: cs.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest,
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

List<String> _imageIdsFromAttachments(List<AttachmentDto> attachments) {
  final ordered = attachments
      .where((att) => att.details is ImageAttachmentDto)
      .map(
        (att) => (
          main: att.mainAttachment,
          id: (att.details as ImageAttachmentDto).normalId,
          fallback: (att.details as ImageAttachmentDto).smallId,
        ),
      )
      .toList();
  if (ordered.isEmpty) return const [];
  ordered.sort((a, b) {
    if (a.main == b.main) return 0;
    return a.main ? -1 : 1;
  });

  return ordered
      .map((e) => e.id.isNotEmpty ? e.id : e.fallback)
      .where((id) => id.isNotEmpty)
      .toList();
}
