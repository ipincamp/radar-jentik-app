import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Ubah Base URL ini sesuai dengan IP komputer Anda jika di-run di device fisik
  // Jika pakai emulator Android, gunakan 10.0.2.2
  // Jika web/iOS simulator, gunakan localhost atau 127.0.0.1
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

    // Tambahkan Interceptor untuk menyisipkan Token secara otomatis
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ambil token dari secure storage
          String? token = await storage.read(key: 'jwt_token');

          if (token != null) {
            // Jika token ada, tambahkan ke Header Authorization
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // lakukan logging atau modifikasi response terbungkus di sini jika diperlukan
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // 1. Logika penanganan error 401 (Unauthorized / Token Expired)
          if (e.response?.statusCode == 401) {
            // Hapus semua key autentikasi dari secure storage
            await storage.delete(key: 'jwt_token');
            await storage.delete(key: 'user_role');

            // TODO: Arahkan user kembali ke LoginPage secara otomatis tanpa BuildContext
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }

          // 2. Intersepsi pesan error dari backend Go standar secara global
          if (e.response?.data != null && e.response?.data is Map) {
            final backendMessage = e.response?.data['message'];
            if (backendMessage != null) {
              // Bungkus ulang DioException dengan pesan asli dari backend agar bisa dibaca langsung lewat e.message
              return handler.next(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  type: e.type,
                  error: e.error,
                  message: backendMessage.toString(),
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
