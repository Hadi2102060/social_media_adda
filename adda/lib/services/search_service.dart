import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<dynamic>> searchUsers(String token, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/users?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> searchPosts(String token, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/posts?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> searchHashtags(String token, String tag) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/hashtags?tag=$tag'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
} 