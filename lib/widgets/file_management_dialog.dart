import 'package:flutter/material.dart';



class FileManagementDialog extends StatelessWidget {
  final String? fileName;
  final String? fileUrl;
  final bool hasFile;
  final String? fileType; // ДОБАВЛЯЕМ ТИП ФАЙЛА
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const FileManagementDialog({
    super.key,
    this.fileName,
    this.fileUrl,
    required this.hasFile,
    this.fileType, // ДОБАВЛЯЕМ В КОНСТРУКТОР
    required this.onUpload,
    required this.onDownload,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Управление файлом',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.orange),
                  onPressed: onClose,
                  tooltip: 'Закрыть',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Информация о файле
            if (hasFile && fileName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Файл: $fileName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fileUrl != null)
                            Text(
                              'Размер: ${_getFileSizeFromUrl(fileUrl!)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Файл не загружен',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Кнопки действий
            Column(
              children: [
                // Кнопка загрузки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text('Загрузить файл'),
                    onPressed: onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Кнопка скачивания (только если есть файл)
                if (hasFile && fileUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Скачать файл'),
                      onPressed: onDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (hasFile && fileUrl != null) const SizedBox(height: 8),

                // Кнопка удаления (только если есть файл)
                if (hasFile)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Удалить файл'),
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFileSizeFromUrl(String url) {
    // Это заглушка - в реальном приложении нужно получать размер файла с сервера
    return '~1.5 MB';
  }
}