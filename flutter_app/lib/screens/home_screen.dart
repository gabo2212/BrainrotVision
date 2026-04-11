import 'package:brainrotvision_flutter/models/analysis_models.dart';
import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/about_screen.dart';
import 'package:brainrotvision_flutter/screens/insights_screen.dart';
import 'package:brainrotvision_flutter/screens/preview_screen.dart';
import 'package:brainrotvision_flutter/screens/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().bootstrap();
    });
  }

  Future<void> _pickAndNavigate(
    BuildContext context,
    ImageSource source,
  ) async {
    final state = context.read<AppState>();
    final picked = await state.pickImage(source);
    if (!context.mounted || !picked) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PreviewScreen()));
  }

  Future<void> _runAnalysisAction(
    BuildContext context, {
    required Future<bool> Function(AppState state) action,
  }) async {
    final state = context.read<AppState>();
    final completed = await action(state);
    if (!context.mounted || !completed) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ResultsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, state, _) {
        final demoBusy = state.isAnalyzing || state.isLoadingSamples;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF5EBDD),
                  Color(0xFFF2D4BF),
                  Color(0xFFE2E7D2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BrainrotVision',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17322D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A local-first computer vision demo for clustering, retrieval, and optional classification of Italian brainrot images.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF36544E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StatusChip(
                                  label: state.backendReady
                                      ? 'Backend Ready'
                                      : 'Backend Pending',
                                  color: state.backendReady
                                      ? const Color(0xFF1E7A4B)
                                      : const Color(0xFFB85D35),
                                ),
                                const SizedBox(width: 12),
                                _StatusChip(
                                  label:
                                      state.health?.classifierAvailable == true
                                      ? 'Classifier On'
                                      : 'Similarity Mode',
                                  color: const Color(0xFF17322D),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start instantly or bring your own image',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Run a live dataset-backed demo in one tap, or upload a meme image to inspect its cluster, label, and nearest neighbors.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: demoBusy
                                      ? null
                                      : () => _runAnalysisAction(
                                          context,
                                          action: (appState) =>
                                              appState.analyzeRandomSample(),
                                        ),
                                  icon: const Icon(Icons.shuffle_outlined),
                                  label: Text(
                                    state.isAnalyzing
                                        ? 'Running Demo...'
                                        : 'Use Random Dataset Image',
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: demoBusy
                                      ? null
                                      : () => _runAnalysisAction(
                                          context,
                                          action: (appState) =>
                                              appState.runSampleDemo(),
                                        ),
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('Try Sample Demo'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: demoBusy
                                      ? null
                                      : () => _runAnalysisAction(
                                          context,
                                          action: (appState) =>
                                              appState.runSampleDemo(),
                                        ),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('View Example Result'),
                                ),
                                FilledButton.icon(
                                  onPressed:
                                      state.isPicking || state.isAnalyzing
                                      ? null
                                      : () => _pickAndNavigate(
                                          context,
                                          ImageSource.gallery,
                                        ),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text('Choose From Gallery'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed:
                                      state.isPicking || state.isAnalyzing
                                      ? null
                                      : () => _pickAndNavigate(
                                          context,
                                          ImageSource.camera,
                                        ),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take Photo'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap a sample below for a real backend call using the indexed brainrot dataset.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF36544E),
                              ),
                            ),
                            if (state.isLoadingSamples) ...[
                              const SizedBox(height: 16),
                              const LinearProgressIndicator(),
                            ],
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                state.errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF8E2E1B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live Sample Gallery',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Each thumbnail runs analysis against the real dataset artifacts, not mock data.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton.icon(
                                  onPressed: state.isLoadingSamples
                                      ? null
                                      : () => context
                                            .read<AppState>()
                                            .loadSamples(),
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (state.sampleGallery.isEmpty &&
                                state.isLoadingSamples)
                              const SizedBox(
                                height: 164,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (state.sampleGallery.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4E4D6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Sample thumbnails will appear here once the backend exposes indexed dataset images.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              )
                            else
                              SizedBox(
                                height: 184,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.sampleGallery.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final sample = state.sampleGallery[index];
                                    return _SampleThumbCard(
                                      sample: sample,
                                      imageUrl: state.resolveUrl(
                                        sample.thumbnailUrl,
                                      ),
                                      onTap: demoBusy
                                          ? null
                                          : () => _runAnalysisAction(
                                              context,
                                              action: (appState) => appState
                                                  .analyzeSample(sample),
                                            ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Dataset Insights',
                            subtitle:
                                'Inspect counts, dimensions, duplicates, and cluster coverage.',
                            icon: Icons.query_stats_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const InsightsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            title: 'Methodology',
                            subtitle:
                                'Review the CV pipeline, retrieval logic, and project limits.',
                            icon: Icons.menu_book_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AboutScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Snapshot',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricPill(
                                  label: 'Indexed Images',
                                  value:
                                      '${state.health?.samplesIndexed ?? state.stats?.validImages ?? 0}',
                                ),
                                _MetricPill(
                                  label: 'Formats',
                                  value:
                                      '${state.stats?.formatDistribution.length ?? 0}',
                                ),
                                _MetricPill(
                                  label: 'Exact Duplicates',
                                  value:
                                      '${state.stats?.exactDuplicateGroups ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SampleThumbCard extends StatelessWidget {
  const _SampleThumbCard({
    required this.sample,
    required this.imageUrl,
    required this.onTap,
  });

  final SimilarImage sample;
  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: imageUrl.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFE8D8C9),
                            child: Center(
                              child: Icon(Icons.image_not_supported_outlined),
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                                  color: Color(0xFFE8D8C9),
                                  child: Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sample.label ?? sample.filename ?? 'Dataset sample',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  sample.filename ?? 'Tap to analyze',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFC8623B)),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17322D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
