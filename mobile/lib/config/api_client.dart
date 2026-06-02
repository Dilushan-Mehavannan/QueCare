import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  // We point to 10.0.2.2 for Android Emulator, and localhost for iOS/others
  // You can customize this to your actual network IP (e.g. 192.168.1.50)
  static const String baseServerUrl = 'http://10.0.2.2:3000'; 

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: baseServerUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can retrieve the auth token from local storage here
          // options.headers['Authorization'] = 'Bearer $token';
          print('--> ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('<-- ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('[API Error] <-- ${e.message} ${e.response?.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }
}
