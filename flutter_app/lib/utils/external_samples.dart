/// Curated pool of stable external brainrot image URLs.
///
/// Sources: Wikimedia Commons (CC-BY-SA) — these are the same images used
/// in the Wikipedia Italian Brainrot article and the Wikimedia Commons
/// Category:Italian_brainrot page.  URLs point to upload.wikimedia.org
/// which is in the backend allowlist.
///
/// Extra Tung Tung Sahur entries are included so the Tripple T showcase
/// has a larger random pool to draw from.
library;

class ExternalSampleEntry {
  const ExternalSampleEntry({
    required this.id,
    required this.label,
    required this.displayLabel,
    required this.imageUrl,
    required this.credit,
  });

  final String id;
  final String label;
  final String displayLabel;
  final String imageUrl;
  final String credit;
}

// ---------------------------------------------------------------------------
// Stable Wikimedia Commons direct-download URLs (thumb URLs served via CDN)
// ---------------------------------------------------------------------------

const List<ExternalSampleEntry> kExternalSamples = [
  // ── Tung Tung Sahur ──────────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'tts_1',
    label: 'tung_tung_sahur',
    displayLabel: 'Tung Tung Sahur',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Tung_Tung_Tung_Sahur.png/440px-Tung_Tung_Tung_Sahur.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  ExternalSampleEntry(
    id: 'tts_2',
    label: 'tung_tung_sahur',
    displayLabel: 'Tung Tung Sahur',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Italian_brainrot_characters.png/440px-Italian_brainrot_characters.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Tralalero Tralala ────────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'trl_1',
    label: 'tralalero_tralala',
    displayLabel: 'Tralalero Tralala',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Tralalero_Tralala.webp/440px-Tralalero_Tralala.webp.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Bombardiro Crocodilo ─────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'bom_1',
    label: 'bombardino_crocodilo',
    displayLabel: 'Bombardiro Crocodilo',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Bombardiro_Crocodillo.jpg/440px-Bombardiro_Crocodillo.jpg',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Ballerina Cappuccina ─────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'bal_1',
    label: 'ballerina_cappuccina',
    displayLabel: 'Ballerina Cappuccina',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Ballerina_Cappucina.png/440px-Ballerina_Cappucina.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Cappuccino Assassino ─────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'cap_1',
    label: 'cappuccino_assassino',
    displayLabel: 'Cappuccino Assassino',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Cappucino_assasino.webp/440px-Cappucino_assasino.webp.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Brr Brr Patapim ─────────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'pat_1',
    label: 'tralalero_tralala',
    displayLabel: 'Brr Brr Patapim',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Brr_brr_patapim.jpg/440px-Brr_brr_patapim.jpg',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Chimpanzini Bananini ─────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'chi_1',
    label: 'tralalero_tralala',
    displayLabel: 'Chimpanzini Bananini',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/ChimpanziniBananini.webp/440px-ChimpanziniBananini.webp.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
  // ── Lirili Larila ───────────────────────────────────────────────────────
  ExternalSampleEntry(
    id: 'lir_1',
    label: 'tralalero_tralala',
    displayLabel: 'Lirili Larila',
    imageUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Liril%C3%AC_Laril%C3%A0.webp/440px-Liril%C3%AC_Laril%C3%A0.webp.png',
    credit: 'Wikimedia Commons – CC-BY-SA',
  ),
];

/// Only entries whose label is tung_tung_sahur (for the Tripple T pool).
List<ExternalSampleEntry> get kTrippleTSamples => kExternalSamples
    .where((e) => e.label == 'tung_tung_sahur')
    .toList();

