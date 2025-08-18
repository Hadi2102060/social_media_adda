import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class MessagingService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<dynamic>> getConversations(String token, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations?user_id=$userId'),
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

  Future<bool> createConversation(String token, List<String> userIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'user_ids': userIds}),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getMessages(String token, String conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$conversationId'),
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

  Future<bool> sendMessage(String token, String conversationId, String senderId, String senderUsername, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages?sender_id=$senderId&sender_username=$senderUsername'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'conversation_id': conversationId, 'text': text}),
    );
    return response.statusCode == 200;
  }

  WebSocketChannel connectToChat(String conversationId) {
    return WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/chat/$conversationId'),
    );
  }
} 