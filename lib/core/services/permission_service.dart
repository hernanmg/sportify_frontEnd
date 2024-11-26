import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportify_amateur/models/permission.dart';

class PermissionService {
  final String baseUrl = '';

  PermissionService();

  Future<List<Permission>> getPermissions() async {
    final response = await http.get(Uri.parse('$baseUrl/permissions'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Permission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch permissions');
    }
  }
}
