import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class WPApi {
  final String baseUrl;

  WPApi(this.baseUrl);

  final String jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vZ2F6b25iYXphLnJ1IiwiaWF0IjoxNzYyMzI4MjI2LCJuYmYiOjE3NjIzMjgyMjYsImV4cCI6MTc2MjkzMzAyNiwiZGF0YSI6eyJ1c2VyIjp7ImlkIjoiMSJ9fX0.Fpb6nwBI96apfZvXDW_ep8h30eqp0IDDSUGZuWJKavk';

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

  // УПРОЩЕННЫЙ МЕТОД: Сохранение изменений в вещи
  Future<bool> updateVeschi(int id, Map<String, dynamic> data) async {
    try {
      print('=== ОТЛАДКА API: Отправка данных ===');
      print('URL: $baseUrl/wp-json/wp/v2/veschi/$id');
      print('Данные: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(data),
      );

      print('Ответ сервера: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Исключение при сохранении: $e');
      return false;
    }
  }

  Future<bool> deleteVeschi(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id?force=true'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Исключение при удалении: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadImage(File imageFile, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/wp-json/wp/v2/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $jwtToken';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: fileName,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        print('Ошибка загрузки изображения: ${response.statusCode}');
        print('Тело ответа: $responseData');
        return null;
      }
    } catch (e) {
      print('Исключение при загрузке изображения: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createVeschi(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Ошибка создания: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Исключение при создании: $e');
      return null;
    }
  }

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