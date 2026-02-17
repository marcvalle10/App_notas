import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/api_config.dart';

class ApiClient {
  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception(
        'No hay sesión activa (token null). Inicia sesión primero.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await http.get(_u(path), headers: await _headers());
    final body = res.body.isEmpty ? '{}' : res.body;
    final jsonBody = json.decode(body);

    if (res.statusCode >= 400) {
      throw Exception(
        jsonBody is Map && jsonBody['error'] != null
            ? jsonBody['error']
            : 'HTTP ${res.statusCode}',
      );
    }
    return (jsonBody as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      _u(path),
      headers: await _headers(),
      body: json.encode(data),
    );
    final body = res.body.isEmpty ? '{}' : res.body;
    final jsonBody = json.decode(body);

    if (res.statusCode >= 400) {
      throw Exception(
        jsonBody is Map && jsonBody['error'] != null
            ? jsonBody['error']
            : 'HTTP ${res.statusCode}',
      );
    }
    return (jsonBody as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      _u(path),
      headers: await _headers(),
      body: json.encode(data),
    );
    final body = res.body.isEmpty ? '{}' : res.body;
    final jsonBody = json.decode(body);

    if (res.statusCode >= 400) {
      throw Exception(
        jsonBody is Map && jsonBody['error'] != null
            ? jsonBody['error']
            : 'HTTP ${res.statusCode}',
      );
    }
    return (jsonBody as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await http.delete(_u(path), headers: await _headers());
    final body = res.body.isEmpty ? '{}' : res.body;
    final jsonBody = json.decode(body);

    if (res.statusCode >= 400) {
      throw Exception(
        jsonBody is Map && jsonBody['error'] != null
            ? jsonBody['error']
            : 'HTTP ${res.statusCode}',
      );
    }
    return (jsonBody as Map).cast<String, dynamic>();
  }
}
