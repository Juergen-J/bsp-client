import 'package:berlin_service_portal/widgets/cards/service_short_card.dart';
import 'package:flutter/material.dart';
import '../../model/service/user_service_short_dto.dart';

class ServicesGrid extends StatelessWidget {
  final List<UserServiceShortDto> services;
  final void Function(UserServiceShortDto)? onTap;

  const ServicesGrid({
    super.key,
    required this.services,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isTwoCols = constraints.maxWidth >= 800;
        final crossAxisCount = isTwoCols ? 2 : 1;

        return GridView.builder(
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isTwoCols ? 2.8 : 2.6,
          ),
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceShortCard(
              service: service,
              onTap: onTap != null ? () => onTap!(service) : null,
            );
          },
        );
      },
    );
  }
}
