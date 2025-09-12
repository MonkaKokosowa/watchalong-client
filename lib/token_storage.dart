// Add this to your pubspec.yaml dependencies:
// shared_preferences: ^2.0.0

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'discord_access_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
