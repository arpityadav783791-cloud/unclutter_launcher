/// High-performance text normalization utility for launcher search.
/// Folds diacritics / accented characters, normalizes case, and strips punctuation
/// so queries like "pokemon" match "Pokémon", and "whatsapp" matches "Whats-App".
class TextNormalizer {
  static const Map<String, String> _diacriticsMap = {
    // a
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
    'ă': 'a', 'ą': 'a', 'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a',
    'Å': 'a', 'Ā': 'a', 'Ă': 'a', 'Ą': 'a',
    // c
    'ç': 'c', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c', 'Ç': 'c', 'Ć': 'c',
    'Ĉ': 'c', 'Ċ': 'c', 'Č': 'c',
    // d
    'ď': 'd', 'đ': 'd', 'Ď': 'd', 'Đ': 'd',
    // e
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e',
    'ę': 'e', 'ě': 'e', 'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e', 'Ē': 'e',
    'Ĕ': 'e', 'Ė': 'e', 'Ę': 'e', 'Ě': 'e',
    // g
    'ĝ': 'g', 'ğ': 'g', 'ġ': 'g', 'ģ': 'g', 'Ĝ': 'g', 'Ğ': 'g', 'Ġ': 'g',
    'Ģ': 'g',
    // h
    'ĥ': 'h', 'ħ': 'h', 'Ĥ': 'h', 'Ħ': 'h',
    // i
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ĩ': 'i', 'ī': 'i', 'ĭ': 'i',
    'į': 'i', 'ı': 'i', 'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i', 'Ĩ': 'i',
    'Ī': 'i', 'Ĭ': 'i', 'Į': 'i', 'İ': 'i',
    // j
    'ĵ': 'j', 'Ĵ': 'j',
    // k
    'ķ': 'k', 'Ķ': 'k',
    // l
    'ĺ': 'l', 'ļ': 'l', 'ľ': 'l', 'ŀ': 'l', 'ł': 'l', 'Ĺ': 'l', 'Ļ': 'l',
    'Ľ': 'l', 'Ŀ': 'l', 'Ł': 'l',
    // n
    'ñ': 'n', 'ń': 'n', 'ņ': 'n', 'ň': 'n', 'ŋ': 'n', 'Ñ': 'n', 'Ń': 'n',
    'Ņ': 'n', 'Ň': 'n', 'Ŋ': 'n',
    // o
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
    'ŏ': 'o', 'ő': 'o', 'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o',
    'Ø': 'o', 'Ō': 'o', 'Ŏ': 'o', 'Ő': 'o',
    // r
    'ŕ': 'r', 'ŗ': 'r', 'ř': 'r', 'Ŕ': 'r', 'Ŗ': 'r', 'Ř': 'r',
    // s
    'ś': 's', 'ŝ': 's', 'ş': 's', 'š': 's', 'Ś': 's', 'Ŝ': 's', 'Ş': 's',
    'Š': 's',
    // t
    'ţ': 't', 'ť': 't', 'ŧ': 't', 'Ţ': 't', 'Ť': 't', 'Ŧ': 't',
    // u
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ũ': 'u', 'ū': 'u', 'ŭ': 'u',
    'ů': 'u', 'ű': 'u', 'ų': 'u', 'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ũ': 'u', 'Ū': 'u', 'Ŭ': 'u', 'Ů': 'u', 'Ű': 'u', 'Ų': 'u',
    // w
    'ŵ': 'w', 'Ŵ': 'w',
    // y
    'ý': 'y', 'ÿ': 'y', 'ŷ': 'y', 'Ý': 'y', 'Ÿ': 'y', 'Ŷ': 'y',
    // z
    'ź': 'z', 'ż': 'z', 'ž': 'z', 'Ź': 'z', 'Ż': 'z', 'Ž': 'z',
    // ligatures & specials
    'æ': 'ae', 'Æ': 'ae', 'œ': 'oe', 'Œ': 'oe', 'ß': 'ss',
  };

  static final RegExp _separatorRegex =
      RegExp(r'[\s\-_.,:;/\()\[\]{}&+=*~!?#@%^$|`"\x27]');

  /// Converts accented / Latin diacritics into plain ASCII equivalents.
  static String foldDiacritics(String text) {
    if (text.isEmpty) return text;
    final sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      sb.write(_diacriticsMap[char] ?? char);
    }
    return sb.toString();
  }

  /// Removes common separators, dashes, underscores, and punctuation.
  static String stripSeparators(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll(_separatorRegex, '');
  }

  /// Folds diacritics and lowercases text for standard comparison.
  static String normalize(String text) {
    return foldDiacritics(text).toLowerCase().trim();
  }

  /// Folds diacritics, lowercases, and strips all separators into a compact key.
  static String cleanKey(String text) {
    return stripSeparators(normalize(text));
  }

  /// Evaluates whether [target] matches [query], accounting for:
  /// 1. Direct normalized substring match
  /// 2. Cleaned key match (ignoring separators like `-` and spaces)
  /// 3. Word-prefix matches (e.g., "g m" matches "Google Maps")
  static bool matches(String target, String query) {
    final cleanQuery = cleanKey(query);
    if (cleanQuery.isEmpty) return false;

    final normTarget = normalize(target);
    final normQuery = normalize(query);

    // Direct normalized substring
    if (normTarget.contains(normQuery)) return true;

    // Separator-free match (e.g. "whatsapp" matches "Whats-App")
    final cleanTarget = cleanKey(target);
    if (cleanTarget.contains(cleanQuery)) return true;

    // Word prefix match: each query word starts a word in target
    final targetWords = normTarget.split(_separatorRegex).where((w) => w.isNotEmpty).toList();
    final queryWords = normQuery.split(_separatorRegex).where((w) => w.isNotEmpty).toList();

    if (queryWords.length > 1 && queryWords.length <= targetWords.length) {
      bool allWordsMatch = true;
      var targetIndex = 0;

      for (final qWord in queryWords) {
        var found = false;
        while (targetIndex < targetWords.length) {
          if (targetWords[targetIndex].startsWith(qWord)) {
            found = true;
            targetIndex++;
            break;
          }
          targetIndex++;
        }
        if (!found) {
          allWordsMatch = false;
          break;
        }
      }

      if (allWordsMatch) return true;
    }

    return false;
  }

  /// Scores a match for sorting relevance (lower number = better match):
  /// 0 = Exact normalized match
  /// 1 = Starts with normalized query
  /// 2 = Clean key starts with clean query
  /// 3 = Any word starts with query
  /// 4 = Substring match
  /// 5 = Clean key substring match
  /// 999 = No match
  static int scoreMatch(String target, String query) {
    final normTarget = normalize(target);
    final normQuery = normalize(query);
    final cleanTarget = cleanKey(target);
    final cleanQuery = cleanKey(query);

    if (cleanQuery.isEmpty) return 999;
    if (normTarget == normQuery || cleanTarget == cleanQuery) return 0;
    if (normTarget.startsWith(normQuery)) return 1;
    if (cleanTarget.startsWith(cleanQuery)) return 2;

    final words = normTarget.split(_separatorRegex);
    for (final word in words) {
      if (word.startsWith(normQuery)) return 3;
    }

    if (normTarget.contains(normQuery)) return 4;
    if (cleanTarget.contains(cleanQuery)) return 5;

    return 999;
  }
}
