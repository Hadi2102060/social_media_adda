import 'package:flutter/material.dart';
import '../services/feed_service.dart';

class FeedProvider with ChangeNotifier {
  final FeedService _feedService = FeedService();
  List<dynamic> _feed = [];
  bool _loading = false;
  String? _error;
  List<dynamic> get feed => _feed;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchFeed(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _feed = await _feedService.getFeed(token);
    } catch (e) {
      _error = "Failed to load feed: $e";
    }
    _loading = false;
    notifyListeners();
  }
} 