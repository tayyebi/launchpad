import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  String? _baseUrl;
  String? _token;

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;
  ApiClient._();

  void configure({required String baseUrl, String? token}) {
    _baseUrl = baseUrl;
    _token = token;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
  }

  bool get isConfigured => _baseUrl != null;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
