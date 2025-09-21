import 'package:flutter/material.dart';
import '../../model/service/user_service_short_dto.dart';
import 'cards/service_short_card.dart';

class ServicesGrid extends StatelessWidget {
  final List<UserServiceShortDto> services;
  final void Function(UserServiceShortDto)? onTap;
  final void Function(UserServiceShortDto)? onMessage;

  const ServicesGrid({
    super.key,
    required this.services,
    this.onTap,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isTwoCols = constraints.maxWidth >= 800;
        final crossAxisCount = isTwoCols ? 2 : 1;

        final aspect = isTwoCols ? 3.0 : 3.0;

        return GridView.builder(
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspect,
          ),
          itemBuilder: (context, index) {
            final s = services[index];
            return ServiceShortCard(
              service: s,
              priceUnit: 'VB',
              onTap: onTap != null ? () => onTap!(s) : null,
              onMessage: onMessage != null ? () => onMessage!(s) : null,
              tags: ['React','Node.js','TypeScript'],
            );
          },
        );
      },
    );
  }
}
