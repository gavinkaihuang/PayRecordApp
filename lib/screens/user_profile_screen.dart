import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/log_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telegramTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();
  
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _telegramTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (ApiService.isDevMode) {
          LogService().addLog('Profile Response Keys: ${data.keys.toList()}');
          LogService().addLog('Profile Telegram Data: ${data['telegramToken']} / ${data['telegram_token']}');
          print('Profile Response: $data');
        }
        _usernameController.text = data['username'] ?? '';
        _nicknameController.text = data['nickname'] ?? '';
        
        // Check for both camelCase and snake_case
        _telegramTokenController.text = 
            data['telegramToken'] ?? data['telegram_token'] ?? '';
        _telegramChatIdController.text = 
            data['telegramChatId'] ?? data['telegram_chat_id'] ?? '';
      }
    } catch (e) {
      if (ApiService.isDevMode) print('Fetch profile error: $e');
      // Ignore error or show snackbar. 404 means no profile yet, which is fine.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'nickname': _nicknameController.text,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
        'telegramToken': _telegramTokenController.text,
        'telegramChatId': _telegramChatIdController.text,
      };

      final response = await _apiService.updateProfile(data);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      filled: true,
                      fillColor: Color(0xFFEEEEEE),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: 'Nickname'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password', 
                      helperText: 'Leave empty to keep current password'
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telegramTokenController,
                    decoration: const InputDecoration(labelText: 'Telegram Bot Token'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telegramChatIdController,
                    decoration: const InputDecoration(labelText: 'Telegram Chat ID'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
