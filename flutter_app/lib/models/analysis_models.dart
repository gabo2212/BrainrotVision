class BackendHealth {
  const BackendHealth({
    required this.ready,
    required this.samplesIndexed,
    required this.classifierAvailable,
  });

  final bool ready;
  final int samplesIndexed;
  final bool classifierAvailable;

  factory BackendHealth.fromJson(Map<String, dynamic> json) {
    return BackendHealth(
      ready: json['ready'] as bool? ?? false,
      samplesIndexed: json['samples_indexed'] as int? ?? 0,
      classifierAvailable: json['classifier_available'] as bool? ?? false,
    );
  }
}

class NumericSummary {
  const NumericSummary({
    required this.mean,
    required this.median,
    required this.min,
    required this.max,
  });

  final double? mean;
  final double? median;
  final double? min;
  final double? max;

  factory NumericSummary.fromJson(Map<String, dynamic>? json) {
    double? parseValue(String key) {
      final value = json?[key];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return null;
    }

    return NumericSummary(
      mean: parseValue('mean'),
      median: parseValue('median'),
      min: parseValue('min'),
      max: parseValue('max'),
    );
  }
}

class DatasetStats {
  const DatasetStats({
    required this.totalImages,
    required this.validImages,
    required this.corruptImages,
    required this.hasLabels,
    required this.artifactReady,
    required this.exactDuplicateGroups,
    required this.nearDuplicateGroups,
    required this.formatDistribution,
    required this.labelDistribution,
    required this.clusterDistribution,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  final int totalImages;
  final int validImages;
  final int corruptImages;
  final bool hasLabels;
  final bool artifactReady;
  final int exactDuplicateGroups;
  final int nearDuplicateGroups;
  final Map<String, int> formatDistribution;
  final Map<String, int> labelDistribution;
  final Map<String, int> clusterDistribution;
  final NumericSummary width;
  final NumericSummary height;
  final NumericSummary aspectRatio;

  factory DatasetStats.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseDistribution(String key) {
      final raw = (json[key] as Map<String, dynamic>?) ?? <String, dynamic>{};
      return raw.map((label, value) => MapEntry(label, (value as num).toInt()));
    }

    return DatasetStats(
      totalImages: (json['total_images'] as num?)?.toInt() ?? 0,
      validImages: (json['valid_images'] as num?)?.toInt() ?? 0,
      corruptImages: (json['corrupt_images'] as num?)?.toInt() ?? 0,
      hasLabels: json['has_labels'] as bool? ?? false,
      artifactReady: json['artifact_ready'] as bool? ?? false,
      exactDuplicateGroups: (json['exact_duplicate_groups'] as num?)?.toInt() ?? 0,
      nearDuplicateGroups: (json['near_duplicate_groups'] as num?)?.toInt() ?? 0,
      formatDistribution: parseDistribution('format_distribution'),
      labelDistribution: parseDistribution('label_distribution'),
      clusterDistribution: parseDistribution('kmeans_cluster_distribution'),
      width: NumericSummary.fromJson(json['width'] as Map<String, dynamic>?),
      height: NumericSummary.fromJson(json['height'] as Map<String, dynamic>?),
      aspectRatio: NumericSummary.fromJson(json['aspect_ratio'] as Map<String, dynamic>?),
    );
  }
}

class SimilarImage {
  const SimilarImage({
    required this.filename,
    required this.label,
    required this.distance,
    required this.kmeansCluster,
    required this.thumbnailUrl,
    required this.rawUrl,
  });

  final String? filename;
  final String? label;
  final double? distance;
  final int? kmeansCluster;
  final String? thumbnailUrl;
  final String? rawUrl;

  factory SimilarImage.fromJson(Map<String, dynamic> json) {
    return SimilarImage(
      filename: json['filename'] as String?,
      label: json['label'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      kmeansCluster: (json['kmeans_cluster'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      rawUrl: json['raw_url'] as String?,
    );
  }
}

class ClassificationResult {
  const ClassificationResult({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      label: json['label'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalysisResult {
  const AnalysisResult({
    required this.filename,
    required this.width,
    required this.height,
    required this.format,
    required this.brightness,
    required this.contrast,
    required this.clusterId,
    required this.classification,
    required this.similarImages,
    required this.uploadSha256,
  });

  final String filename;
  final int width;
  final int height;
  final String format;
  final double brightness;
  final double contrast;
  final int? clusterId;
  final ClassificationResult? classification;
  final List<SimilarImage> similarImages;
  final String? uploadSha256;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      filename: json['filename'] as String? ?? 'upload',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      format: json['format'] as String? ?? 'UNKNOWN',
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0,
      clusterId: (json['cluster_id'] as num?)?.toInt(),
      classification: json['classification'] == null
          ? null
          : ClassificationResult.fromJson(json['classification'] as Map<String, dynamic>),
      similarImages: ((json['similar_images'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => SimilarImage.fromJson(item as Map<String, dynamic>))
          .toList(),
      uploadSha256: json['upload_sha256'] as String?,
    );
  }
}
