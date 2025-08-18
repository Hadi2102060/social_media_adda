import 'dart:convert';
import 'package:http/http.dart' as http;

class StoryService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<bool> uploadStory(String token, String userId, String username, String mediaUrl, String mediaType, DateTime expiresAt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stories?user_id=$userId&username=$username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'media_url': mediaUrl,
        'media_type': mediaType,
        'expires_at': expiresAt.toIso8601String(),
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getStories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stories'),
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

  Future<bool> viewStory(String token, String storyId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stories/$storyId/view?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteStory(String token, String storyId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/stories/$storyId?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> uploadReel(String token, String userId, String username, String videoUrl, String caption) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reels?user_id=$userId&username=$username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'video_url': videoUrl,
        'caption': caption,
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getReels(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reels'),
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