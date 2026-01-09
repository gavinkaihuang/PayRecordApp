import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'log_service.dart';

class ApiService {
  late Dio _dio;
  static final ApiService _instance = ApiService._internal();

  // Default values
  static const String defaultIp = '192.168.0.101';
  static const String defaultPort = '3000';
  
  String _baseUrl = 'http://$defaultIp:$defaultPort/api';
  static bool isDevMode = true;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (isDevMode) {
          LogService().addLog('API Req: ${options.method} ${options.uri}');
        }
        
        // Ensure baseUrl is up to date (in case it changed and Dio options weren't updated)
        // Or update Dio base url when settings change.
        // Let's rely on init() or updateConnection settings.
        options.baseUrl = _baseUrl; 

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (isDevMode) {
          print('[[TOKEN]]: $token');
        }
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (isDevMode) {
          print('Headers: ${options.headers}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (isDevMode) {
          LogService().addLog('API Res: ${response.statusCode} ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (isDevMode) {
           LogService().addLog('API Err: ${e.message} ${e.requestOptions.uri}');
        }
        return handler.next(e);
      },
    ));
    
    // Initial load handled by main.dart calling init() explicitly
    // init(); 
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('connection_type') ?? 'ip';
    
    if (type == 'domain') {
      final domain = prefs.getString('server_domain') ?? '';
      // Ensure domain has protocol (basic check)
      String cleanDomain = domain;
      if (domain.isNotEmpty && !domain.startsWith('http')) {
        cleanDomain = 'https://$domain';
      }
      _baseUrl = '$cleanDomain/api';
    } else {
      final ip = prefs.getString('server_ip') ?? defaultIp;
      final port = prefs.getString('server_port') ?? defaultPort;
      _baseUrl = 'http://$ip:$port/api';
    }
    
    _dio.options.baseUrl = _baseUrl;
    if (isDevMode) print('ApiService initialized with: $_baseUrl (Type: $type)');
  }

  Future<void> updateConnection({
    required String type,
    String? ip,
    String? port,
    String? domain,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connection_type', type);
    
    if (type == 'domain' && domain != null) {
      await prefs.setString('server_domain', domain);
      String cleanDomain = domain;
      if (domain.isNotEmpty && !domain.startsWith('http')) {
        cleanDomain = 'https://$domain';
      }
      _baseUrl = '$cleanDomain/api';
    } else if (type == 'ip' && ip != null && port != null) {
      await prefs.setString('server_ip', ip);
      await prefs.setString('server_port', port);
      _baseUrl = 'http://$ip:$port/api';
    }
    
    _dio.options.baseUrl = _baseUrl;
    if (isDevMode) print('ApiService updated to: $_baseUrl (Type: $type)');
  }

  String get currentBaseUrl => _baseUrl;
  
  String get currentServerUrl {
    // Remove '/api' from the end
    if (_baseUrl.endsWith('/api')) {
      return _baseUrl.substring(0, _baseUrl.length - 4);
    }
    return _baseUrl;
  }

  Future<Response> login(String username, String password) async {
    return _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> getBills(int year, int month) async {
    return _dio.get('/bills', queryParameters: {
      'year': year,
      'month': month,
    });
  }

  Future<Response> addBill(Map<String, dynamic> billData) async {
    return _dio.post('/bills', data: billData);
  }

  Future<Response> updateBill(String id, Map<String, dynamic> billData) async {
    return _dio.put('/bills/$id', data: billData);
  }

  Future<void> setMerchantIcon(String name, String iconUrl) async {
    try {
      if (isDevMode) print('Setting merchant icon for $name: $iconUrl');
      await _dio.post('/merchants', data: {
        'name': name,
        'icon': iconUrl,
      });
    } catch (e) {
      if (isDevMode) print('Failed to set merchant icon: $e');
    }
  }

  Future<Response> cloneBills(int year, int month) async {
    return _dio.post('/bills/clone', data: {
      'year': year,
      'month': month,
    });
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return _dio.put('/users/profile', data: data);
  }

  Future<Response> getProfile() async {
    return _dio.get('/users/profile');
  }

  Future<String?> uploadFile(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    try {
      final response = await _dio.post('/upload', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url']; 
      }
    } catch (e) {
      if (isDevMode) {
        print('Upload error: $e');
      }
    }
    return null;
  }
}
