import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<XFile> initialFiles;
  final void Function(List<XFile> files) onFilesPicked;

  const ImageUploadWidget({
    super.key,
    this.initialFiles = const [],
    required this.onFilesPicked,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  late List<XFile> _files;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.initialFiles);
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _files.add(image);
        });
        widget.onFilesPicked(_files);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора изображения: $e')),
      );
    } finally {
      setState(() => _isPicking = false);
    }
  }

  void _removeImage(XFile file) {
    setState(() {
      _files.remove(file);
    });
    widget.onFilesPicked(_files);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._files.map(
          (file) => Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(file.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => _removeImage(file),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        _isPicking
            ? const SizedBox(
                width: 100,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 40, color: Colors.grey),
                ),
              ),
      ],
    );
  }
}
