import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/wp_api.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final WPApi api = WPApi('http://gazonbaza.ru');

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WP Rest Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: VeschiScreen(api: api),
    );
  }
}

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

  // Глобальный ключ для безопасных сообщений
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Оптимизированная загрузка данных
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

  // Простая функция для показа сообщений
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Простая функция для показа сообщения о загрузке
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
      
      // Инициализируем только если контроллеры еще не созданы
      if (!_veschNameControllers.containsKey(id)) {
        final veschName = _getAcfValue(item, 'vesch-name').toString();
        _veschNameControllers[id] = TextEditingController(text: veschName);
      }
      
      if (!_nicknameControllers.containsKey(id)) {
        final nickname = _getAcfValue(item, 'nickname').toString();
        _nicknameControllers[id] = TextEditingController(text: nickname);
      }
      
      // Всегда обновляем ID изображений из свежих данных
      final veschFoto = _getAcfValue(item, 'vesch-foto');
      final userPhoto = _getAcfValue(item, 'photo');
      
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
    }
  }

  // НОВАЯ ФУНКЦИЯ: Форматирование таймера по новому формату
  String _formatTimer(String dateIso) {
    try {
      final created = DateTime.parse(dateIso);
      final now = DateTime.now();
      final diff = now.difference(created);
      
      final days = diff.inDays;
      final hours = diff.inHours.remainder(24);
      final minutes = diff.inMinutes.remainder(60);
      
      // Форматируем по новому формату: Дни - д, Часы - $, Минуты - ¢
      return '${days}д : ${hours}\$ : ${minutes}¢';
    } catch (e) {
      return '0д : 0\$ : 0¢';
    }
  }

  // НОВАЯ ФУНКЦИЯ: Умное форматирование даты
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
        // Форматируем дату: день.месяц.год час:минуты
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
      return ''; // Пустая строка вместо внешнего URL
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

  // Функция для выбора источника
  Future<void> _showImageSourceDialog(int itemId, String fieldType) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите источник ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(itemId, fieldType, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Камера'),
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

  // Оптимизированная функция загрузки изображения
  Future<void> _pickAndUploadImage(int itemId, String fieldType, ImageSource source) async {
    try {
      _showLoadingMessage('${source == ImageSource.camera ? 'Съемка' : 'Загрузка'} ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}...');

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400, // Еще меньше для скорости
        maxHeight: 400,
        imageQuality: 60, // Еще меньше качество
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
          
          // Сохраняем изменения и ОБНОВЛЯЕМ данные
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

  // Оптимизированная функция сохранения
  Future<void> _saveChanges(int itemId, {bool showMessage = true, bool shouldRefresh = false}) async {
    final veschName = _veschNameControllers[itemId]?.text ?? '';
    final nickname = _nicknameControllers[itemId]?.text ?? '';
    
    if (showMessage) {
      _showLoadingMessage('Сохранение...');
    }

    try {
      final Map<String, dynamic> updateData = {
        'acf': {
          'vesch_name': veschName,
          'nickname': nickname,
        }
      };

      // Преобразуем ID в строки
      if (_veschFotoIds.containsKey(itemId) && _veschFotoIds[itemId] != null) {
        final imageId = _veschFotoIds[itemId]!;
        updateData['acf']!['vesch_foto'] = imageId.toString();
        updateData['acf']!['vesch-foto'] = imageId.toString();
      }
      
      if (_userPhotoIds.containsKey(itemId) && _userPhotoIds[itemId] != null) {
        final imageId = _userPhotoIds[itemId]!;
        updateData['acf']!['photo'] = imageId.toString();
      }

      final success = await widget.api.updateVeschi(itemId, updateData);
      
      if (showMessage) {
        if (success) {
          _showMessage('Сохранено!');
          
          // ОБНОВЛЯЕМ данные если нужно
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

  // Функция добавления
  Future<void> _addNewVesch() async {
    try {
      _showLoadingMessage('Создание новой вещи...');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultTitle = "Вещь $timestamp";

      final newVeschData = {
        'title': defaultTitle,
        'status': 'publish',
        'acf': {
          'vesch_name': defaultTitle,
          'nickname': '',
        }
      };

      final createdVesch = await widget.api.createVeschi(newVeschData);

      if (createdVesch != null) {
        _showMessage('Новая вещь создана!');
        _refreshData(); // Авто-обновление
      } else {
        _showMessage('Ошибка создания', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  // Функция удаления
  Future<void> _deleteItem(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить вещь?'),
        content: Text('Вы уверены, что хотите удалить вещь #$itemId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
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
          _refreshData(); // Авто-обновление
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
          title: const Text('Таблица Вещей'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Обновить данные',
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _futureVeschi,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Загрузка данных...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshData,
                      label: const Text('Повторить'),
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
                    const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Нет данных'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      onPressed: _addNewVesch,
                      label: const Text('Добавить первую вещь'),
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
                  columns: const [
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Фото\nВещи', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Название\nВещи', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Фото\nЮзера', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Прозвище', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Время - Деньги', style: TextStyle(fontWeight: FontWeight.bold))), // ОБЪЕДИНЕННАЯ КОЛОНКА
                    DataColumn(label: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: veschi.map((item) {
                    final id = item['id'] as int;
                    final dateIso = item['date'] ?? '';
                    
                    final veschFotoUrl = _getImageUrl(_getAcfValue(item, 'vesch-foto'));
                    final userPhotoUrl = _getImageUrl(_getAcfValue(item, 'photo'));
                    
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataCell(
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(id, 'vesch-foto'),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: veschFotoUrl.isNotEmpty 
                                  ? NetworkImage(veschFotoUrl) 
                                  : null,
                              child: veschFotoUrl.isEmpty 
                                  ? const Icon(Icons.add_a_photo, size: 20, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: _veschNameControllers[id],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(id, 'photo'),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: userPhotoUrl.isNotEmpty 
                                  ? NetworkImage(userPhotoUrl) 
                                  : null,
                              child: userPhotoUrl.isEmpty 
                                  ? const Icon(Icons.add_a_photo, size: 20, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: _nicknameControllers[id],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        // ОБЪЕДИНЕННАЯ ЯЧЕЙКА: Дата и Таймер
                        DataCell(
                          Container(
                            width: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Верхняя строка: Умная дата
                                Text(
                                  _formatSmartDate(dateIso),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // Нижняя строка: Таймер в новом формате
                                Text(
                                  _formatTimer(dateIso),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.save, color: Colors.green, size: 20),
                                onPressed: () => _saveChanges(id),
                                tooltip: 'Сохранить',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteItem(id),
                                tooltip: 'Удалить',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewVesch,
          tooltip: 'Добавить новую вещь',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// Обновленный виджет таймера
class TimerWidget extends StatefulWidget {
  final String dateIso;
  final String Function(String) formatTimer;

  const TimerWidget({
    super.key,
    required this.dateIso,
    required this.formatTimer,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.formatTimer(widget.dateIso),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
    );
  }
}