import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Separate Dio instance with no baseUrl for direct S3 PUT calls
  final Dio _s3Dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode == 401) {
            await StorageService.clearSession();
            Get.offAllNamed('/login');
            Get.snackbar(
              'Session Expired',
              'Please log in again.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<Options> _authOptions() async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response> login(String email, String password) => _dio.post(
    '/api/auth/login',
    data: {'email': email, 'password': password},
  );

  Future<Response> forgotPassword(String email) =>
      _dio.post('/api/Auth/forgot-password', data: {'email': email});

  Future<Response> getInspections({int page = 1, int pageSize = 100}) async {
    final options = await _authOptions();
    return _dio.get(
      '/api/mobile/inspections/list',
      queryParameters: {'pageNumber': page, 'pageSize': pageSize},
      options: options,
    );
  }

  Future<Response> getProfile({String? token}) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : await _authOptions();
    return _dio.get('/api/auth/profile', options: options);
  }

  Future<Response> getQuickSuggestions({
    required String agencyId,
    required int type,
  }) async {
    final options = await _authOptions();
    return _dio.get(
      '/api/QuickSuggestions',
      queryParameters: {
        'type': type,
        'page': 1,
        'pageSize': 10000,
        'agencyId': agencyId,
      },
      options: options,
    );
  }

  Future<Response> getReportTemplate(
    String inspectionId, {
    required bool isEntryExit,
  }) async {
    final options = await _authOptions();
    final path = isEntryExit
        ? '/api/mobile/report-template/entry-exit'
        : '/api/mobile/report-template/routine';
    return _dio.get(
      path,
      queryParameters: {'inspectionId': inspectionId},
      options: options,
    );
  }

  /// Gets a pre-signed S3 upload URL, PUTs the file bytes to S3,
  /// and returns the final public fileUrl to store in the report.
  /// [isVideo] determines the mediaType and content-type sent to the API.
  Future<String> uploadMedia({
    required String agencyId,
    required String propertyId,
    required String inspectionId,
    required String filePath,
    bool isVideo = false,
  }) async {
    final ext = filePath.split('.').last.toLowerCase();
    String contentType;
    if (isVideo) {
      contentType = ext == 'mov' ? 'video/quicktime' : 'video/mp4';
    } else {
      contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    }

    final options = await _authOptions();
    final response = await _dio.get(
      '/api/S3/generate-upload-url',
      queryParameters: {
        'agencyId': agencyId,
        'propertyId': propertyId,
        'inspectionId': inspectionId,
        'mediaType': isVideo ? 'video' : 'photo',
        'contentType': contentType,
      },
      options: options,
    );

    final body = response.data is Map ? response.data as Map : {};
    final dataMap = (body['data'] is Map ? body['data'] : body) as Map;
    final uploadUrl = (dataMap['uploadUrl'] ?? dataMap['upload_url'] ?? '')
        .toString();
    final fileUrl =
        (dataMap['fileUrl'] ?? dataMap['file_url'] ?? dataMap['url'] ?? '')
            .toString();

    if (uploadUrl.isEmpty) throw Exception('No uploadUrl in response: $body');

    final bytes = await File(filePath).readAsBytes();
    await _s3Dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': contentType},
        contentType: contentType,
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    return fileUrl.isNotEmpty ? fileUrl : uploadUrl.split('?').first;
  }

  // Keep old name as a convenience wrapper so nothing else breaks.
  Future<String> uploadPhoto({
    required String agencyId,
    required String propertyId,
    required String inspectionId,
    required String filePath,
  }) => uploadMedia(
    agencyId: agencyId,
    propertyId: propertyId,
    inspectionId: inspectionId,
    filePath: filePath,
  );

  Future<Response> syncReport(Map<String, dynamic> body) async {
    final options = await _authOptions();
    return _dio.post('/api/ReportSync/sync', data: body, options: options);
  }

  Future<Response> syncRoutineReport(Map<String, dynamic> body) async {
    final options = await _authOptions();
    return _dio.post(
      '/api/ReportSync/sync-routine',
      data: body,
      options: options,
    );
  }

  Future<Response> getInspectionById(String inspectionId) async {
    final options = await _authOptions();
    return _dio.get('/api/inspection/$inspectionId', options: options);
  }
}
