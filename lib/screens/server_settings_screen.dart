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
  final _domainController = TextEditingController();
  
  String _connectionType = 'ip'; // 'ip' or 'domain'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _connectionType = prefs.getString('connection_type') ?? 'ip';
      _ipController.text = prefs.getString('server_ip') ?? ApiService.defaultIp;
      _portController.text = prefs.getString('server_port') ?? ApiService.defaultPort;
      _domainController.text = prefs.getString('server_domain') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    if (_connectionType == 'ip') {
      final ip = _ipController.text.trim();
      final port = _portController.text.trim();

      if (ip.isEmpty || port.isEmpty) {
        _showError('Please enter both IP and Port');
        return;
      }
      
      await ApiService().updateConnection(
        type: 'ip', 
        ip: ip, 
        port: port
      );
    } else {
      final domain = _domainController.text.trim();
      
      if (domain.isEmpty) {
         _showError('Please enter a Domain Name');
         return;
      }
      
      await ApiService().updateConnection(
        type: 'domain', 
        domain: domain
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server settings saved!')),
    );
    Navigator.pop(context);
  }
  
  void _showError(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() => _isLoading = false);
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
            // Connection Type Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'ip', 
                  label: Text('IP Address'),
                  icon: Icon(Icons.lan),
                ),
                ButtonSegment<String>(
                  value: 'domain', 
                  label: Text('Domain Name'),
                  icon: Icon(Icons.language),
                ),
              ],
              selected: {_connectionType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _connectionType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Input Fields
            if (_connectionType == 'ip') ...[
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
            ] else ...[
               TextField(
                controller: _domainController,
                decoration: const InputDecoration(
                  labelText: 'Domain Name',
                  hintText: 'e.g. https://api.myapp.com',
                  helperText: 'Enter the full URL including protocol (https://)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
            
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
