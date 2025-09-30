import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // NOTE: For real device, use your PC's local IP address below (e.g., 192.168.0.105)
  static const String baseUrl ='http://127.0.0.1:8000'; // <-- Change this to your actual PC IP

  Future<String?> registerUser(String username, String email, String password) async {
    print("$username $email $password");
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      })
    );
    if (response.statusCode == 200) {
      return null; // Success
    } else {
      return jsonDecode(response.body)['detail']; 
      print("error");
    }
  }

  Future<String?> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      // Save token, go to homepage
      return null;
    } else {
      return jsonDecode(response.body)['detail']; // Error message
    }
  }
}
