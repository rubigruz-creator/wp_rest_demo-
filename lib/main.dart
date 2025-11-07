import 'dart:convert'; // ДОБАВИТЬ ЭТОТ ИМПОРТ
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
  final String placeholderImage = 'https://via.placeholder.com/64?text=No+Photo';
  final ImagePicker _imagePicker = ImagePicker();
  
  // Контроллеры для редактирования текста
  final Map<int, TextEditingController> _veschNameControllers = {};
  final Map<int, TextEditingController> _nicknameControllers = {};
  
  // Храним ID загруженных изображений
  final Map<int, int> _veschFotoIds = {};
  final Map<int, int> _userPhotoIds = {};

  @override
  void initState() {
    super.initState();
    _futureVeschi = widget.api.fetchVeschi();
  }

  void _refreshData() {
    setState(() {
      _futureVeschi = widget.api.fetchVeschi();
    });
  }

  // Инициализация контроллеров когда данные загружены
  void _initializeControllers(List<dynamic> veschi) {
    _veschNameControllers.clear();
    _nicknameControllers.clear();
    _veschFotoIds.clear();
    _userPhotoIds.clear();
    
    for (final item in veschi) {
      final id = item['id'] as int;
      final veschName = _getAcfValue(item, 'vesch-name').toString();
      final nickname = _getAcfValue(item, 'nickname').toString();
      
      _veschNameControllers[id] = TextEditingController(text: veschName);
      _nicknameControllers[id] = TextEditingController(text: nickname);
      
      // Сохраняем ID изображений если они есть
      final veschFoto = _getAcfValue(item, 'vesch-foto');
      final userPhoto = _getAcfValue(item, 'photo');
      
      if (veschFoto != null && veschFoto != '') {
        if (veschFoto is Map && veschFoto['id'] != null) {
          _veschFotoIds[id] = veschFoto['id'] as int;
        } else if (veschFoto is int) {
          _veschFotoIds[id] = veschFoto;
        } else if (veschFoto is String) {
          final intValue = int.tryParse(veschFoto);
          if (intValue != null) {
            _veschFotoIds[id] = intValue;
          }
        }
      }
      
      if (userPhoto != null && userPhoto != '') {
        if (userPhoto is Map && userPhoto['id'] != null) {
          _userPhotoIds[id] = userPhoto['id'] as int;
        } else if (userPhoto is int) {
          _userPhotoIds[id] = userPhoto;
        } else if (userPhoto is String) {
          final intValue = int.tryParse(userPhoto);
          if (intValue != null) {
            _userPhotoIds[id] = intValue;
          }
        }
      }
    }
  }

  // Функция для форматирования таймера
  String _formatTimer(String dateIso) {
    try {
      final created = DateTime.parse(dateIso);
      final now = DateTime.now();
      final diff = now.difference(created);
      
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);
      
      return '${hours}ч ${minutes}м ${seconds}с';
    } catch (e) {
      return '0ч 0м 0с';
    }
  }

  // Функция для получения ACF значения
  dynamic _getAcfValue(dynamic item, String fieldName) {
    if (item == null || item['acf'] == null) return '';
    
    final acf = item['acf'];
    final variants = [
      fieldName,
      fieldName.replaceAll('_', '-'),
      fieldName.replaceAll('-', '_'),
      fieldName.replaceAll(RegExp(r'[_-]'), '')
    ];
    
    for (final key in variants) {
      if (acf.containsKey(key) && acf[key] != null && acf[key] != '') {
        return acf[key];
      }
    }
    return '';
  }

  // Функция для получения URL изображения из ACF поля
  String _getImageUrl(dynamic imageField) {
    if (imageField == null) return placeholderImage;
    if (imageField is String) return imageField;
    if (imageField is Map && imageField['url'] != null) return imageField['url'];
    if (imageField is Map && imageField['source_url'] != null) return imageField['source_url'];
    return placeholderImage;
  }

  // Функция для выбора и загрузки изображения
  Future<void> _pickAndUploadImage(int itemId, String fieldType, BuildContext context) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                const SizedBox(width: 16),
                Text('Загрузка ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}...'),
              ],
            ),
          ),
        );

        final File imageFile = File(pickedFile.path);
        final fileName = '${fieldType}_${itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final uploadedImage = await widget.api.uploadImage(imageFile, fileName);
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (uploadedImage != null) {
          final imageId = uploadedImage['id'] as int;
          
          if (fieldType == 'vesch-foto') {
            _veschFotoIds[itemId] = imageId;
          } else {
            _userPhotoIds[itemId] = imageId;
          }
          
          await _saveChanges(itemId, context, showMessage: false);
          
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${fieldType == 'vesch-foto' ? 'Фото вещи' : 'Фото юзера'} обновлено!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки ${fieldType == 'vesch-foto' ? 'фото вещи' : 'фото юзера'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Функция для сохранения изменений
  Future<void> _saveChanges(int itemId, BuildContext context, {bool showMessage = true}) async {
    final veschName = _veschNameControllers[itemId]?.text ?? '';
    final nickname = _nicknameControllers[itemId]?.text ?? '';
    
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              Text('Сохранение записи $itemId...'),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    try {
      // Подготавливаем данные для отправки
      final Map<String, dynamic> updateData = {
        'acf': {
          'vesch-name': veschName,
          'nickname': nickname,
        }
      };

      // Добавляем ID изображений если они есть
      if (_veschFotoIds[itemId] != null) {
        updateData['acf']!['vesch-foto'] = _veschFotoIds[itemId].toString(); // ✅ приводим к строке
      }

      if (_userPhotoIds[itemId] != null) {
        updateData['acf']!['photo'] = _userPhotoIds[itemId].toString(); // ✅ тоже строка
      }


      // УБИРАЕМ json.encode из print - это может вызывать ошибку
      print('Отправляемые данные для $itemId: $updateData');

      // Отправляем на сервер
      final success = await widget.api.updateVeschi(itemId, updateData);
      
      if (showMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Запись $itemId успешно сохранена!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка сохранения записи $itemId'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      _refreshData();
      
    } catch (e) {
      if (showMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Ошибка при сохранении $itemId: $e');
    }
  }




  // Функция для добавления новой вещи
  Future<void> _addNewVesch(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              const Text('Создание новой вещи...'),
            ],
          ),
        ),
      );

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
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (createdVesch != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Новая вещь создана! ID: ${createdVesch['id']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка создания новой вещи'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Функция для удаления записи
  Future<void> _deleteItem(int itemId, BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              Text('Удаление записи $itemId...'),
            ],
          ),
        ),
      );

      try {
        final success = await widget.api.deleteVeschi(itemId);
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Запись $itemId успешно удалена!'),
              backgroundColor: Colors.green,
            ),
          );
          
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления записи $itemId'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица Вещи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureVeschi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка загрузки: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final veschi = snapshot.data ?? [];
          _initializeControllers(veschi);

          if (veschi.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Нет данных в таблице.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 8,
                dataRowMinHeight: 80,
                dataRowMaxHeight: 100,
                columns: const [
                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Фото\nВещи', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Название\nВещи', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Фото\nЮзера', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Прозвище', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Дата\nсоздания', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Таймер', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: veschi.map((item) {
                  final id = item['id'] as int;
                  final dateIso = item['date'] ?? '';
                  
                  final veschFoto = _getAcfValue(item, 'vesch-foto');
                  final userPhoto = _getAcfValue(item, 'photo');
                  
                  final veschFotoUrl = _getImageUrl(veschFoto);
                  final userPhotoUrl = _getImageUrl(userPhoto);
                  
                  String formattedDate = '';
                  try {
                    final date = DateTime.parse(dateIso);
                    formattedDate = '${date.day}.${date.month}.${date.year}\n${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                  } catch (e) {
                    formattedDate = 'Ошибка даты';
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        GestureDetector(
                          onTap: () => _pickAndUploadImage(id, 'vesch-foto', context),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(veschFotoUrl),
                            onBackgroundImageError: (exception, stackTrace) => 
                                const Icon(Icons.error),
                            child: veschFotoUrl == placeholderImage 
                                ? const Icon(Icons.inventory_2_outlined, size: 24)
                                : Stack(
                                    children: [
                                      Container(color: Colors.black38),
                                      const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 120,
                          child: TextField(
                            controller: _veschNameControllers[id],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            maxLines: 3,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _pickAndUploadImage(id, 'photo', context),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(userPhotoUrl),
                            onBackgroundImageError: (exception, stackTrace) => 
                                const Icon(Icons.error),
                            child: userPhotoUrl == placeholderImage 
                                ? const Icon(Icons.person_outline, size: 24)
                                : Stack(
                                    children: [
                                      Container(color: Colors.black38),
                                      const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          child: TextField(
                            controller: _nicknameControllers[id],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        TimerWidget(dateIso: dateIso, formatTimer: _formatTimer),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.save, color: Colors.green),
                              onPressed: () => _saveChanges(id, context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(id, context),
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
        onPressed: () => _addNewVesch(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Виджет для живого таймера
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
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
    );
  }
}