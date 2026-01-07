import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('server_ip') ?? ApiService.defaultIp;
      _portController.text = prefs.getString('server_port') ?? ApiService.defaultPort;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    if (ip.isEmpty || port.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both IP and Port')),
      );
      setState(() => _isLoading = false);
      return;
    }

    await ApiService().updateConnection(ip, port);

    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server settings saved!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Server IP / Hostname',
                hintText: 'e.g. 192.168.0.101',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'e.g. 3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
