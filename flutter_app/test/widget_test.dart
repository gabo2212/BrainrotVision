import 'package:brainrotvision_flutter/main.dart';
import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:brainrotvision_flutter/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiService extends ApiService {
  FakeApiService() : super(baseUrl: 'http://localhost:8000');

  @override
  Future<BackendHealth> fetchHealth() async {
    return const BackendHealth(
      ready: true,
      samplesIndexed: 42,
      classifierAvailable: false,
    );
  }

  @override
  Future<DatasetStats> fetchStats() async {
    return const DatasetStats(
      totalImages: 42,
      validImages: 40,
      corruptImages: 2,
      hasLabels: false,
      artifactReady: true,
      exactDuplicateGroups: 3,
      nearDuplicateGroups: 5,
      formatDistribution: {'JPEG': 30, 'PNG': 12},
      labelDistribution: {},
      clusterDistribution: {'0': 20, '1': 22},
      width: NumericSummary(mean: 512, median: 512, min: 256, max: 1024),
      height: NumericSummary(mean: 512, median: 512, min: 256, max: 1024),
      aspectRatio: NumericSummary(mean: 1, median: 1, min: 0.5, max: 1.8),
    );
  }
}

void main() {
  testWidgets('home screen renders project title and actions', (tester) async {
    await tester.pumpWidget(BrainrotVisionApp(apiService: FakeApiService()));
    await tester.pumpAndSettle();

    expect(find.text('BrainrotVision'), findsOneWidget);
    expect(find.text('Choose From Gallery'), findsOneWidget);
    expect(find.text('Dataset Insights'), findsOneWidget);
  });
}
