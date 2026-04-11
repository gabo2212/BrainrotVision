import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/results_screen.dart';
import 'package:brainrotvision_flutter/utils/external_samples.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrippleTScreen extends StatefulWidget {
  const TrippleTScreen({super.key});

  @override
  State<TrippleTScreen> createState() => _TrippleTScreenState();
}

class _TrippleTScreenState extends State<TrippleTScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  PlayerState _playerState = PlayerState.stopped;

  // All web samples + highlighted Tripple T entries shown at top
  final List<ExternalSampleEntry> _allSamples = kExternalSamples;
  final List<ExternalSampleEntry> _ttSamples = kTrippleTSamples;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    // Auto-play on open
    _playAudio();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    await _player.play(
      UrlSource(
        'https://italianbrainrot.miraheze.org/wiki/File:Tung_Tung_Tung_Sahur_Audio.wav',
      ),
    );
  }

  Future<void> _stopAudio() async => _player.stop();

  Future<void> _analyzeEntry(
    BuildContext context,
    ExternalSampleEntry entry,
  ) async {
    final state = context.read<AppState>();
    await _stopAudio();
    final ok = await state.analyzeExternalUrl(
      entry.imageUrl,
      thumbnailUrl: entry.imageUrl,
    );
    if (!context.mounted || !ok) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
    );
  }

  Future<void> _analyzeRandomTT(BuildContext context) async {
    if (_ttSamples.isEmpty) return;
    final entry = _ttSamples[Random().nextInt(_ttSamples.length)];
    await _analyzeEntry(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = context.watch<AppState>().isAnalyzing;
    final isPlaying = _playerState == PlayerState.playing;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                floating: true,
                title: const Text(
                  'Tripple T',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero banner
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF533483).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🪵',
                                style: TextStyle(fontSize: 56),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tung Tung Tung Sahur',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A terrifying anomaly that appears during Sahur.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _analyzeRandomTT(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFE94560),
                                    ),
                                    icon: const Icon(Icons.shuffle_outlined),
                                    label: const Text(
                                      'Analyze Random Tung Tung Sahur',
                                    ),
                                  ),
                                  if (isPlaying)
                                    OutlinedButton.icon(
                                      onPressed: _stopAudio,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      icon: const Icon(Icons.stop_outlined),
                                      label: const Text('Stop Audio'),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: _playAudio,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      icon: const Icon(Icons.play_arrow_outlined),
                                      label: const Text('Play Again'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Web Brainrot Gallery',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap any card to run live ML analysis on the real pipeline.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final entry = _allSamples[i];
                      return _WebSampleCard(
                        entry: entry,
                        onTap: busy
                            ? null
                            : () => _analyzeEntry(context, entry),
                      );
                    },
                    childCount: _allSamples.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebSampleCard extends StatelessWidget {
  const _WebSampleCard({required this.entry, required this.onTap});

  final ExternalSampleEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTT = entry.label == 'tung_tung_sahur';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTT
                ? const Color(0xFFE94560).withValues(alpha: 0.8)
                : Colors.white12,
            width: isTT ? 2 : 1,
          ),
          color: const Color(0xFF16213E),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                entry.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorBuilder: (ctx, err, st) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to analyze',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

