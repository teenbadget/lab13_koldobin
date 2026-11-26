import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Субдомен на https://requestcatcher.com/, куди надсилаються запити.
// Сторінку https://lab13-koldobin.requestcatcher.com/ потрібно залишити відкритою,
// щоб бачити запити, які надходять із застосунку.
const String kRequestCatcherHost = 'lab13-koldobin.requestcatcher.com';
const String kRequestCatcherUrl = 'https://$kRequestCatcherHost';

// Результат запиту для показу користувачу.
class ApiResult {
  final bool ok;
  final String message;
  const ApiResult(this.ok, this.message);
}

// Сервіс для відправки даних форм за допомогою пакету dio.
class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: kRequestCatcherUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            // sendTimeout не задаємо: у браузері він вмикає preflight (OPTIONS)
            // Форма (x-www-form-urlencoded) не потребує CORS-preflight (OPTIONS) у браузері
            contentType: Headers.formUrlEncodedContentType,
          ),
        );

  final Dio _dio;

  Future<ApiResult> login({required String email, required String password}) {
    return _post('/login', {'email': email, 'password': password});
  }

  Future<ApiResult> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _post('/signup', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<ApiResult> resetPassword({required String email}) {
    return _post('/reset', {'email': email});
  }

  Future<ApiResult> _post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return ApiResult(true, 'Запит надіслано (код ${response.statusCode})');
    } on DioException catch (e) {
      // У браузері requestcatcher не віддає CORS-заголовки, тож відповідь
      // недоступна, хоча сам запит уже дійшов до сервера.
      if (kIsWeb && e.response == null && e.type == DioExceptionType.connectionError) {
        return const ApiResult(
          true,
          'Запит надіслано (браузер не дає прочитати відповідь через CORS)',
        );
      }
      final code = e.response?.statusCode;
      final text = code != null
          ? 'Сервер відповів помилкою $code'
          : 'Не вдалося надіслати запит: ${e.message ?? e.type.name}';
      return ApiResult(false, text);
    } catch (e) {
      return ApiResult(false, 'Помилка: $e');
    }
  }
}
