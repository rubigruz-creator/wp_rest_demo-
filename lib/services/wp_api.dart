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
        print('Ошибка загрузки данных: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки вещей: $e');
    }
  }

  // Метод для сохранения изменений в вещи
  Future<bool> updateVeschi(int id, Map<String, dynamic> data) async {
    try {
      print('=== ОТЛАДКА API: Отправка данных ===');
      print('URL: $baseUrl/wp-json/wp/v2/veschi/$id');
      print('Данные для отправки: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(data),
      );

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Успешное обновление записи $id');
        return true;
      } else {
        print('❌ Ошибка обновления: ${response.statusCode}');
        
        // Парсим ошибку для лучшего понимания
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            print('Сообщение об ошибке: ${errorData['message']}');
          }
          if (errorData is Map && errorData.containsKey('code')) {
            print('Код ошибки: ${errorData['code']}');
          }
        } catch (e) {
          print('Не удалось распарсить ошибку: $e');
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Исключение при сохранении: $e');
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

      print('Статус удаления: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Успешное удаление записи $id');
        return true;
      } else {
        print('❌ Ошибка удаления: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Исключение при удалении: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadImage(File imageFile, String fileName) async {
    try {
      print('=== Начало загрузки изображения ===');
      print('Файл: ${imageFile.path}');
      print('Имя файла: $fileName');
      
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

      print('Статус загрузки изображения: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        print('✅ Изображение успешно загружено');
        final imageData = json.decode(responseData);
        print('ID загруженного изображения: ${imageData['id']}');
        return imageData;
      } else {
        print('❌ Ошибка загрузки изображения: ${response.statusCode}');
        print('Тело ответа: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Исключение при загрузке изображения: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createVeschi(Map<String, dynamic> data) async {
    try {
      print('=== Создание новой вещи ===');
      print('Данные: ${json.encode(data)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(data),
      );

      print('Статус создания: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        print('✅ Новая вещь успешно создана');
        return json.decode(response.body);
      } else {
        print('❌ Ошибка создания: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Исключение при создании: $e');
      return null;
    }
  }
}