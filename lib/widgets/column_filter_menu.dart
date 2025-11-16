import 'package:flutter/material.dart';

class ColumnFilterMenu extends StatefulWidget {
  final Map<String, bool> columnVisibility;
  final ValueChanged<Map<String, bool>> onVisibilityChanged;

  const ColumnFilterMenu({
    super.key,
    required this.columnVisibility,
    required this.onVisibilityChanged,
  });

  @override
  State<ColumnFilterMenu> createState() => _ColumnFilterMenuState();
}

class _ColumnFilterMenuState extends State<ColumnFilterMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list, color: Colors.orange),
      tooltip: 'Фильтр колонок',
      onSelected: (value) {
        _handleMenuSelection(value);
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'show_all',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.green),
              SizedBox(width: 8),
              Text('Показать все колонки'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'hide_all',
          child: Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Скрыть все колонки'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ..._buildColumnMenuItems(),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildColumnMenuItems() {
    return widget.columnVisibility.entries.map((entry) {
      return PopupMenuItem<String>(
        value: entry.key,
        child: Row(
          children: [
            Icon(
              entry.value ? Icons.check_box : Icons.check_box_outline_blank,
              color: entry.value ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              _getColumnLabel(entry.key),
              style: TextStyle(
                color: entry.value ? Colors.black : Colors.grey,
                fontWeight: entry.value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _handleMenuSelection(String value) {
    final newVisibility = Map<String, bool>.from(widget.columnVisibility);

    switch (value) {
      case 'show_all':
        for (var key in newVisibility.keys) {
          newVisibility[key] = true;
        }
        break;
      case 'hide_all':
        for (var key in newVisibility.keys) {
          newVisibility[key] = false;
        }
        break;
      default:
        // Переключаем конкретную колонку
        if (newVisibility.containsKey(value)) {
          newVisibility[value] = !newVisibility[value]!;
        }
    }

    widget.onVisibilityChanged(newVisibility);
  }

  String _getColumnLabel(String key) {
    final labels = {
      'id': 'ID',
      'veschFoto': 'Фото Вещи',
      'veschName': 'Название Вещи',
      'userPhoto': 'Фото Юзера',
      'nickname': 'Прозвище',
      'file': 'Файл',
      'timer': 'Время - Деньги',
      'actions': 'Действия',
    };
    return labels[key] ?? key;
  }
}