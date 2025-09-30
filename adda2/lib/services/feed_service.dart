import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Change if needed

  Future<List<dynamic>> getFeed(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feed'),
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

  Future<bool> createPost(String token, String userId, String username, String caption, {String? imageUrl, String? videoUrl}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts?user_id=$userId&username=$username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'caption': caption,
        if (imageUrl != null) 'image_url': imageUrl,
        if (videoUrl != null) 'video_url': videoUrl,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> likePost(String token, String postId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> unlikePost(String token, String postId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/unlike?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> addComment(String token, String postId, String userId, String username, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments?user_id=$userId&username=$username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text, 'post_id': postId}),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getComments(String token, String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
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