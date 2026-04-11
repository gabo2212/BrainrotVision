import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.analysis;
        return Scaffold(
          appBar: AppBar(title: const Text('Recognition Result')),
          body: result == null
              ? const Center(
                  child: Text(
                    'Run an analysis from the home or preview screen first.',
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result.classification != null)
                        _RecognitionHeroCard(
                          classification: result.classification!,
                          clusterId: result.clusterId,
                        )
                      else
                        _ClassifierUnavailableCard(result: result),
                      const SizedBox(height: 20),
                      if (result.classification != null)
                        _RecognitionEvidenceCard(
                          classification: result.classification!,
                        ),
                      if (result.classification != null)
                        const SizedBox(height: 20),
                      _ImageDiagnosticsCard(result: result),
                      const SizedBox(height: 20),
                      _SimilarImagesSection(result: result),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Known-Class Limitation',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'This recognizer identifies one of the known brainrot classes in the dataset. Unknown or out-of-distribution images can still be forced into the closest known class, so low-confidence results should be read as best matches rather than certainty.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const InsightsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.query_stats_outlined),
                        label: const Text('Open Dataset Insights'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _RecognitionHeroCard extends StatelessWidget {
  const _RecognitionHeroCard({
    required this.classification,
    required this.clusterId,
  });

  final ClassificationResult classification;
  final int? clusterId;

  @override
  Widget build(BuildContext context) {
    final agreement = classification.neighborAgreement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classification.wording,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFC8623B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              classification.displayName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17322D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Predicted Identity among the known brainrot classes in this dataset.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xFF36544E)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Detected Brainrot',
                  value: classification.displayName,
                ),
                _MetricChip(
                  label: 'Recognition Confidence',
                  value:
                      '${(classification.confidence * 100).toStringAsFixed(1)}%',
                ),
                _MetricChip(
                  label: 'Classifier Status',
                  value: classification.classifierStatus,
                ),
                _MetricChip(
                  label: 'Predicted Identity',
                  value: classification.displayName,
                ),
                if (agreement != null)
                  _MetricChip(
                    label: 'Neighbor Agreement',
                    value:
                        '${agreement.matchingNeighbors}/${agreement.totalNeighbors} Agree',
                  ),
                _MetricChip(
                  label: 'Cluster',
                  value: clusterId?.toString() ?? 'N/A',
                ),
              ],
            ),
            if (classification.warningMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: classification.openSetWarning
                      ? const Color(0xFFF7E1D7)
                      : const Color(0xFFF4E4D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      classification.openSetWarning
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color: const Color(0xFF8E2E1B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        classification.warningMessage!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF8E2E1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecognitionEvidenceCard extends StatelessWidget {
  const _RecognitionEvidenceCard({required this.classification});

  final ClassificationResult classification;

  @override
  Widget build(BuildContext context) {
    final neighborAgreement = classification.neighborAgreement;
    final clusterAlignment = classification.clusterAlignment;
    final topPredictions = classification.topPredictions.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recognition Evidence',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Why this identity was chosen',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: const Color(0xFF36544E)),
            ),
            const SizedBox(height: 18),
            if (topPredictions.isNotEmpty) ...[
              Text(
                'Top Predictions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...topPredictions.map(
                (prediction) => _PredictionBar(prediction: prediction),
              ),
              const SizedBox(height: 18),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (neighborAgreement != null)
                  _EvidenceTile(
                    title: 'Nearest-Neighbor Retrieval',
                    body: neighborAgreement.agreesWithPrediction
                        ? 'Agrees with ${classification.displayName} at ${(neighborAgreement.agreementRatio * 100).toStringAsFixed(0)}%.'
                        : 'Mixed evidence: neighbor majority is ${neighborAgreement.majorityDisplayName}.',
                  ),
                if (clusterAlignment != null)
                  _EvidenceTile(
                    title: 'Cluster Alignment',
                    body: clusterAlignment.alignsWithPrediction
                        ? 'Cluster ${clusterAlignment.clusterId} is mostly ${clusterAlignment.majorityDisplayName}.'
                        : 'Cluster ${clusterAlignment.clusterId} leans toward ${clusterAlignment.majorityDisplayName}.',
                  ),
                _EvidenceTile(
                  title: 'Confidence Gap',
                  body: classification.confidenceGap == null
                      ? 'No runner-up class available.'
                      : '${(classification.confidenceGap! * 100).toStringAsFixed(1)} points over the second-best class.',
                ),
              ],
            ),
            if (classification.evidence.isNotEmpty) ...[
              const SizedBox(height: 18),
              ...classification.evidence.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Color(0xFF1E7A4B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageDiagnosticsCard extends StatelessWidget {
  const _ImageDiagnosticsCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Diagnostics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'Format', value: result.format),
                _MetricChip(
                  label: 'Dimensions',
                  value: '${result.width} × ${result.height}',
                ),
                _MetricChip(
                  label: 'Brightness',
                  value: result.brightness.toStringAsFixed(1),
                ),
                _MetricChip(
                  label: 'Contrast',
                  value: result.contrast.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarImagesSection extends StatelessWidget {
  const _SimilarImagesSection({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final predictedLabel = result.classification?.label;
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Similar Known Brainrots',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final image = result.similarImages[index];
                  final thumbnailUrl = state.resolveUrl(image.thumbnailUrl);
                  final matchesPrediction =
                      predictedLabel != null &&
                      image.label != null &&
                      image.label == predictedLabel;
                  return SizedBox(
                    width: 228,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: thumbnailUrl.isEmpty
                                    ? const ColoredBox(
                                        color: Color(0xFFE8D8C9),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                          ),
                                        ),
                                      )
                                    : Image.network(
                                        thumbnailUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => const ColoredBox(
                                              color: Color(0xFFE8D8C9),
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              ),
                                            ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              image.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Similarity distance: ${(image.distance ?? 0).toStringAsFixed(3)}',
                            ),
                            if (matchesPrediction) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF17322D,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Matches predicted identity'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemCount: result.similarImages.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassifierUnavailableCard extends StatelessWidget {
  const _ClassifierUnavailableCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brainrot Identity Detection',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'A classifier is not available for this dataset, so the app is showing retrieval and clustering only.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Classifier Status',
                  value: result.classifierAvailable ? 'Active' : 'Unavailable',
                ),
                _MetricChip(
                  label: 'Cluster',
                  value: result.clusterId?.toString() ?? 'N/A',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17322D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PredictionBar extends StatelessWidget {
  const _PredictionBar({required this.prediction});

  final PredictionCandidate prediction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prediction.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('${(prediction.confidence * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: prediction.confidence.clamp(0.0, 1.0).toDouble(),
              backgroundColor: const Color(0xFFF0E5DB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8623B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4E4D6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
