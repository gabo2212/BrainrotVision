import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Map<String, String>>[
      {
        'title': 'Project Goal',
        'body':
            'BrainrotVision treats the dataset as a computer vision analysis problem: build metadata, inspect image quality, cluster visual themes, and retrieve the closest examples for any uploaded image.',
      },
      {
        'title': 'Core Stack',
        'body':
            'FastAPI serves the inference API, a shared Python package handles embeddings and artifact generation, and Flutter provides the mobile-friendly client for upload and results.',
      },
      {
        'title': 'Why Similarity First',
        'body':
            'The dataset may not expose clean labels. Visual embeddings, KMeans clusters, and nearest-neighbor search stay useful even when labels are weak or absent.',
      },
      {
        'title': 'Current Limits',
        'body':
            'Classification only appears when the folder structure supports it cleanly. Android support depends on a local SDK bootstrap in this environment.',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('About & Methodology')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title']!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(section['body']!),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: sections.length,
      ),
    );
  }
}
