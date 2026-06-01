import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://194.36.85.234';

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ─────────────────────────────────────────────────────────────────────────
  //  TOKEN HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.setBool('is_logged_in', false);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TOKEN REFRESH — 401 aave to navo access token lo, session expire na thay
  // ─────────────────────────────────────────────────────────────────────────

  static Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_refreshKey);
    if (refresh == null) return false;

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mobile/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await prefs.setString(_accessKey, data['access']);
        return true; // navo token mali gayo — session continue
      }
      return false; // refresh pan expire — logout karvun padse
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SESSION EXPIRY — refresh pan fail thay tyare j logout
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _handleSessionExpiry() async {
    await clearTokens();
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  1. AUTH
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/mobile/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await saveTokens(data['access'], data['refresh']);
      return data;
    }
    throw Exception(
      data['detail'] ?? data['non_field_errors']?[0] ?? 'Login failed',
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_refreshKey);
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/api/mobile/auth/logout/'),
      headers: headers,
      body: jsonEncode({'refresh': refresh ?? ''}),
    );
    await clearTokens();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  2. PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    return await _getRequest('/api/mobile/profile/');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    return await _patchRequest('/api/mobile/profile/', body);
  }

  static Future<void> saveFcmToken(String fcmToken) async {
    await _postRequest('/api/mobile/profile/fcm-token/', {'fcm_token': fcmToken});
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  3. CALENDAR
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCalendar(int month, int year) async {
    return await _getRequest('/api/mobile/calendar/?month=$month&year=$year');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  4. ATTENDANCE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAttendanceHistory(int month, int year) async {
    return await _getRequest('/api/mobile/attendance/history/?month=$month&year=$year');
  }

  static Future<Map<String, dynamic>> getAttendanceReport(int month, int year) async {
    return await _getRequest('/api/mobile/attendance/report/?month=$month&year=$year');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  5. ANALYTICS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAnalytics({int months = 5}) async {
    return await _getRequest('/api/mobile/analytics/?months=$months');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  6. EXPORT
  // ─────────────────────────────────────────────────────────────────────────

  static Future<http.Response> exportCsv(int month, int year) async {
    final headers = await _authHeaders();
    return await http.get(
      Uri.parse('$baseUrl/api/mobile/export/csv/?month=$month&year=$year'),
      headers: headers,
    );
  }

  static Future<http.Response> exportPdf(int month, int year) async {
    final headers = await _authHeaders();
    return await http.get(
      Uri.parse('$baseUrl/api/mobile/export/pdf/?month=$month&year=$year'),
      headers: headers,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  7. NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications({String filter = 'all'}) async {
    return await _getRequest('/api/mobile/notifications/?filter=$filter');
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    return await _getRequest('/api/mobile/notifications/unread-count/');
  }

  static Future<void> markAllRead() async {
    await _postRequest('/api/mobile/notifications/mark-read/', {});
  }

  static Future<void> markSpecificRead(List<String> notificationIds) async {
    await _postRequest('/api/mobile/notifications/mark-read/', {
      'notification_ids': notificationIds,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  8. LEAVE REQUESTS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getLeaveRequests() async {
    return await _getRequest('/api/mobile/leave-requests/');
  }

  static Future<Map<String, dynamic>> submitLeaveRequest({
    required String reason,
    required String description,
    required String startDate,
    required String endDate,
    File? certificateFile,
  }) async {
    final token = await getAccessToken();
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (certificateFile != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mobile/leave-requests/'),
      );
      request.headers.addAll(headers);
      request.fields['reason'] = reason;
      request.fields['description'] = description;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.files.add(
        await http.MultipartFile.fromPath('certificate', certificateFile.path),
      );
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return await submitLeaveRequest(
            reason: reason,
            description: description,
            startDate: startDate,
            endDate: endDate,
            certificateFile: certificateFile,
          );
        } else {
          await _handleSessionExpiry();
          throw Exception('Session expired');
        }
      }
      return _parseResponse(res);
    } else {
      return await _postRequest('/api/mobile/leave-requests/', {
        'reason': reason,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
      });
    }
  }

  static Future<Map<String, dynamic>> getLeaveDetail(String leaveId) async {
    return await _getRequest('/api/mobile/leave-requests/$leaveId/');
  }

  static Future<void> withdrawLeaveRequest(String leaveId) async {
    final headers = await _authHeaders();
    var res = await http.delete(
      Uri.parse('$baseUrl/api/mobile/leave-requests/$leaveId/'),
      headers: headers,
    );
    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        res = await http.delete(
          Uri.parse('$baseUrl/api/mobile/leave-requests/$leaveId/'),
          headers: newHeaders,
        );
      } else {
        await _handleSessionExpiry();
        throw Exception('Session expired');
      }
    }
    _handleStatus(res);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS — auto refresh retry logic
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _getRequest(String path) async {
    final headers = await _authHeaders();
    var res = await http.get(Uri.parse('$baseUrl$path'), headers: headers);

    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        res = await http.get(Uri.parse('$baseUrl$path'), headers: newHeaders);
      } else {
        await _handleSessionExpiry();
        throw Exception('Session expired — please login again');
      }
    }
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> _postRequest(
      String path,
      Map<String, dynamic> body,
      ) async {
    final headers = await _authHeaders();
    var res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        res = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
          body: jsonEncode(body),
        );
      } else {
        await _handleSessionExpiry();
        throw Exception('Session expired — please login again');
      }
    }
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> _patchRequest(
      String path,
      Map<String, dynamic> body,
      ) async {
    final headers = await _authHeaders();
    var res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await _authHeaders();
        res = await http.patch(
          Uri.parse('$baseUrl$path'),
          headers: newHeaders,
          body: jsonEncode(body),
        );
      } else {
        await _handleSessionExpiry();
        throw Exception('Session expired — please login again');
      }
    }
    return _parseResponse(res);
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    _handleStatus(res);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static void _handleStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body);
    } catch (_) {}

    switch (res.statusCode) {
      case 400:
        throw Exception(
          body['detail'] ?? body.values.first?.toString() ?? 'Validation error',
        );
      case 401:
        throw Exception('Session expired — please login again');
      case 403:
        throw Exception(
          body['detail'] ?? 'Permission denied (403).',
        );
      case 404:
        throw Exception('No data found');
      default:
        throw Exception('Server error: ${res.statusCode}');
    }
  }
}