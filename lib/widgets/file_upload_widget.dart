import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FileUploadWidget extends StatelessWidget {
  final String? fileUrl;
  final String? fileName;
  final bool hasFile;
  final VoidCallback onTap;
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final double size;

  const FileUploadWidget({
    super.key,
    this.fileUrl,
    this.fileName,
    required this.hasFile,
    required this.onTap,
    required this.onUpload,
    required this.onDownload,
    required this.onDelete,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.withOpacity(0.2) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFile ? Colors.green : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Icon(
          hasFile ? Icons.folder_open : Icons.folder,
          color: hasFile ? Colors.green : Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }
}