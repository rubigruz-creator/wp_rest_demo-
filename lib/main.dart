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

class PostsScreen extends StatefulWidget {
  final WPApi api;
  const PostsScreen({super.key, required this.api});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}


class VeschiScreen extends StatefulWidget {
  final WPApi api;
  const VeschiScreen({super.key, required this.api});

  @override
  State<VeschiScreen> createState() => _VeschiScreenState();
}

class _VeschiScreenState extends State<VeschiScreen> {
  late Future<List<dynamic>> _futureVeschi;

  @override
  void initState() {
    super.initState();
    _futureVeschi = widget.api.fetchVeschi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Таблица Вещи')),
      body: FutureBuilder<List<dynamic>>(
        future: _futureVeschi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final veschi = snapshot.data ?? [];

          if (veschi.isEmpty) {
            return const Center(child: Text('Нет данных в таблице.'));
          }

          return ListView.builder(
            itemCount: veschi.length,
            itemBuilder: (context, index) {
              final item = veschi[index];
              final name = item['title']?['rendered'] ?? 'Без имени';
              final acf = item['acf'] ?? {};
              final opisanie = acf['opisanie'] ?? '';
              final foto = acf['foto'] ?? '';

              return ListTile(
                leading: foto != ''
                    ? Image.network(foto, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.inventory_2_outlined),
                title: Text(name),
                subtitle: Text(opisanie),
              );
            },
          );
        },
      ),
    );
  }
}










class _PostsScreenState extends State<PostsScreen> {
  late Future<List<dynamic>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _futurePosts = widget.api.fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список постов wwwwww002')),
      body: FutureBuilder<List<dynamic>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final title = post['title']?['rendered'] ?? 'Без названия';
              final date = post['date'] ?? '';
              final acf = post['acf'] ?? {};
              final desc = acf['opisanie'] ?? '';

              return ListTile(
                title: Text(title),
                subtitle: Text('$desc\n$date'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
