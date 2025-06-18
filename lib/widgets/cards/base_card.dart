import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class BaseCard extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final Widget image;
  final double? height;
  final double? imageHeight;

  const BaseCard({
    Key? key,
    this.child,
    required this.image,
    this.onTap,
    this.height,
    this.imageHeight,
  }) : super(key: key);

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final showOnlyImage = widget.child == null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 300,
            height: widget.height,
            child: Card(
              elevation: _hovering ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: showOnlyImage
                  ? Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: widget.image,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: widget.imageHeight,
                          width: double.infinity,
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child: widget.image,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: widget.child!,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
