import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/utils/brainrot_labels.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final stats = state.stats;
        return Scaffold(
          appBar: AppBar(title: const Text('Dataset Insights')),
          body: stats == null
              ? Center(
                  child: state.isLoadingStats
                      ? const CircularProgressIndicator()
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Dataset stats are not loaded yet.'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () =>
                                    context.read<AppState>().loadStats(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AppState>().loadStats(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SummaryCard(
                            label: 'Total Images',
                            value: '${stats.totalImages}',
                          ),
                          _SummaryCard(
                            label: 'Valid Images',
                            value: '${stats.validImages}',
                          ),
                          _SummaryCard(
                            label: 'Corrupt Images',
                            value: '${stats.corruptImages}',
                          ),
                          _SummaryCard(
                            label: 'Artifact Ready',
                            value: stats.artifactReady ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DistributionCard(
                        title: 'Formats',
                        distribution: stats.formatDistribution,
                      ),
                      const SizedBox(height: 16),
                      _DistributionCard(
                        title: stats.hasLabels
                            ? 'Inferred Labels'
                            : 'Inferred Labels (not available yet)',
                        distribution: stats.labelDistribution,
                        formatLabels: true,
                      ),
                      const SizedBox(height: 16),
                      _DistributionCard(
                        title: 'KMeans Clusters',
                        distribution: stats.clusterDistribution,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Geometry',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              _NumericLine(
                                label: 'Width Mean',
                                summary: stats.width,
                              ),
                              _NumericLine(
                                label: 'Height Mean',
                                summary: stats.height,
                              ),
                              _NumericLine(
                                label: 'Aspect Mean',
                                summary: stats.aspectRatio,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Exact duplicate groups: ${stats.exactDuplicateGroups}',
                              ),
                              Text(
                                'Near-duplicate groups: ${stats.nearDuplicateGroups}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.distribution,
    this.formatLabels = false,
  });

  final String title;
  final Map<String, int> distribution;
  final bool formatLabels;

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No values available yet.')
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: entries
                    .take(12)
                    .map(
                      (entry) => Chip(
                        label: Text(
                          '${formatLabels ? formatBrainrotLabel(entry.key) : entry.key}: ${entry.value}',
                        ),
                        backgroundColor: const Color(0xFFF4E4D6),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumericLine extends StatelessWidget {
  const _NumericLine({required this.label, required this.summary});

  final String label;
  final NumericSummary summary;

  @override
  Widget build(BuildContext context) {
    final display = summary.mean?.toStringAsFixed(2) ?? 'n/a';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $display'),
    );
  }
}
