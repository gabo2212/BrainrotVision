import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Map<String, String>>[
      {
        'title': 'Project Goal',
        'body':
            'BrainrotVision turns the dataset into a known-class brainrot identity detection problem: build metadata, inspect quality, train a lightweight recognizer, and support each prediction with nearest-neighbor evidence.',
      },
      {
        'title': 'Known Brainrot Identities',
        'body':
            'The recognizer is trained on five dataset identities: Ballerina Cappuccina, Bombardino Crocodilo, Cappuccino Assassino, Tralalero Tralala, and Tung Tung Sahur.',
      },
      {
        'title': 'Recognition Pipeline',
        'body':
            'A frozen ResNet50 embedding model feeds both the logistic regression classifier and the nearest-neighbor retrieval system. The app combines classifier probabilities, cluster assignment, and matching neighbors to explain why an identity was chosen.',
      },
      {
        'title': 'Known-Class Limitation',
        'body':
            'This is not open-world recognition. The system identifies one of the known brainrot classes present in the dataset, so unknown or out-of-distribution images may still be forced into the closest known class.',
      },
      {
        'title': 'Current Limits',
        'body':
            'Low-confidence results are softened as likely identities or best matches. Android support still depends on a writable local Flutter SDK in this environment.',
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
