import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<dynamic>> getNotifications(String token, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications?user_id=$userId'),
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

  Future<bool> markAsRead(String token, String notifId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notifId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  WebSocketChannel connectToNotification(String userId) {
    return WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/notifications/$userId'),
    );
  }
} 