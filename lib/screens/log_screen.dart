import 'package:flutter/material.dart';
import '../services/log_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  @override
  Widget build(BuildContext context) {
     final logs = LogService().logs.reversed.toList();
     return Scaffold(
      appBar: AppBar(
        title: const Text('Operation Logs'),
        actions: [
           IconButton(
             icon: const Icon(Icons.delete),
             onPressed: () {
               setState(() {
                 LogService().clearLogs();
               });
             },
           )
        ],
      ),
      body: ListView.separated(
        itemCount: logs.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final log = logs[i];
          return ListTile(
            dense: true,
            title: Text(log.message, style: const TextStyle(fontSize: 12)),
            subtitle: Text(log.timestamp.toString().split('.')[0], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          );
        },
      ),
    );
  }
}
