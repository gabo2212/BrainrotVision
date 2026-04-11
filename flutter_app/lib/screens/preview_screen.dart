import 'dart:io';

import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final selectedImage = state.selectedImage;
        return Scaffold(
          appBar: AppBar(title: const Text('Recognition Preview')),
          body: selectedImage == null
              ? const Center(
                  child: Text('Select an image from the home screen first.'),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.file(
                            File(selectedImage.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        selectedImage.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: state.isAnalyzing
                            ? null
                            : () async {
                                final success = await context
                                    .read<AppState>()
                                    .analyzeSelectedImage();
                                if (!context.mounted || !success) {
                                  return;
                                }
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ResultsScreen(),
                                  ),
                                );
                              },
                        icon: state.isAnalyzing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_mosaic_outlined),
                        label: Text(
                          state.isAnalyzing
                              ? 'Detecting Identity...'
                              : 'Detect Brainrot Identity',
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF8E2E1B)),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
