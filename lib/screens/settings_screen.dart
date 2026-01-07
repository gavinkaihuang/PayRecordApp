import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'user_profile_screen.dart';
import 'log_screen.dart';
import 'login_screen.dart';
import 'server_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout(context);
            }, 
            child: const Text('Logout', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('User Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const UserProfileScreen())
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.orange),
            title: const Text('Operation Logs'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LogScreen())
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dns, color: Colors.purple),
            title: const Text('Server Connection'),
            subtitle: const Text('Configure IP and Port'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ServerSettingsScreen())
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}
