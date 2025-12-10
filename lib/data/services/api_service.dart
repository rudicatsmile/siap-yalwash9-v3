import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import 'storage_service.dart';

/// HTTP client service for API communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _logger = Logger();
  final _storage = StorageService();

  /// Initialize API service
  void init() {
    _logger.d('Initializing API Service');
    _logger.d('Environment: ${Environment.current}');
    _logger.d('API Base URL: ${Environment.apiBaseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConstants.apiTimeoutSeconds),
        headers: {
          ApiConstants.headerContentType: ApiConstants.applicationJson,
          ApiConstants.headerAccept: ApiConstants.applicationJson,
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token to headers if available
          final token = _storage.getAuthToken();
          if (token != null) {
            options.headers[ApiConstants.headerAuthorization] =
                ApiConstants.bearerToken(token);
          }

          _logger.d('Request: ${options.method} ${options.path}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
              'Response: ${response.statusCode} ${response.requestOptions.path}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
              'Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          _logger.e('Error message: ${error.message}');
          _logger.e('Error data: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );

    _logger
        .i('API Service initialized with base URL: ${Environment.apiBaseUrl}');
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection.',
          statusCode: 0,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _getErrorMessage(error.response?.data);

        return ApiException(
          message,
          statusCode: statusCode,
          data: error.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiException('Request cancelled', statusCode: 0);

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return ApiException(
            'No internet connection. Please check your network.',
            statusCode: 0,
          );
        }
        return ApiException(
          'Unexpected error occurred: ${error.message}',
          statusCode: 0,
        );

      default:
        return ApiException(
          'An error occurred: ${error.message}',
          statusCode: 0,
        );
    }
  }

  /// Extract error message from response data
  String _getErrorMessage(dynamic data) {
    if (data == null) return 'An error occurred';

    if (data is Map<String, dynamic>) {
      // Check for standard error structure
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error.containsKey('message')) {
          return error['message'] as String;
        } else if (error is String) {
          return error;
        }
      }

      // Check for message field
      if (data.containsKey('message')) {
        return data['message'] as String;
      }
    }

    return 'An error occurred';
  }

  /// Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException(this.message, {required this.statusCode, this.data});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
