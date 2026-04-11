import 'package:brainrotvision_flutter/utils/brainrot_labels.dart';

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
      exactDuplicateGroups:
          (json['exact_duplicate_groups'] as num?)?.toInt() ?? 0,
      nearDuplicateGroups:
          (json['near_duplicate_groups'] as num?)?.toInt() ?? 0,
      formatDistribution: parseDistribution('format_distribution'),
      labelDistribution: parseDistribution('label_distribution'),
      clusterDistribution: parseDistribution('kmeans_cluster_distribution'),
      width: NumericSummary.fromJson(json['width'] as Map<String, dynamic>?),
      height: NumericSummary.fromJson(json['height'] as Map<String, dynamic>?),
      aspectRatio: NumericSummary.fromJson(
        json['aspect_ratio'] as Map<String, dynamic>?,
      ),
    );
  }
}

class SimilarImage {
  const SimilarImage({
    required this.filename,
    required this.label,
    required this.displayLabel,
    required this.distance,
    required this.kmeansCluster,
    required this.rawRelativePath,
    required this.thumbnailUrl,
    required this.rawUrl,
  });

  final String? filename;
  final String? label;
  final String? displayLabel;
  final double? distance;
  final int? kmeansCluster;
  final String? rawRelativePath;
  final String? thumbnailUrl;
  final String? rawUrl;

  String get displayName => (displayLabel == null || displayLabel!.isEmpty)
      ? formatBrainrotLabel(label)
      : displayLabel!;

