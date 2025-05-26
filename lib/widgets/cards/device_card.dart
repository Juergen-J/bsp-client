import 'package:flutter/material.dart';
import '../../model/short_device.dart';
import 'base_card.dart';

class DeviceCard extends StatelessWidget {
  final ShortDevice device;
  final VoidCallback? onTap;

  const DeviceCard({Key? key, required this.device, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      image: device.imagePath != null
          ? Image.asset(
              device.imagePath!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : const Icon(Icons.print, size: 40, color: Colors.grey),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  }
}
