import 'package:flutter/material.dart';
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

  // Функция для форматирования таймера
  String _formatTimer(String dateIso) {
    try {
      final created = DateTime.parse(dateIso);
      final now = DateTime.now();
      final diff = now.difference(created);
      
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);
      
      return '$hoursч $minutesм $secondsс';
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
                  final id = item['id']?.toString() ?? '0';
                  final dateIso = item['date'] ?? '';
                  
                  // Получаем ACF поля
                  final veschName = _getAcfValue(item, 'vesch-name').toString();
                  final veschFoto = _getAcfValue(item, 'vesch-foto');
                  final userPhoto = _getAcfValue(item, 'photo');
                  final nickname = _getAcfValue(item, 'nickname').toString();
                  
                  // Получаем URL изображений
                  final veschFotoUrl = _getImageUrl(veschFoto);
                  final userPhotoUrl = _getImageUrl(userPhoto);
                  
                  // Форматируем дату
                  String formattedDate = '';
                  try {
                    final date = DateTime.parse(dateIso);
                    formattedDate = '${date.day}.${date.month}.${date.year}\n${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                  } catch (e) {
                    formattedDate = 'Ошибка даты';
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(veschFotoUrl),
                          onBackgroundImageError: (exception, stackTrace) => 
                              const Icon(Icons.error),
                          child: veschFotoUrl == placeholderImage 
                              ? const Icon(Icons.inventory_2_outlined, size: 24)
                              : null,
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            veschName.isEmpty ? 'Без названия' : veschName,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(userPhotoUrl),
                          onBackgroundImageError: (exception, stackTrace) => 
                              const Icon(Icons.error),
                          child: userPhotoUrl == placeholderImage 
                              ? const Icon(Icons.person_outline, size: 24)
                              : null,
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: Text(
                            nickname.isEmpty ? '—' : nickname,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
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
                              onPressed: () {
                                // TODO: Реализовать сохранение
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Сохранение записи $id')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // TODO: Реализовать удаление
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Удаление записи $id')),
                                );
                              },
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
        onPressed: () {
          // TODO: Реализовать добавление новой вещи
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Добавление новой вещи')),
          );
        },
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
    // Запускаем обновление таймера каждую секунду
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
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