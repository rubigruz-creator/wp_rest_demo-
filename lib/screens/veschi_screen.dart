import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/wp_api.dart';
import 'image_viewer_screen.dart';
import '../widgets/editable_image.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/file_management_dialog.dart';
import '../widgets/column_filter_menu.dart';


class VeschiScreen extends StatefulWidget {
  final WPApi api;
  const VeschiScreen({super.key, required this.api});

  @override
  State<VeschiScreen> createState() => _VeschiScreenState();
}

class _VeschiScreenState extends State<VeschiScreen> {
  late Future<List<dynamic>> _futureVeschi;
  final ImagePicker _imagePicker = ImagePicker();
  
  final Map<int, TextEditingController> _veschNameControllers = {};
  final Map<int, TextEditingController> _nicknameControllers = {};
  final Map<int, int> _veschFotoIds = {};
  final Map<int, int> _userPhotoIds = {};
  final Map<int, int> _custFileIds = {};
  final Map<int, String> _custFileUrls = {};
  final Map<int, String> _custFileNames = {};

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureVeschi = widget.api.fetchVeschi();
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _loadData();
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLoadingMessage(String message) {
    if (!mounted) return;
    
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 15),
      ),
    );
  }

  void _initializeControllers(List<dynamic> veschi) {
    for (final item in veschi) {
      final id = item['id'] as int;
      
      if (!_veschNameControllers.containsKey(id)) {
        final veschName = _getAcfValue(item, 'vesch-name').toString();
        _veschNameControllers[id] = TextEditingController(text: veschName);
      }
      
      if (!_nicknameControllers.containsKey(id)) {
        final nickname = _getAcfValue(item, 'nickname').toString();
        _nicknameControllers[id] = TextEditingController(text: nickname);
      }
      
      final veschFoto = _getAcfValue(item, 'vesch-foto');
      final userPhoto = _getAcfValue(item, 'photo');
      final custFile = _getAcfValue(item, 'cust-files');
      
      if (veschFoto != null && veschFoto != '') {
        if (veschFoto is Map && veschFoto['id'] != null) {
          _veschFotoIds[id] = veschFoto['id'] as int;
        } else if (veschFoto is int) {
          _veschFotoIds[id] = veschFoto;
        }
      }
      
      if (userPhoto != null && userPhoto != '') {
        if (userPhoto is Map && userPhoto['id'] != null) {
          _userPhotoIds[id] = userPhoto['id'] as int;
        } else if (userPhoto is int) {
          _userPhotoIds[id] = userPhoto;
        }
      }
      
      if (custFile != null && custFile != '' && custFile != 'false') {
        if (custFile is Map) {
          if (custFile['id'] != null) {
            _custFileIds[id] = custFile['id'] as int;
          }
          if (custFile['url'] != null) {
            _custFileUrls[id] = custFile['url'] as String;
          }
          if (custFile['filename'] != null) {
            _custFileNames[id] = custFile['filename'] as String;
          } else if (custFile['title'] != null) {
            _custFileNames[id] = custFile['title'] as String;
          }
        }
      }
    }
  }

  String _formatTimer(String dateIso) {
    try {
      final created = DateTime.parse(dateIso);
      final now = DateTime.now();
      final diff = now.difference(created);
      
      final days = diff.inDays;
      final hours = diff.inHours.remainder(24);
      final minutes = diff.inMinutes.remainder(60);
      
      return '${days}д : ${hours}\$ : ${minutes}¢';
    } catch (e) {
      return '0д : 0\$ : 0¢';
    }
  }

  String _formatSmartDate(String dateIso) {
    try {
      final date = DateTime.parse(dateIso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final dateDay = DateTime(date.year, date.month, date.day);
      
      if (dateDay == today) {
        return 'Сегодня';
      } else if (dateDay == yesterday) {
        return 'Вчера';
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Ошибка даты';
    }
  }

  dynamic _getAcfValue(dynamic item, String fieldName) {
    if (item == null || item['acf'] == null) return '';
    
    final acf = item['acf'] as Map<String, dynamic>;
    
    if (acf.containsKey(fieldName) && acf[fieldName] != null && acf[fieldName] != '') {
      return acf[fieldName];
    }
    
    final variants = [
      fieldName,
      fieldName.replaceAll('_', '-'),
      fieldName.replaceAll('-', '_'),
    ];
    
    for (final key in variants) {
      if (acf.containsKey(key) && acf[key] != null && acf[key] != '') {
        return acf[key];
      }
    }
    
    return '';
  }

  String _getImageUrl(dynamic imageField) {
    if (imageField == null || imageField == '' || imageField == 'false') {
      return '';
    }
    
    try {
      if (imageField is String) {
        if (imageField.isEmpty || !imageField.startsWith('http') || imageField.startsWith('file://')) {
          return '';
        }
        return imageField;
      }
      
      if (imageField is Map) {
        if (imageField['url'] is String) {
          final url = imageField['url'] as String;
          if (url.isNotEmpty && url.startsWith('http') && !url.startsWith('file://')) {
            return url;
          }
        }
        
        if (imageField['source_url'] is String) {
          final sourceUrl = imageField['source_url'] as String;
          if (sourceUrl.isNotEmpty && sourceUrl.startsWith('http') && !sourceUrl.startsWith('file://')) {
            return sourceUrl;
          }
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return 'PDF документ';
      case 'doc':
      case 'docx':
        return 'Word документ';
      case 'xls':
      case 'xlsx':
        return 'Excel таблица';
      case 'zip':
      case 'rar':
        return 'Архив';
      case 'txt':
        return 'Текстовый файл';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Изображение';
      default:
        return 'Файл';
    }
  }

  Future<void> _showImageSourceDialog(int itemId, String fieldType) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A3A),
          title: Text(
            'Выберите источник ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Галерея', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(itemId, fieldType, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Камера', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(itemId, fieldType, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(int itemId, String fieldType, ImageSource source) async {
    try {
      _showLoadingMessage('${source == ImageSource.camera ? 'Съемка' : 'Загрузка'} ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final fileName = '${fieldType}_${itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final uploadedImage = await widget.api.uploadImage(imageFile, fileName);

        if (uploadedImage != null) {
          final imageId = uploadedImage['id'] as int;
          
          if (fieldType == 'vesch-foto') {
            _veschFotoIds[itemId] = imageId;
          } else {
            _userPhotoIds[itemId] = imageId;
          }
          
          await _saveChanges(itemId, shouldRefresh: true);
          
          _showMessage('${fieldType == 'vesch-foto' ? 'Фото вещи' : 'Фото юзера'} обновлено!');
        } else {
          _showMessage('Ошибка загрузки изображения', isError: true);
        }
      } else {
        _showMessage('Отменено');
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  void _showFullScreenImage(int itemId, String fieldType, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: imageUrl,
          onEdit: () {
            Navigator.pop(context);
            _showImageSourceDialog(itemId, fieldType);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteImage(itemId, fieldType);
          },
          onClose: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _deleteImage(int itemId, String fieldType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: Text(
          'Удалить ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _showLoadingMessage('Удаление изображения...');

      try {
        if (fieldType == 'vesch-foto') {
          _veschFotoIds.remove(itemId);
        } else {
          _userPhotoIds.remove(itemId);
        }

        await _saveChanges(itemId, shouldRefresh: true);
        _showMessage('${fieldType == 'vesch-foto' ? 'Фото вещи' : 'Фото юзера'} удалено!');
      } catch (e) {
        _showMessage('Ошибка удаления: $e', isError: true);
      }
    }
  }

  void _onImageTap(int itemId, String fieldType, String imageUrl, bool hasImage) {
    if (hasImage) {
      _showFullScreenImage(itemId, fieldType, imageUrl);
    } else {
      _showImageSourceDialog(itemId, fieldType);
    }
  }

  void _onImageEdit(int itemId, String fieldType) {
    _showImageSourceDialog(itemId, fieldType);
  }

  void _showFileManagementDialog(int itemId) {
    final hasFile = _custFileIds.containsKey(itemId) && _custFileIds[itemId] != null;
    final fileUrl = _custFileUrls[itemId];
    final fileName = _custFileNames[itemId];
    final fileType = fileName != null ? _getFileType(fileName) : 'Неизвестный тип';

    showDialog(
      context: context,
      builder: (context) => FileManagementDialog(
        fileName: fileName,
        fileUrl: fileUrl,
        hasFile: hasFile,
        fileType: fileType,
        onUpload: () {
          Navigator.pop(context);
          _showFileSourceDialog(itemId);
        },
        onDownload: () {
          Navigator.pop(context);
          _downloadFile(itemId);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteFile(itemId);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showFileSourceDialog(int itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: const Text(
          'Выберите файл',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Галерея изображений', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(itemId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Сделать фото', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(itemId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(int itemId) async {
    try {
      _showLoadingMessage('Открытие галереи...');
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      
      if (imageFile != null) {
        await _uploadSelectedFile(itemId, File(imageFile.path), 'image.jpg');
      } else {
        _showMessage('Выбор отменен');
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera(int itemId) async {
    try {
      _showLoadingMessage('Открытие камеры...');
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
      
      if (imageFile != null) {
        await _uploadSelectedFile(itemId, File(imageFile.path), 'photo.jpg');
      } else {
        _showMessage('Съемка отменена');
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  Future<void> _uploadSelectedFile(int itemId, File file, String originalName) async {
    try {
      _showLoadingMessage('Загрузка файла...');

      final extension = originalName.split('.').last;
      final fileName = 'cust_file_${itemId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final uploadedFile = await widget.api.uploadFile(file, fileName);

      if (uploadedFile != null) {
        final fileId = uploadedFile['id'] as int;
        final fileUrl = uploadedFile['source_url'] as String;
        final serverFileName = uploadedFile['title']?['rendered'] as String? ?? originalName;
        
        setState(() {
          _custFileIds[itemId] = fileId;
          _custFileUrls[itemId] = fileUrl;
          _custFileNames[itemId] = serverFileName;
        });
        
        await _saveChanges(itemId, shouldRefresh: true);
        _showMessage('Файл успешно загружен!');
      } else {
        _showMessage('Ошибка загрузки файла на сервер', isError: true);
      }
    } catch (e) {
      print('Ошибка загрузки файла: $e');
      _showMessage('Ошибка загрузки: $e', isError: true);
    }
  }

  Future<void> _downloadFile(int itemId) async {
    if (!_custFileUrls.containsKey(itemId)) {
      _showMessage('Файл не найден', isError: true);
      return;
    }

    final fileUrl = _custFileUrls[itemId]!;
    final fileName = _custFileNames[itemId] ?? 'download';

    try {
      _showLoadingMessage('Открытие файла...');

      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        final launched = await launchUrl(
          Uri.parse(fileUrl),
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          _showMessage('Файл открывается...');
        } else {
          _showDownloadOptions(fileUrl, fileName, itemId);
        }
      } else {
        _showDownloadOptions(fileUrl, fileName, itemId);
      }
    } catch (e) {
      _showDownloadOptions(fileUrl, fileName, itemId);
    }
  }

  void _showDownloadOptions(String fileUrl, String fileName, int itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: const Text(
          'Скачать файл',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Файл: $fileName',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Выберите способ скачивания:',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyDownloadLink(fileUrl);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text('Копировать ссылку', style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser(fileUrl);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_browser, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text('Открыть в браузере', style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyDownloadLink(String fileUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: fileUrl));
      _showMessage('Ссылка скопирована в буфер обмена!');
    } catch (e) {
      _showMessage('Ошибка копирования: $e', isError: true);
    }
  }

  Future<void> _openInBrowser(String fileUrl) async {
    try {
      final launched = await launchUrl(
        Uri.parse(fileUrl),
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        _showMessage('Не удалось открыть браузер', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  Future<void> _deleteFile(int itemId) async {
    if (!_custFileIds.containsKey(itemId)) {
      _showMessage('Файл не найден', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: const Text('Удалить файл?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Вы уверены, что хотите удалить файл "${_custFileNames[itemId] ?? 'файл'}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showLoadingMessage('Удаление файла...');

      try {
        final fileId = _custFileIds[itemId]!;
        final success = await widget.api.deleteFile(fileId);

        if (success) {
          _custFileIds.remove(itemId);
          _custFileUrls.remove(itemId);
          _custFileNames.remove(itemId);
          
          await _saveChanges(itemId, shouldRefresh: true);
          _showMessage('Файл удален!');
        } else {
          _showMessage('Ошибка удаления файла', isError: true);
        }
      } catch (e) {
        _showMessage('Ошибка: $e', isError: true);
      }
    }
  }

  Future<void> _saveChanges(int itemId, {bool showMessage = true, bool shouldRefresh = false}) async {
    final veschName = _veschNameControllers[itemId]?.text ?? '';
    final nickname = _nicknameControllers[itemId]?.text ?? '';
    
    if (showMessage) {
      _showLoadingMessage('Сохранение...');
    }

    try {
      final Map<String, dynamic> updateData = {
        'acf': {
          'vesch-name': veschName,
          'nickname': nickname,
        }
      };

      if (_veschFotoIds.containsKey(itemId) && _veschFotoIds[itemId] != null) {
        final imageId = _veschFotoIds[itemId]!;
        updateData['acf']!['vesch-foto'] = imageId.toString();
      }
      
      if (_userPhotoIds.containsKey(itemId) && _userPhotoIds[itemId] != null) {
        final imageId = _userPhotoIds[itemId]!;
        updateData['acf']!['photo'] = imageId.toString();
      }

      if (_custFileIds.containsKey(itemId) && _custFileIds[itemId] != null) {
        final fileId = _custFileIds[itemId]!;
        updateData['acf']!['cust-files'] = fileId.toString();
      }

      final success = await widget.api.updateVeschi(itemId, updateData);
      
      if (showMessage) {
        if (success) {
          _showMessage('Сохранено!');
          
          if (shouldRefresh) {
            _refreshData();
          }
        } else {
          _showMessage('Ошибка сохранения', isError: true);
        }
      }
      
    } catch (e) {
      if (showMessage) {
        _showMessage('Ошибка: $e', isError: true);
      }
    }
  }

  Future<void> _addNewVesch() async {
    try {
      _showLoadingMessage('Создание новой вещи...');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultTitle = "Вещь $timestamp";

      final newVeschData = {
        'title': defaultTitle,
        'status': 'publish',
        'acf': {
          'vesch-name': defaultTitle,
          'nickname': '',
        }
      };

      final createdVesch = await widget.api.createVeschi(newVeschData);

      if (createdVesch != null) {
        _showMessage('Новая вещь создана!');
        _refreshData();
      } else {
        _showMessage('Ошибка создания', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3A),
        title: const Text('Удалить вещь?', style: TextStyle(color: Colors.white)),
        content: Text('Вы уверены, что хотите удалить вещь #$itemId?', 
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _showLoadingMessage('Удаление...');

      try {
        final success = await widget.api.deleteVeschi(itemId);
        
        if (success) {
          _showMessage('Удалено!');
          _refreshData();
        } else {
          _showMessage('Ошибка удаления', isError: true);
        }
      } catch (e) {
        _showMessage('Ошибка: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        

        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.red, Colors.orange, Colors.yellow],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: const Text(
              'БАЗАР-ВОКЗАЛ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            // НОВОЕ: Меню фильтра колонок
            ColumnFilterMenu(
              columnVisibility: _columnVisibility,
              onVisibilityChanged: _onColumnVisibilityChanged,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: _refreshData,
              tooltip: 'Обновить данные',
            ),
          ],
        ),
          






        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A2A),
                Color(0xFF1A0A2A),
              ],
            ),
          ),
          child: FutureBuilder<List<dynamic>>(
            future: _futureVeschi,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 16),
                      Text('Загрузка данных...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Ошибка загрузки', style: TextStyle(color: Colors.white, fontSize: 20)),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: _refreshData,
                        label: const Text('Повторить', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final veschi = snapshot.data ?? [];
              if (veschi.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Нет данных', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addNewVesch,
                        label: const Text('Добавить первую вещь', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              _initializeControllers(veschi);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,





                  child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    dataRowMinHeight: 70,
                    dataRowMaxHeight: 90,
                    headingTextStyle: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    dataTextStyle: const TextStyle(color: Colors.white),
                    columns: _getVisibleColumns(), // ИСПОЛЬЗУЕМ НОВЫЙ МЕТОД
                    rows: veschi.map((item) {
                      final id = item['id'] as int;
                      final dateIso = item['date'] ?? '';
                      
                      final veschFotoUrl = _getImageUrl(_getAcfValue(item, 'vesch-foto'));
                      final userPhotoUrl = _getImageUrl(_getAcfValue(item, 'photo'));
                      
                      final hasVeschFoto = veschFotoUrl.isNotEmpty;
                      final hasUserPhoto = userPhotoUrl.isNotEmpty;

                      return DataRow(

                        cells: _getVisibleCells( // ИСПОЛЬЗУЕМ НОВЫЙ МЕТОД
                          id: id,
                          veschFotoUrl: veschFotoUrl,
                          hasVeschFoto: hasVeschFoto,
                          userPhotoUrl: userPhotoUrl,
                          hasUserPhoto: hasUserPhoto,
                          dateIso: dateIso,
                        ),
                      
                      
                      );
                    }).toList(),
                  ),
                
                
                
                
                
                ),
              );
            },
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _addNewVesch,
            tooltip: 'Добавить новую вещь',
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

// НОВОЕ: Состояние видимости колонок
  Map<String, bool> _columnVisibility = {
    'id': true,
    'veschFoto': true,
    'veschName': true,
    'userPhoto': true,
    'nickname': true,
    'file': true,
    'timer': true,
    'actions': true,
  };

  // НОВЫЙ МЕТОД: Обработчик изменения видимости
  void _onColumnVisibilityChanged(Map<String, bool> newVisibility) {
    setState(() {
      _columnVisibility = newVisibility;
    });
  }

  // НОВЫЙ МЕТОД: Получить видимые колонки
  List<DataColumn> _getVisibleColumns() {
    final columns = <DataColumn>[];
    
    if (_columnVisibility['id'] == true) {
      columns.add(const DataColumn(label: Text('ID')));
    }
    if (_columnVisibility['veschFoto'] == true) {
      columns.add(const DataColumn(label: Text('Фото\nВещи')));
    }
    if (_columnVisibility['veschName'] == true) {
      columns.add(const DataColumn(label: Text('Название\nВещи')));
    }
    if (_columnVisibility['userPhoto'] == true) {
      columns.add(const DataColumn(label: Text('Фото\nЮзера')));
    }
    if (_columnVisibility['nickname'] == true) {
      columns.add(const DataColumn(label: Text('Прозвище')));
    }
    if (_columnVisibility['file'] == true) {
      columns.add(const DataColumn(label: Text('Файл')));
    }
    if (_columnVisibility['timer'] == true) {
      columns.add(const DataColumn(label: Text('Время - Деньги')));
    }
    if (_columnVisibility['actions'] == true) {
      columns.add(const DataColumn(label: Text('Действия')));
    }
    
    return columns;
  }

  // НОВЫЙ МЕТОД: Получить видимые ячейки
  List<DataCell> _getVisibleCells({
    required int id,
    required String veschFotoUrl,
    required bool hasVeschFoto,
    required String userPhotoUrl,
    required bool hasUserPhoto,
    required String dateIso,
  }) {
    final cells = <DataCell>[];
    
    if (_columnVisibility['id'] == true) {
      cells.add(DataCell(
        Text(id.toString(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ));
    }
    if (_columnVisibility['veschFoto'] == true) {
      cells.add(DataCell(
        EditableImage(
          imageUrl: veschFotoUrl,
          hasImage: hasVeschFoto,
          onTap: () => _onImageTap(id, 'vesch-foto', veschFotoUrl, hasVeschFoto),
          onEdit: () => _onImageEdit(id, 'vesch-foto'),
          size: 56,
          borderRadius: 12, // Ваше значение скругления
        ),
      ));
    }
    if (_columnVisibility['veschName'] == true) {
      cells.add(DataCell(
        SizedBox(
          width: 130,
          child: TextField(
            controller: _veschNameControllers[id],
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            maxLines: 2,
          ),
        ),
      ));
    }
    if (_columnVisibility['userPhoto'] == true) {
      cells.add(DataCell(
        EditableImage(
          imageUrl: userPhotoUrl,
          hasImage: hasUserPhoto,
          onTap: () => _onImageTap(id, 'photo', userPhotoUrl, hasUserPhoto),
          onEdit: () => _onImageEdit(id, 'photo'),
          size: 56,
          borderRadius: 12, // Ваше значение скругления
        ),
      ));
    }
    if (_columnVisibility['nickname'] == true) {
      cells.add(DataCell(
        SizedBox(
          width: 90,
          child: TextField(
            controller: _nicknameControllers[id],
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
          ),
        ),
      ));
    }
    if (_columnVisibility['file'] == true) {
      cells.add(DataCell(
        FileUploadWidget(
          fileUrl: _custFileUrls[id],
          fileName: _custFileNames[id],
          hasFile: _custFileIds.containsKey(id) && _custFileIds[id] != null,
          onTap: () => _showFileManagementDialog(id),
          onUpload: () => _showFileSourceDialog(id),
          onDownload: () => _downloadFile(id),
          onDelete: () => _deleteFile(id),
          size: 40,
        ),
      ));
    }
    if (_columnVisibility['timer'] == true) {
      cells.add(DataCell(
        Container(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatSmartDate(dateIso),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimer(dateIso),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.yellow,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ));
    }
    if (_columnVisibility['actions'] == true) {
      cells.add(DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.save, color: Colors.white, size: 18),
                onPressed: () => _saveChanges(id),
                tooltip: 'Сохранить',
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () => _deleteItem(id),
                tooltip: 'Удалить',
              ),
            ),
          ],
        ),
      ));
    }
    
    return cells;
  }
}