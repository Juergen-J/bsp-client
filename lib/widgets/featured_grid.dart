import 'package:flutter/material.dart';
import 'cards/mock_card.dart';
import 'cards/mock_card_data.dart';

class FeaturedGrid extends StatelessWidget {
  final List<MockCardData> items;

  const FeaturedGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isTwoCols = constraints.maxWidth >= 800;
      final crossAxisCount = isTwoCols ? 2 : 1;

      return GridView.builder(
        primary: false,
        // критично при вложении
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isTwoCols ? 2.8 : 2.6,
        ),
        itemBuilder: (context, index) => MockCard(data: items[index]),
      );
    });
  }
}
