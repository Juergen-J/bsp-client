import 'package:flutter/material.dart';

class StickyMenuDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyMenuDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: height,
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}