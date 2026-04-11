import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/about_screen.dart';
import 'package:brainrotvision_flutter/screens/insights_screen.dart';
import 'package:brainrotvision_flutter/screens/preview_screen.dart';
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

  Future<void> _pickAndNavigate(BuildContext context, ImageSource source) async {
    final state = context.read<AppState>();
    final picked = await state.pickImage(source);
    if (!context.mounted || !picked) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, state, _) {
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
                                  label: state.backendReady ? 'Backend Ready' : 'Backend Pending',
                                  color: state.backendReady
                                      ? const Color(0xFF1E7A4B)
                                      : const Color(0xFFB85D35),
                                ),
                                const SizedBox(width: 12),
                                _StatusChip(
                                  label: state.health?.classifierAvailable == true
                                      ? 'Classifier On'
                                      : 'Similarity Mode',
                                  color: const Color(0xFF17322D),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Choose an image source',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload a meme image, inspect the predicted cluster or label, and compare it against the closest dataset examples.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: state.isPicking
                                      ? null
                                      : () => _pickAndNavigate(context, ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Choose From Gallery'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: state.isPicking
                                      ? null
                                      : () => _pickAndNavigate(context, ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take Photo'),
                                ),
                              ],
                            ),
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
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Dataset Insights',
                            subtitle: 'Inspect counts, dimensions, duplicates, and cluster coverage.',
                            icon: Icons.query_stats_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const InsightsScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            title: 'Methodology',
                            subtitle: 'Review the CV pipeline, retrieval logic, and project limits.',
                            icon: Icons.menu_book_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
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
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricPill(
                                  label: 'Indexed Images',
                                  value: '${state.health?.samplesIndexed ?? state.stats?.validImages ?? 0}',
                                ),
                                _MetricPill(
                                  label: 'Formats',
                                  value: '${state.stats?.formatDistribution.length ?? 0}',
                                ),
                                _MetricPill(
                                  label: 'Exact Duplicates',
                                  value: '${state.stats?.exactDuplicateGroups ?? 0}',
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
