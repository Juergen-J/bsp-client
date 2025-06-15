import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../model/short_device.dart';
import '../../service/image_service.dart';
import 'base_card.dart';

class DeviceCard extends StatelessWidget {
  final ShortDevice device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final smallId = _extractSmallImageId(device);

    return FutureBuilder<Widget>(
        future: _buildImage(context, smallId),
        builder: (context, snapshot) {
          final imageWidget = switch (snapshot.connectionState) {
            ConnectionState.waiting =>
              const Center(child: CircularProgressIndicator()),
            _ when snapshot.hasData => snapshot.data!,
            _ => const Icon(Icons.print, size: 40, color: Colors.grey),
          };

          return BaseCard(
            onTap: onTap,
            image: imageWidget,
            height: 300,
            imageHeight: 239,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    device.deviceType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  String? _extractSmallImageId(ShortDevice device) {
    final mainAttachment =
        device.attachments.where((a) => a.mainAttachment).firstOrNull;

    if (mainAttachment?.details is ImageAttachmentDto) {
      final imageDetails = mainAttachment!.details as ImageAttachmentDto;
      return imageDetails.smallId;
    }

    return null;
  }

  Future<Widget> _buildImage(BuildContext context, String? attachmentId) async {
    if (attachmentId == null) {
      return const Icon(Icons.print, size: 40, color: Colors.grey);
    }

    final imageService = Provider.of<ImageService>(context, listen: false);
    return await imageService.getImageWidget(attachmentId, width: double.infinity, height: double.infinity);
  }
}
