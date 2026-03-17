import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class AuthApi {
  static const String baseUrl = 'http://10.0.2.2:5298';

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/Auth/login');

    final response = await http.post(
      url,
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Lỗi server: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
