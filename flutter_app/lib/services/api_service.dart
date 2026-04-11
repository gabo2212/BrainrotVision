import 'dart:convert';

import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  ApiService({required this.baseUrl});

  factory ApiService.fromEnvironment() {
    return ApiService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
    );
  }

  final String baseUrl;

  String resolveUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$baseUrl$path';
  }

  Future<BackendHealth> fetchHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    _throwIfError(response);
    return BackendHealth.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DatasetStats> fetchStats() async {
    final response = await http.get(Uri.parse('$baseUrl/stats'));
    _throwIfError(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return DatasetStats.fromJson(payload['payload'] as Map<String, dynamic>);
  }

  Future<List<SimilarImage>> fetchSamples({int limit = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/samples?limit=$limit'));
    _throwIfError(response);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload['items'] as List<dynamic>?) ?? const <dynamic>[];
    return items
        .map((item) => SimilarImage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AnalysisResult> analyzeImage(XFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _throwIfError(response);
    return AnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AnalysisResult> analyzeSample(String rawRelativePath) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze/sample'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'raw_relative_path': rawRelativePath}),
    );
    _throwIfError(response);
    return AnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Request failed with status ${response.statusCode}.';
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      message = payload['detail'] as String? ?? message;
    } catch (_) {
      // Keep the fallback message when the response body is not JSON.
    }
    throw Exception(message);
  }
}
