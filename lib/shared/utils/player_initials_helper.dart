class PlayerInitialsHelper {
  PlayerInitialsHelper._();

  /// Computes true initials based on first and last name.
  /// E.g. "Chet Mehta" -> "CM", "Neal Patel" -> "NP", "Vilmer Villaverde" -> "VV".
  /// Falls back to first 2 letters if single word, or [fallback] if empty.
  static String compute(String? fullName, [String? fallback]) {
    if (fullName != null) {
      final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.length == 1) {
        final single = parts.first;
        return single.substring(0, single.length.clamp(1, 2)).toUpperCase();
      }
    }
    if (fallback != null && fallback.trim().isNotEmpty && fallback != '?') {
      final clean = fallback.trim().toUpperCase();
      return clean.length > 2 ? clean.substring(0, 2) : clean;
    }
    return '?';
  }
}
