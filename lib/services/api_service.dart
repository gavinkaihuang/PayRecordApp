import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl = 'http://192.168.0.101:3000/api';
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
          print('--- API Request ---');
          print('URL: ${options.uri}');
          print('Data: ${options.data}');
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
          print('--- API Response ---');
          print('URL: ${response.requestOptions.uri}');
          print('Status: ${response.statusCode}');
          print('Data: ${response.data}');
          print('--------------------');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (isDevMode) {
          print('--- API Error ---');
          print('URL: ${e.requestOptions.uri}');
          print('Error: ${e.message}');
          if (e.response != null) {
            print('Data: ${e.response?.data}');
          }
           print('-----------------');
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
}
