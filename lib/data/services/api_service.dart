import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Separate Dio instance with no baseUrl for direct S3 PUT calls
  final Dio _s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
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
    ));
  }

  Future<Options> _authOptions() async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response> login(String email, String password) =>
      _dio.post('/api/auth/login', data: {'email': email, 'password': password});

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

  Future<Response> getReportTemplate(String inspectionId, {required bool isEntryExit}) async {
    final options = await _authOptions();
    final path = isEntryExit
        ? '/api/mobile/report-template/entry-exit'
        : '/api/mobile/report-template/routine';
    return _dio.get(path, queryParameters: {'inspectionId': inspectionId}, options: options);
  }

  /// Gets a pre-signed S3 upload URL, PUTs the file bytes to S3,
  /// and returns the final public fileUrl to store in the report.
  Future<String> uploadPhoto({
    required String agencyId,
    required String propertyId,
    required String inspectionId,
    required String filePath,
  }) async {
    final options = await _authOptions();
    // Step 1: get pre-signed uploadUrl + permanent fileUrl from our API
    final response = await _dio.get(
      '/api/S3/generate-upload-url',
      queryParameters: {
        'agencyId': agencyId,
        'propertyId': propertyId,
        'inspectionId': inspectionId,
        'mediaType': 'photo',
      },
      options: options,
    );
    print('generateUploadUrl response: ${response.data}');
    final data = response.data is Map ? response.data as Map : {};
    final uploadUrl = (data['uploadUrl'] ?? data['upload_url'] ?? '').toString();
    final fileUrl = (data['fileUrl'] ?? data['file_url'] ?? data['url'] ?? '').toString();

    if (uploadUrl.isEmpty) throw Exception('No uploadUrl in response: $data');

    // Step 2: PUT file bytes directly to S3 using separate Dio (no baseUrl, no Bearer token)
    final bytes = await File(filePath).readAsBytes();
    final ext = filePath.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    await _s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable(bytes.map((e) => [e])),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
      ),
    );
    return fileUrl.isNotEmpty ? fileUrl : uploadUrl.split('?').first;
  }

  Future<Response> syncReport(Map<String, dynamic> body) async {
    final options = await _authOptions();
    return _dio.post('/api/ReportSync/sync', data: body, options: options);
  }

  Future<Response> getInspectionById(String inspectionId) async {
    final options = await _authOptions();
    return _dio.get('/api/inspection/$inspectionId', options: options);
  }
}
