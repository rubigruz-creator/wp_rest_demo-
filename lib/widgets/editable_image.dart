import 'package:flutter/material.dart';

class EditableImage extends StatelessWidget {
  final String imageUrl;
  final bool hasImage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final double size;
  final double borderRadius;

  const EditableImage({
    super.key,
    required this.imageUrl,
    required this.hasImage,
    required this.onTap,
    required this.onEdit,
    this.size = 56,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Основное изображение
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: hasImage ? Colors.transparent : Colors.grey[800],
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error_outline, color: Colors.red);
                      },
                    ),
                  )
                : const Icon(Icons.add_a_photo, size: 20, color: Colors.orange),
          ),
          
          // Кнопка редактирования (только если есть изображение)
          if (hasImage)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}