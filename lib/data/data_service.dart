import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:leavego_app/services/connectivity_service.dart';

class DataService {
  const DataService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get _http => _client ?? http.Client();

  void _ensureOnline() {
    if (Get.isRegistered<ConnectivityService>()) {
      Get.find<ConnectivityService>().ensureOnline();
    }
  }

  Never _rethrowNetwork(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        (error is http.ClientException &&
            (error.message.toLowerCase().contains('failed host lookup') ||
                error.message.toLowerCase().contains('network is unreachable') ||
                error.message.toLowerCase().contains('connection'))) ||
        error.toString().toLowerCase().contains('socketexception')) {
      throw Exception(ConnectivityService.offlineMessage);
    }
    throw error;
  }

  void _logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
  }) {
    debugPrint('API REQUEST => [$method] $url');
    if (headers != null && headers.isNotEmpty) {
      debugPrint('API HEADERS => $headers');
    }
    if (body != null) {
      debugPrint('API DATA => $body');
    }
  }

  void _logResponse({
    required String method,
    required String url,
    required int statusCode,
    required String rawBody,
  }) {
    debugPrint('API RESPONSE <= [$method] $url');
    debugPrint('API STATUS <= $statusCode');
    debugPrint('API BODY <= $rawBody');
  }

  Map<String, dynamic> _decodePayload(String rawBody) {
    final payload = <String, dynamic>{};
    if (rawBody.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return payload;
  }

  Future<Map<String, dynamic>> post({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    _ensureOnline();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    _logRequest(method: 'POST', url: url, headers: requestHeaders, body: body);

    try {
      final response = await _http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      _logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        rawBody: response.body,
      );

      return <String, dynamic>{
        'statusCode': response.statusCode,
        'data': _decodePayload(response.body),
      };
    } catch (e) {
      _rethrowNetwork(e);
    }
  }

  Future<Map<String, dynamic>> get({
    required String url,
    Map<String, String>? headers,
  }) async {
    _ensureOnline();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    _logRequest(method: 'GET', url: url, headers: requestHeaders);

    try {
      final response = await _http.get(Uri.parse(url), headers: requestHeaders);
      _logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        rawBody: response.body,
      );

      return <String, dynamic>{
        'statusCode': response.statusCode,
        'data': _decodePayload(response.body),
      };
    } catch (e) {
      _rethrowNetwork(e);
    }
  }

  Future<Map<String, dynamic>> put({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    _ensureOnline();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    _logRequest(method: 'PUT', url: url, headers: requestHeaders, body: body);

    try {
      final response = await _http.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      _logResponse(
        method: 'PUT',
        url: url,
        statusCode: response.statusCode,
        rawBody: response.body,
      );

      return <String, dynamic>{
        'statusCode': response.statusCode,
        'data': _decodePayload(response.body),
      };
    } catch (e) {
      _rethrowNetwork(e);
    }
  }

  Future<Map<String, dynamic>> delete({
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    _ensureOnline();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    _logRequest(method: 'DELETE', url: url, headers: requestHeaders, body: body);

    try {
      final response = await _http.delete(
        Uri.parse(url),
        headers: requestHeaders,
        body: body == null ? null : jsonEncode(body),
      );
      _logResponse(
        method: 'DELETE',
        url: url,
        statusCode: response.statusCode,
        rawBody: response.body,
      );

      return <String, dynamic>{
        'statusCode': response.statusCode,
        'data': _decodePayload(response.body),
      };
    } catch (e) {
      _rethrowNetwork(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart({
    required String url,
    required Map<String, String> fields,
    required String? filePath,
    required String fileFieldName,
    Map<String, String>? headers,
  }) async {
    _ensureOnline();
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(<String, String>{...?headers});
    request.fields.addAll(fields);

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );
    }

    _logRequest(
      method: 'POST MULTIPART',
      url: url,
      headers: request.headers,
      body: <String, dynamic>{
        'fields': fields,
        'fileFieldName': fileFieldName,
        'filePath': filePath,
      },
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _logResponse(
        method: 'POST MULTIPART',
        url: url,
        statusCode: response.statusCode,
        rawBody: response.body,
      );

      return <String, dynamic>{
        'statusCode': response.statusCode,
        'data': _decodePayload(response.body),
      };
    } catch (e) {
      _rethrowNetwork(e);
    }
  }
}
