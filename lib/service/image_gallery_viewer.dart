import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

import 'image_service.dart';

class _ImageGalleryViewer extends StatefulWidget {
  final List<String> imageIds;
  final int initialIndex;

  const _ImageGalleryViewer({
    required this.imageIds,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _controller;
  late Future<List<ImageProvider>> _imagesFuture;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);

    final imageService = Provider.of<ImageService>(context, listen: false);
    _imagesFuture = Future.wait(
      widget.imageIds.map((id) async {
        final bytes = await imageService.fetchImageBytes(id);
        return MemoryImage(bytes);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ImageProvider>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final images = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            PhotoViewGallery.builder(
              pageController: _controller,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: images[index],
                minScale: PhotoViewComputedScale.contained * 1,
                maxScale: PhotoViewComputedScale.covered * 2.5,
              ),
              loadingBuilder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
            ),

            // ← Кнопка "назад"
            Positioned(
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 32),
                onPressed: currentIndex > 0
                    ? () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ),

            // → Кнопка "вперёд"
            Positioned(
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 32),
                onPressed: currentIndex < widget.imageIds.length - 1
                    ? () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ),

            // ✖ Кнопка закрытия
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Индикатор страницы
            Positioned(
              bottom: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentIndex + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void showImageGalleryViewer(
    BuildContext context, List<String> imageIds, int initialIndex) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Image gallery',
    // <=== Это ОБЯЗАТЕЛЬНО
    barrierColor: Colors.black.withOpacity(0.9),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _ImageGalleryViewer(
            imageIds: imageIds,
            initialIndex: initialIndex,
          ),
        ),
      );
    },
  );
}