  factory SimilarImage.fromJson(Map<String, dynamic> json) {
    return SimilarImage(
      filename: json['filename'] as String?,
      label: json['label'] as String?,
      displayLabel: json['display_label'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      kmeansCluster: (json['kmeans_cluster'] as num?)?.toInt(),
      rawRelativePath: json['raw_relative_path'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      rawUrl: json['raw_url'] as String?,
    );
  }
}

class PredictionCandidate {
  const PredictionCandidate({
    required this.classId,
    required this.label,
    required this.displayLabel,
    required this.confidence,
  });

  final int? classId;
  final String label;
  final String displayLabel;
  final double confidence;

  String get displayName =>
      displayLabel.isEmpty ? formatBrainrotLabel(label) : displayLabel;

  factory PredictionCandidate.fromJson(Map<String, dynamic> json) {
    return PredictionCandidate(
      classId: (json['class_id'] as num?)?.toInt(),
      label: json['label'] as String? ?? 'unknown',
      displayLabel:
          json['display_label'] as String? ??
          formatBrainrotLabel(json['label'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NeighborAgreementSummary {
  const NeighborAgreementSummary({
    required this.agreesWithPrediction,
    required this.agreementRatio,
    required this.matchingNeighbors,
    required this.totalNeighbors,
    required this.majorityLabel,
    required this.majorityDisplayLabel,
  });

  final bool agreesWithPrediction;
  final double agreementRatio;
  final int matchingNeighbors;
  final int totalNeighbors;
  final String? majorityLabel;
  final String? majorityDisplayLabel;

  String get majorityDisplayName =>
      (majorityDisplayLabel == null || majorityDisplayLabel!.isEmpty)
      ? formatBrainrotLabel(majorityLabel)
      : majorityDisplayLabel!;

  factory NeighborAgreementSummary.fromJson(Map<String, dynamic> json) {
    return NeighborAgreementSummary(
      agreesWithPrediction: json['agrees_with_prediction'] as bool? ?? false,
      agreementRatio: (json['agreement_ratio'] as num?)?.toDouble() ?? 0,
      matchingNeighbors: (json['matching_neighbors'] as num?)?.toInt() ?? 0,
      totalNeighbors: (json['total_neighbors'] as num?)?.toInt() ?? 0,
      majorityLabel: json['majority_label'] as String?,
      majorityDisplayLabel: json['majority_display_label'] as String?,
    );
  }
}

class ClusterAlignmentSummary {
  const ClusterAlignmentSummary({
    required this.clusterId,
    required this.alignsWithPrediction,
    required this.majorityLabel,
    required this.majorityDisplayLabel,
    required this.majorityRatio,
  });

  final int? clusterId;
  final bool alignsWithPrediction;
  final String? majorityLabel;
  final String? majorityDisplayLabel;
  final double? majorityRatio;

  String get majorityDisplayName =>
      (majorityDisplayLabel == null || majorityDisplayLabel!.isEmpty)
      ? formatBrainrotLabel(majorityLabel)
      : majorityDisplayLabel!;

  factory ClusterAlignmentSummary.fromJson(Map<String, dynamic> json) {
    return ClusterAlignmentSummary(
      clusterId: (json['cluster_id'] as num?)?.toInt(),
      alignsWithPrediction: json['aligns_with_prediction'] as bool? ?? false,
      majorityLabel: json['majority_label'] as String?,
      majorityDisplayLabel: json['majority_display_label'] as String?,
      majorityRatio: (json['majority_ratio'] as num?)?.toDouble(),
    );
  }
}

class ClassificationResult {
  const ClassificationResult({
    required this.classId,
    required this.label,
    required this.displayLabel,
    required this.confidence,
    required this.classifierAvailable,
    required this.classifierStatus,
    required this.confidenceGap,
    required this.wording,
    required this.lowConfidence,
    required this.openSetWarning,
    required this.warningMessage,
    required this.topPredictions,
    required this.neighborAgreement,
    required this.clusterAlignment,
    required this.evidence,
  });

  final int? classId;
  final String label;
  final String displayLabel;
  final double confidence;
  final bool classifierAvailable;
  final String classifierStatus;
  final double? confidenceGap;
  final String wording;
  final bool lowConfidence;
  final bool openSetWarning;
  final String? warningMessage;
  final List<PredictionCandidate> topPredictions;
  final NeighborAgreementSummary? neighborAgreement;
  final ClusterAlignmentSummary? clusterAlignment;
  final List<String> evidence;

  String get displayName =>
      displayLabel.isEmpty ? formatBrainrotLabel(label) : displayLabel;

  bool get hasMixedEvidence => lowConfidence || openSetWarning;

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      classId: (json['class_id'] as num?)?.toInt(),
      label: json['label'] as String? ?? 'unknown',
      displayLabel:
          json['display_label'] as String? ??
          formatBrainrotLabel(json['label'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      classifierAvailable: json['classifier_available'] as bool? ?? false,
      classifierStatus:
          json['classifier_status'] as String? ??
          'Unavailable for this dataset',
      confidenceGap: (json['confidence_gap'] as num?)?.toDouble(),
      wording: json['wording'] as String? ?? 'Detected Brainrot',
      lowConfidence: json['low_confidence'] as bool? ?? false,
      openSetWarning: json['open_set_warning'] as bool? ?? false,
      warningMessage: json['warning_message'] as String?,
      topPredictions:
          ((json['top_predictions'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (item) =>
                    PredictionCandidate.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      neighborAgreement: json['neighbor_agreement'] == null
          ? null
          : NeighborAgreementSummary.fromJson(
              json['neighbor_agreement'] as Map<String, dynamic>,
            ),
      clusterAlignment: json['cluster_alignment'] == null
          ? null
          : ClusterAlignmentSummary.fromJson(
              json['cluster_alignment'] as Map<String, dynamic>,
            ),
      evidence: ((json['evidence'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
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
    required this.classifierAvailable,
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
  final bool classifierAvailable;
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
      classifierAvailable: json['classifier_available'] as bool? ?? false,
      clusterId: (json['cluster_id'] as num?)?.toInt(),
      classification: json['classification'] == null
          ? null
          : ClassificationResult.fromJson(
              json['classification'] as Map<String, dynamic>,
            ),
      similarImages:
          ((json['similar_images'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (item) => SimilarImage.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      uploadSha256: json['upload_sha256'] as String?,
    );
  }
}
