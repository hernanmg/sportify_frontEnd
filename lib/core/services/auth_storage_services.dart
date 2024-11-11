import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  // Guarda el token en almacenamiento
  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("authToken", token);
  }

  // Obtiene el token guardado
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  // Borra el token guardado
  Future<void> clearStoredToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("authToken");
  }
}