import 'package:flutter/material.dart';
import '../services/messaging_service.dart';

class MessagingProvider with ChangeNotifier {
  final MessagingService _messagingService = MessagingService();
  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  bool _loading = false;
  String? _error;
  List<dynamic> get conversations => _conversations;
  List<dynamic> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchConversations(String token, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _messagingService.getConversations(token, userId);
    } catch (e) {
      _error = "Failed to load conversations: $e";
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String token, String conversationId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _messagingService.getMessages(token, conversationId);
    } catch (e) {
      _error = "Failed to load messages: $e";
    }
    _loading = false;
    notifyListeners();
  }
} 