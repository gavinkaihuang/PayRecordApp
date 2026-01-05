import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'log_service.dart';

class ApiService {
  late Dio _dio;
  static const String serverUrl = 'http://192.168.0.101:3000';
  final String baseUrl = '$serverUrl/api';
  static bool isDevMode = true;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (isDevMode) {
          LogService().addLog('API Req: ${options.method} ${options.uri}');
        }
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
      // Non-critical, eat error or rethrow?
      // User flow shouldn't break if merchant save fails, but nice to know.
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
      // Assuming response.data['url'] or nested structure. 
      // Adjust based on actual backend. Commonly { url: "path" }
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
