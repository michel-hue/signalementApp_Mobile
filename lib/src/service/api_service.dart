import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _baseUrl = 'https://pct.newtiv.com';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36",
      "Referer": "https://pct.newtiv.com/",
    },
  ));

  static CookieJar? _cookieJar;

  static List<Map<String, dynamic>>? _cachedTypes;
  static List<Map<String, dynamic>>? _cachedZones;
  static DateTime? _typesCacheTime;
  static DateTime? _zonesCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  static DateTime? _lastRequest;
  static const _minDelay = Duration(milliseconds: 500);

  static bool _initialized = false;

  // ─── INITIALISATION ─────────────────────────────────────

  static void init() {
    if (_initialized) return;

    if (!kIsWeb) {
      _cookieJar = CookieJar();
      _dio.interceptors.add(CookieManager(_cookieJar!));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        await _rateLimit();
        if (options.extra['auth'] == true) {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final body = response.data?.toString() ?? '';
        if (body.trim().startsWith('<!DOCTYPE') || body.trim().startsWith('<html')) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              error: 'Protection bot détectée (réponse HTML)',
            ),
          );
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        final method = error.requestOptions.method.toUpperCase();
        final isReadOnly = method == 'GET';
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (isReadOnly && !alreadyRetried) {
          error.requestOptions.extra['retried'] = true;
          await Future.delayed(const Duration(seconds: 2));
          try {
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (_) {}
        }
        handler.next(error);
      },
    ));

    _initialized = true;
  }

  static Future<void> _rateLimit() async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < _minDelay) {
        await Future.delayed(_minDelay - elapsed);
      }
    }
    _lastRequest = DateTime.now();
  }

  // ─── TOKEN AUTH ─────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── AUTH ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    init();
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data;
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<void> logout() async {
    init();
    final token = await getToken();
    if (token != null) {
      try {
        await _dio.get('/auth/logout', options: Options(extra: {'auth': true}));
      } catch (_) {}
    }
    await clearToken();
    if (!kIsWeb) await _cookieJar?.deleteAll();
  }

  static Future<Map<String, dynamic>> getMe() async {
    init();
    final response = await _dio.get('/me', options: Options(extra: {'auth': true}));
    return response.data;
  }

  // ─── TYPES DE PROBLÈMES ─────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTypes({bool forceRefresh = false}) async {
    init();

    if (!forceRefresh && _cachedTypes != null && _typesCacheTime != null) {
      if (DateTime.now().difference(_typesCacheTime!) < _cacheDuration) {
        debugPrint('📦 Types depuis le cache');
        return _cachedTypes!;
      }
    }

    try {
      final response = await _dio.get('/types');
      final data = response.data;

      List<Map<String, dynamic>> result;
      if (data is List) {
        result = List<Map<String, dynamic>>.from(data);
      } else if (data['data'] != null) {
        result = List<Map<String, dynamic>>.from(data['data']);
      } else {
        result = [];
      }

      _cachedTypes = result;
      _typesCacheTime = DateTime.now();
      debugPrint('📦 Types reçus : ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur getTypes : $e');
      if (_cachedTypes != null) return _cachedTypes!;
      rethrow;
    }
  }

  static void clearTypesCache() {
    _cachedTypes = null;
    _typesCacheTime = null;
  }

  // ─── ZONES ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getZones({bool forceRefresh = false}) async {
    init();

    if (!forceRefresh && _cachedZones != null && _zonesCacheTime != null) {
      if (DateTime.now().difference(_zonesCacheTime!) < _cacheDuration) {
        return _cachedZones!;
      }
    }

    try {
      final response = await _dio.get('/zones');
      final data = response.data;

      List<Map<String, dynamic>> result;
      if (data is List) {
        result = List<Map<String, dynamic>>.from(data);
      } else if (data['data'] != null) {
        result = List<Map<String, dynamic>>.from(data['data']);
      } else {
        result = [];
      }

      _cachedZones = result;
      _zonesCacheTime = DateTime.now();
      return result;
    } catch (e) {
      if (_cachedZones != null) return _cachedZones!;
      rethrow;
    }
  }

  // ─── SIGNALEMENTS ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSignalements() async {
    init();
    final response = await _dio.get('/signalements');
    final data = response.data;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data['data'] != null) return List<Map<String, dynamic>>.from(data['data']);
    return [];
  }

  static Future<Map<String, dynamic>> getSignalement(String id) async {
    init();
    final response = await _dio.get('/signalements/$id');
    return response.data;
  }

  // ─── UPLOAD PHOTO VERS SUPABASE STORAGE ─────────────────
  // Retourne l'URL publique de la photo, ou null si échec

  // ─── UPLOAD PHOTO VERS SUPABASE STORAGE ─────────────────
  static Future<String?> uploadPhotoToSupabase(XFile xFile) async {
    if (kIsWeb) {
      debugPrint('⚠️ Upload photo non supporté sur web');
      return null;
    }
    try {
      final bytes = await xFile.readAsBytes(); // ✅ fonctionne partout
      final ext = xFile.path.split('.').last.toLowerCase();
      final fileName = 'signalements/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('photos')
          .uploadBinary(fileName, bytes);

      final photoUrl = Supabase.instance.client.storage
          .from('photos')
          .getPublicUrl(fileName);

      debugPrint('✅ Photo uploadée : $photoUrl');
      return photoUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload Supabase : $e');
      return null;
    }
  }

  // ─── ENVOI SIGNALEMENT ──────────────────────────────────
  // ⚠️ photoUrl = String (URL), pas un fichier

  static Future<String> envoyerSignalement({
    required String typeId,
    required double latitude,
    required double longitude,
    String? zoneId,
    String? description,
    String? photoUrl, // ← URL texte, pas un chemin de fichier
  }) async {
    init();

    final jsonBody = <String, dynamic>{
      'type_id':   typeId,
      'latitude':  latitude,
      'longitude': longitude,
      'statut':    'en_attente',
      'photo_url': photoUrl, // ← directement l'URL ou null
    };

    if (zoneId != null) jsonBody['zone_id'] = zoneId;
    if (description != null && description.isNotEmpty) {
      jsonBody['description'] = description;
    }

    debugPrint('📤 Envoi signalement (photo_url: $photoUrl)');

    final response = await _dio.post(
      '/signalements',
      data: jsonBody,
      options: Options(
        contentType: 'application/json',
        extra: {'no_retry': true},
      ),
    );

    debugPrint('📥 Réponse ${response.statusCode} : ${response.data}');

    final responseData = response.data;
    if (responseData is! Map) {
      return 'KP-${DateTime.now().millisecondsSinceEpoch}';
    }
    return responseData['token_suivi']
        ?? responseData['token']
        ?? 'KP-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> updateStatutSignalement(String id, String statut) async {
    init();
    await _dio.patch(
      '/signalements/$id/statut',
      data: {'statut': statut},
      options: Options(extra: {'auth': true}),
    );
  }

  // ─── STATS ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    init();
    try {
      final response = await _dio.get('/stats');
      return response.data;
    } catch (e) {
      debugPrint('⚠️ getStats error: $e');
      return {};
    }
  }

  // ─── SUIVI PAR TOKEN ────────────────────────────────────

  static Future<Map<String, dynamic>?> suivreSignalement(String token) async {
    try {
      final signalements = await getSignalements();
      return signalements.firstWhere(
            (s) => s['token_suivi'] == token,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }
}