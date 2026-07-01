import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:3000/api/v1';

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ========================================================
    // 1. TAMBAHKAN LOG INTERCEPTOR UNTUK DEBUGGING (BARU)
    // ========================================================
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true, // Tampilkan data payload yang dikirim
        responseHeader: true,
        responseBody: true, // Tampilkan data JSON balasan dari server
        error: true, // Tampilkan detail error
        logPrint: (obj) => debugPrint(
          obj.toString(),
        ), // Menggunakan debugPrint agar teks panjang tidak terpotong di konsol
      ),
    );

    // ========================================================
    // 2. CUSTOM INTERCEPTOR UNTUK TOKEN & ERROR HANDLING
    // ========================================================
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // --- Tambahan log ekstra khusus untuk melihat error dari backend Go ---
          debugPrint("🔥 [API ERROR] URL: ${e.requestOptions.path}");
          debugPrint("🔥 [API ERROR] STATUS CODE: ${e.response?.statusCode}");
          debugPrint("🔥 [API ERROR] DATA: ${e.response?.data}");

          // 1. Auto Logout jika 401
          if (e.response?.statusCode == 401) {
            await storage.delete(key: 'jwt_token');
            await storage.delete(key: 'user_role');
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }

          // 2. Ekstraksi pesan error dari format standar Go (StandardResponse)
          if (e.response?.data != null && e.response?.data is Map) {
            final responseData = e.response?.data;
            final backendMessage = responseData['message'];
            final backendErrors =
                responseData['errors']; // Tangkap detail validasi (jika ada)

            if (backendMessage != null) {
              // Jika ada detail 'errors' dari Go, gabungkan agar terlihat di SnackBar
              String finalMessage = backendMessage.toString();
              if (backendErrors != null) {
                finalMessage += " \nDetail: $backendErrors";
              }

              return handler.next(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  type: e.type,
                  error: e.error,
                  message:
                      finalMessage, // Timpa message bawaan Dio dengan message server
                ),
              );
            }
          }

          return handler.next(e);
        },
      ),
    );
  }
}
