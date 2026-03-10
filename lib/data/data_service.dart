import 'dart:convert';

import 'package:http/http.dart' as http;

class DataService {
  const DataService({http.Client? client}) : _client = client;

  final http.Client? _client;

  http.Client get _http => _client ?? http.Client();

  Future<Map<String, dynamic>> post({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final response = await _http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> payload = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {}
    }

    return <String, dynamic>{
      'statusCode': response.statusCode,
      'data': payload,
    };
  }

  Future<Map<String, dynamic>> get({
    required String url,
    Map<String, String>? headers,
  }) async {
    final response = await _http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      },
    );

    Map<String, dynamic> payload = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {}
    }

    return <String, dynamic>{
      'statusCode': response.statusCode,
      'data': payload,
    };
  }

  Future<Map<String, dynamic>> postMultipart({
    required String url,
    required Map<String, String> fields,
    required String? filePath,
    required String fileFieldName,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(<String, String>{...?headers});
    request.fields.addAll(fields);

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    Map<String, dynamic> payload = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {}
    }

    return <String, dynamic>{
      'statusCode': response.statusCode,
      'data': payload,
    };
  }
}
