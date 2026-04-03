import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2/medihelp-api/";

  static Future login(String email, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl + "auth/login.php"),
      body: {
        "email": email,
        "password": password,
      },
    );

    return jsonDecode(response.body);
  }

  static Future register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl + "auth/register.php"),
      body: {
        "name": name,
        "email": email,
        "password": password,
      },
    );

    return jsonDecode(response.body);
  }
}