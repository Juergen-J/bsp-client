import 'package:flutter/material.dart';
import 'base_card.dart';

class AddDeviceCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddDeviceCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      image: const Icon(Icons.add, size: 40, color: Colors.green),
      height: 300,
      // вся карточка
      imageHeight: 300,
      // высота картинки = вся карточка
      child: null, // 👈 ничего не передаём
    );
  }
}
