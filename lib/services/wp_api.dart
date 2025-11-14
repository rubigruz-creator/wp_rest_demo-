import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class WPApi {
  final String baseUrl;

  WPApi(this.baseUrl);

  final String jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vZ2F6b25iYXphLnJ1IiwiaWF0IjoxNzYyOTUwODQyLCJuYmYiOjE3NjI5NTA4NDIsImV4cCI6MTc2MzU1NTY0MiwiZGF0YSI6eyJ1c2VyIjp7ImlkIjoiMSJ9fX0.lbN1wkMpvv9Y7PMdSHPjbob-yNQ2gh6uIKQdo9B6rTM';

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

  Future<bool> updateVeschi(int id, Map<String, dynamic> data) async {
    try {
      print('=== ОТПРАВКА НА СЕРВЕР ДЛЯ ACF ===');
      print('URL: $baseUrl/wp-json/wp/v2/veschi/$id');
      print('ID: $id');
      print('Полные данные: ${json.encode(data)}');
      
      final Map<String, dynamic> postData = {
        'fields': data['acf']
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(postData),
      );

      print('Статус ответа: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ УСПЕШНО сохранено на сервере');
        return true;
      } else {
        print('❌ ОШИБКА сервера: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
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

  Future<Map<String, dynamic>?> uploadFile(File file, String fileName) async {
    try {
      print('=== Начало загрузки файла ===');
      print('Файл: ${file.path}');
      print('Размер файла: ${file.lengthSync()} байт');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/wp-json/wp/v2/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $jwtToken';
      
      // Добавляем файл с правильным именем
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('Статус загрузки файла: ${response.statusCode}');
      print('Ответ сервера: $responseData');
      
      if (response.statusCode == 201) {
        print('✅ Файл успешно загружен');
        final fileData = json.decode(responseData);
        print('ID загруженного файла: ${fileData['id']}');
        print('URL файла: ${fileData['source_url']}');
        return fileData;
      } else {
        print('❌ Ошибка загрузки файла: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Исключение при загрузке файла: $e');
      return null;
    }
  }

  Future<bool> deleteFile(int fileId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wp-json/wp/v2/media/$fileId?force=true'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      print('Статус удаления файла: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Файл успешно удален');
        return true;
      } else {
        print('❌ Ошибка удаления файла: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Исключение при удалении файла: $e');
      return false;
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

      print('Статус создания: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        print('✅ Новая вещь успешно создана');
        return json.decode(response.body);
      } else {
        print('❌ Ошибка создания: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Исключение при создании: $e');
      return null;
    }
  }
}