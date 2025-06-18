import 'package:flutter/material.dart';
import 'base_card.dart';

class ServiceCard extends StatelessWidget {
  final String location;
  final String category;
  final String price;
  final Widget? image;
  final VoidCallback? onTap;

  const ServiceCard({
    Key? key,
    required this.location,
    required this.category,
    required this.price,
    this.image,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      image: image != null
          ? Image.asset(
              image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : const Icon(Icons.print, size: 40, color: Colors.grey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location, style: const TextStyle(color: Colors.grey)),
          Text(category),
          Text(
            price,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
