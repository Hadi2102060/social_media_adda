import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // NOTE: For real device, use your PC's local IP address below (e.g., 192.168.0.105)
  static const String baseUrl =
      'http://127.0.0.1:8000'; // <-- Change this to your actual PC IP

  Future<String?> registerUser(
    String username,
    String email,
    String password,
  ) async {
    print("$username $email $password");
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return null; // Success
    } else {
      return jsonDecode(response.body)['detail'];
    }
  }

  Future<String?> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return null; // Success
    } else {
      return jsonDecode(response.body)['detail']; // Error message
    }
  }
}

//   Future<String?> signInWithGoogle() async {
//     try {
//       // Start the Google sign-in process
//       final GoogleSignInAccount? googleUser = await GoogleSignIn
//           .signIn();

//       if (googleUser == null) {
//         // User canceled the sign-in process
//         return 'Sign-In canceled by user';
//       }

//       // Obtain authentication details from the Google account
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // Check if accessToken and idToken are null
//       if (googleAuth.accessToken == null || googleAuth.idToken == null) {
//         return "Google authentication failed";
//       }

//       // Create credentials for Firebase or your backend
//       final Map<String, String> googleCredentials = {
//         'access_token': googleAuth.accessToken!,
//         'id_token': googleAuth.idToken!,
//       };

//       // Send the credentials to your backend (you can send a POST request here)
//       final response = await http.post(
//         Uri.parse('$baseUrl/users/google-signin'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(googleCredentials),
//       );

//       if (response.statusCode == 200) {
//         // If the response from backend is successful, return null (success)
//         return null;
//       } else {
//         // If an error occurs, return the error message from backend
//         return jsonDecode(response.body)['detail'];
//       }
//     } catch (e) {
//       // Catch and print the error if any during the Google sign-in process
//       print("Google sign-in error: $e");
//       return "Error during Google sign-in";
//     }
//   }
// }

// extension on GoogleSignInAuthentication {
//   get accessToken => null;
// }

// extension on GoogleSignIn {
//   Future<GoogleSignInAccount?> signIn() {
//     throw UnimplementedError('signIn() has not been implemented.');
//   }
// }
