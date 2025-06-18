import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

import '../service/image_service.dart';
import 'image_gallery_viewer.dart';

class DeviceImageCarousel extends StatefulWidget {
  final List<String> imageIds;

  const DeviceImageCarousel({super.key, required this.imageIds});

  @override
  State<DeviceImageCarousel> createState() => _DeviceImageCarouselState();
}

class _DeviceImageCarouselState extends State<DeviceImageCarousel> {
  late InfiniteScrollController _controller;
  int _currentIndex = 0;
  Map<String, Widget> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _controller = InfiniteScrollController(initialItem: 0);
  }

  @override
  Widget build(BuildContext context) {
    final imageService = Provider.of<ImageService>(context, listen: false);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: InfiniteCarousel.builder(
            itemCount: widget.imageIds.length,
            itemExtent: 180,
            controller: _controller,
            axisDirection: Axis.horizontal,
            loop: widget.imageIds.length > 1,
            velocityFactor: 0.2,
            anchor: 0.0,
            center: true,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, itemIndex, realIndex) {
              final imageId = widget.imageIds[itemIndex];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () {
                    showImageGalleryViewer(context, widget.imageIds, itemIndex);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.grey.shade200,
                      child: _imageCache.containsKey(imageId)
                          ? _imageCache[imageId]!
                          : FutureBuilder<Widget>(
                              key: ValueKey(imageId),
                              future: _loadAndCacheImage(imageService, imageId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return _imageCache[imageId] ??
                                      const Icon(Icons.broken_image, size: 50);
                                }
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Индикаторы
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageIds.length, (index) {
            final isActive = index == _currentIndex;
            return GestureDetector(
              onTap: () {
                _controller.animateToItem(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.blue : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Кнопки навигации
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                if (_currentIndex > 0) {
                  _controller.previousItem();
                } else if (widget.imageIds.length > 1) {
                  _controller.animateToItem(widget.imageIds.length - 1);
                }
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              '${_currentIndex + 1} / ${widget.imageIds.length}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: () {
                if (_currentIndex < widget.imageIds.length - 1) {
                  _controller.nextItem();
                } else if (widget.imageIds.length > 1) {
                  _controller.animateToItem(0);
                }
              },
              icon: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Widget> _loadAndCacheImage(
      ImageService imageService, String imageId) async {
    if (!_imageCache.containsKey(imageId)) {
      try {
        final widget = await imageService.getImageWidget(imageId);
        if (mounted) {
          _imageCache[imageId] = widget;
        }
        return widget;
      } catch (e) {
        final errorWidget = const Icon(Icons.broken_image, size: 50);
        if (mounted) {
          _imageCache[imageId] = errorWidget;
        }
        return errorWidget;
      }
    }
    return _imageCache[imageId]!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
