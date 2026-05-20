import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  // Ubah Base URL ini sesuai dengan IP komputer Anda jika di-run di device fisik
  // Jika pakai emulator Android, gunakan 10.0.2.2
  // Jika web/iOS simulator, gunakan localhost atau 127.0.0.1
  static const String baseUrl = 'http://localhost:3000/api/v1';

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
        onError: (DioException e, handler) async {
          // Anda bisa menambahkan logika khusus di sini,
          // misal: jika error 401 (Unauthorized), otomatis logout user
          if (e.response?.statusCode == 401) {
            await storage.delete(key: 'jwt_token');
            // TODO: Arahkan user kembali ke LoginPage
          }
          return handler.next(e);
        },
      ),
    );
  }
}
