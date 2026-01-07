import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../services/log_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    if (token != null && username != null) {
      _user = User(username: username, token: token);
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<String?> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Assuming response structure: { "token": "...", "username": "..." } or similar
        // Adjust based on actual API response verification if needed. 
        // For now, assume simple token return or token in body.
        final token = data['token'] ?? data['access_token']; 
        
        if (token != null) {
          if (ApiService.isDevMode) {
             print('====== [UserOp] Login Success. Token: $token ======');
          }
          // Always save token for persistent login as requested
          if (ApiService.isDevMode) print('Saving token to SharedPreferences...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', username);
          if (ApiService.isDevMode) print('Token saved. Updating state and notifying listeners...');

          _user = User(username: username, token: token);
          _isAuthenticated = true;
          notifyListeners();
          if (ApiService.isDevMode) print('Listeners notified.');
          return null; // Success implies no error message
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('Connection refused')) {
        return 'Connection refused. Check IP/Port and ensure server is running.';
      }
      return 'Connection error: ${e.toString()}';
    }
    return 'Invalid credentials or server error.';
  }

  Future<void> logout() async {
    if (ApiService.isDevMode) {
      LogService().addLog('UserOp: Logging out, clearing token...');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
