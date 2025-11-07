import 'dart:convert';
import 'package:http/http.dart' as http;

class WPApi {
  final String baseUrl;
  String? _token;

  WPApi(this.baseUrl);

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<List<dynamic>> fetchPosts() async {
    final url = Uri.parse('$baseUrl/wp-json/wp/v2/veschi?_fields=id,title,acf,date,author');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return json.decode(resp.body);
    } else {
      throw Exception('Ошибка загрузки: ${resp.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchPost(int id) async {
    final url = Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id/?_fields=acf,title,author');
    final resp = await http.get(url, headers: _headers());
    if (resp.statusCode == 200) {
      return json.decode(resp.body);
    } else {
      throw Exception('Ошибка загрузки поста: ${resp.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updatePost(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/wp-json/wp/v2/veschi/$id');
    final resp = await http.post(url, headers: _headers(), body: json.encode(data));
    if (resp.statusCode == 200) {
      return json.decode(resp.body);
    } else {
      throw Exception('Ошибка обновления: ${resp.statusCode}');
    }
  }

  Future<List<dynamic>> fetchVeschi() async {
    final response = await http.get(Uri.parse('$baseUrl/wp-json/wp/v2/veschi'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Ошибка загрузки veschi: ${response.statusCode}');
    }
  }







}
