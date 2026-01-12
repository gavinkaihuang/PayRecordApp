import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bill_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter binding initialized.');
  
  try {
    // Add small delay to allow native plugins to settle
    await Future.delayed(const Duration(milliseconds: 100));
    
    // --- SAFE MODE: CLEAR DATA TO FIX CRASH ---
    // Uncomment this if app keeps crashing on startup
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    // print('!!! CLEARED ALL PREFS FOR DEBUGGING !!!');
    // -------------------------------------------

    await ApiService().init();
    print('ApiService initialized.');
  } catch (e, stack) {
    print('ApiService init error: $e\n$stack');
  }

  runApp(const MyApp());
  print('runApp called.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
      ],
      child: MaterialApp(
        title: 'PayRecord',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check login status on startup
    Future.microtask(() => 
      Provider.of<AuthProvider>(context, listen: false).checkLoginStatus()
    );
    print('AuthWrapper initialized');
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch to listen to changes
    final auth = context.watch<AuthProvider>();
    
    print('AuthWrapper Rebuild. IsAuthenticated: ${auth.isAuthenticated}');
    
    if (auth.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
