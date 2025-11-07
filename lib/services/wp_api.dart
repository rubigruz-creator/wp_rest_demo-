import 'dart:convert';
import 'package:http/http.dart' as http;

class WPApi {
  final String baseUrl;

  WPApi(this.baseUrl);

  // Твой JWT токен (позже вынесем в настройки)
  final String jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vZ2F6b25iYXphLnJ1IiwiaWF0IjoxNzYyMjY4NjQzLCJuYmYiOjE3NjIyNjg2NDMsImV4cCI6MTc2Mjg3MzQ0MywiZGF0YSI6eyJ1c2VyIjp7ImlkIjoiMSJ9fX0.g_1kXAZf5hiPO_3d25n749JD9hvC_OrGv34OWqrzlBk';

  Future<List<dynamic>> fetchVeschi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi?_fields=id,date,acf,title'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки вещей: $e');
    }
  }

  // Старый метод для постов (оставим на всякий случай)
  Future<List<dynamic>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wp-json/wp/v2/posts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки постов: $e');
    }
  }
}