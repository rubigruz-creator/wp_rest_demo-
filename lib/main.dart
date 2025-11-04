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
      home: PostsScreen(api: api),
    );
  }
}

class PostsScreen extends StatefulWidget {
  final WPApi api;
  const PostsScreen({super.key, required this.api});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
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
      appBar: AppBar(title: const Text('Список постов wwwwww001')),
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
