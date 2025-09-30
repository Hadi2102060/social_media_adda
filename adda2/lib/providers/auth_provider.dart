import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  String? get token => _token;
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.loginUser(username, password);
      if (result != null) {
        _token = result;
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Invalid credentials";
      }
    } catch (e) {
      _error = "Login failed: $e";
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _token = null;
    notifyListeners();
  }
} 