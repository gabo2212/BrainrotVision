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
          appBar: AppBar(title: const Text('Results')),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Summary',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _ResultChip(
                                    label: 'Cluster',
                                    value: '${result.clusterId ?? 'N/A'}',
                                  ),
                                  _ResultChip(
                                    label: 'Format',
                                    value: result.format,
                                  ),
                                  _ResultChip(
                                    label: 'Brightness',
                                    value: result.brightness.toStringAsFixed(1),
                                  ),
                                  _ResultChip(
                                    label: 'Contrast',
                                    value: result.contrast.toStringAsFixed(1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (result.classification != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4E4D6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Classification',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${result.classification!.label} • ${(result.classification!.confidence * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'No classifier was trained for this dataset. Retrieval and clustering remain active.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Most Similar Dataset Images',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final image = result.similarImages[index];
                            final thumbnailUrl = state.resolveUrl(
                              image.thumbnailUrl,
                            );
                            return SizedBox(
                              width: 220,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: thumbnailUrl.isEmpty
                                              ? const ColoredBox(
                                                  color: Color(0xFFE8D8C9),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons
                                                          .image_not_supported_outlined,
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
                                                        color: Color(
                                                          0xFFE8D8C9,
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        image.label ??
                                            image.filename ??
                                            'Dataset image',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distance: ${(image.distance ?? 0).toStringAsFixed(3)}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemCount: result.similarImages.length,
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

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.value});

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
