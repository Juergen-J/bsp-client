import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/service/user_service_full_dto.dart';
import '../../model/attachment/image_attachment_dto.dart';
import '../../service/image_service.dart';
import 'base_card.dart';

class ServiceCard extends StatelessWidget {
  final UserServiceFullDto service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final smallId = _extractSmallImageId(service);

    return FutureBuilder<Widget>(
      future: _buildImage(context, smallId),
      builder: (context, snapshot) {
        final imageWidget = switch (snapshot.connectionState) {
          ConnectionState.waiting =>
            const Center(child: CircularProgressIndicator()),
          _ when snapshot.hasData => snapshot.data!,
          _ => const Icon(Icons.build, size: 40, color: Colors.grey),
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
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                service.serviceType.displayName,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              // Text(
              //   '€${service.price.toStringAsFixed(2)}',
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              // const SizedBox(height: 6),
              // Text(
              //   service.description,
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              //   style: Theme.of(context).textTheme.bodySmall,
              // ),

            ],
          ),
        );
      },
    );
  }

  String? _extractSmallImageId(UserServiceFullDto service) {
    final mainAttachment =
        service.attachments.where((a) => a.mainAttachment).firstOrNull;

    if (mainAttachment?.details is ImageAttachmentDto) {
      final imageDetails = mainAttachment!.details as ImageAttachmentDto;
      return imageDetails.smallId;
    }

    return null;
  }

  Future<Widget> _buildImage(BuildContext context, String? attachmentId) async {
    if (attachmentId == null) {
      return const Icon(Icons.build, size: 40, color: Colors.grey);
    }

    final imageService = Provider.of<ImageService>(context, listen: false);
    return await imageService.getImageWidget(attachmentId,
        width: double.infinity, height: double.infinity);
  }
}
