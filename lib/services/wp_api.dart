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

  Future<bool> updateVeschi(int id, Map<String, dynamic> data) async {
    try {
      print('=== ОТПРАВКА НА СЕРВЕР ДЛЯ ACF ===');
      print('URL: $baseUrl/wp-json/wp/v2/veschi/$id');
      print('ID: $id');
      print('Полные данные: ${json.encode(data)}');
      
      // Детальный разбор ACF данных
      if (data['acf'] != null) {
        print('=== ДЕТАЛИ ACF ПОЛЕЙ ===');
        data['acf'].forEach((key, value) {
          print('$key: $value (type: ${value.runtimeType})');
        });
      }
      
      // Для ACF полей используем fields параметр
      final Map<String, dynamic> postData = {
        'fields': data['acf'] // ACF ожидает поля в разделе 'fields'
      };
      
      print('Данные для отправки (fields): ${json.encode(postData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(postData),
      );

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ УСПЕШНО сохранено на сервере');
        
        // Парсим ответ для проверки
        try {
          final responseData = json.decode(response.body);
          final acfFields = responseData['acf'] ?? {};
          print('=== ПРОВЕРКА СОХРАНЕННЫХ ДАННЫХ ===');
          print('vesch-name: ${acfFields['vesch-name']}');
          print('nickname: ${acfFields['nickname']}');
          print('vesch-foto: ${acfFields['vesch-foto']}');
          print('photo: ${acfFields['photo']}');
          print('cust-files: ${acfFields['cust-files']}');
        } catch (e) {
          print('Не удалось распарсить ответ для проверки: $e');
        }
        
        return true;
      } else {
        print('❌ ОШИБКА сервера: ${response.statusCode}');
        try {
          final errorData = json.decode(response.body);
          print('Детали ошибки: $errorData');
        } catch (e) {
          print('Не удалось распарсить ошибку');
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

  // НОВЫЙ МЕТОД ДЛЯ ЗАГРУЗКИ ФАЙЛОВ (ИСПРАВЛЕННЫЙ)
  Future<Map<String, dynamic>?> uploadFile(File file, String fileName) async {
    try {
      print('=== Начало загрузки файла ===');
      print('Файл: ${file.path}');
      print('Имя файла: $fileName');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/wp-json/wp/v2/media'),
      );
      
      request.headers['Authorization'] = 'Bearer $jwtToken';
      
      // ПРОСТАЯ ЗАГРУЗКА БЕЗ MIME-TYPE
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
      
      if (response.statusCode == 201) {
        print('✅ Файл успешно загружен');
        final fileData = json.decode(responseData);
        print('ID загруженного файла: ${fileData['id']}');
        print('URL файла: ${fileData['source_url']}');
        return fileData;
      } else {
        print('❌ Ошибка загрузки файла: ${response.statusCode}');
        print('Тело ответа: $responseData');
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
        print('Тело ответа: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Исключение при удалении файла: $e');
      return false;
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