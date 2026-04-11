String formatBrainrotLabel(String? rawLabel, {String fallback = 'Unknown'}) {
  if (rawLabel == null || rawLabel.trim().isEmpty) {
    return fallback;
  }
  final normalized = rawLabel.trim().replaceAll('-', '_');
  final parts = normalized
      .split('_')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return fallback;
  }
  return parts
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
