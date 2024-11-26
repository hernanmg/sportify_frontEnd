import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/models/user.dart';

class UserService {
  final String baseUrl= AppConfig.apiBaseUrl;

  // UserService(this.baseUrl);

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }
}
