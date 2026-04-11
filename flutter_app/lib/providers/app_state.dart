import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:brainrotvision_flutter/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AppState extends ChangeNotifier {
  AppState({required ApiService api}) : _api = api;

  final ApiService _api;
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  AnalysisResult? analysis;
  DatasetStats? stats;
  BackendHealth? health;
  String? errorMessage;
  bool isPicking = false;
  bool isAnalyzing = false;
  bool isLoadingStats = false;
  bool _bootstrapped = false;

  String get apiBaseUrl => _api.baseUrl;
  bool get backendReady => health?.ready ?? false;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    await Future.wait([refreshHealth(), loadStats()]);
  }

  Future<void> refreshHealth() async {
    try {
      health = await _api.fetchHealth();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> loadStats() async {
    isLoadingStats = true;
    notifyListeners();
    try {
      stats = await _api.fetchStats();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<bool> pickImage(ImageSource source) async {
    isPicking = true;
    errorMessage = null;
    notifyListeners();
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 95,
      );
      if (file == null) {
        return false;
      }
      selectedImage = file;
      analysis = null;
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isPicking = false;
      notifyListeners();
    }
  }

  Future<bool> analyzeSelectedImage() async {
    if (selectedImage == null) {
      errorMessage = 'Select an image before running analysis.';
      notifyListeners();
      return false;
    }
    isAnalyzing = true;
    errorMessage = null;
    notifyListeners();
    try {
      analysis = await _api.analyzeImage(selectedImage!);
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    selectedImage = null;
    analysis = null;
    errorMessage = null;
    notifyListeners();
  }

  String resolveUrl(String? path) => _api.resolveUrl(path);
}
