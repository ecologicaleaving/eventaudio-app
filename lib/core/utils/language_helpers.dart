// Utilities for language display in EventAudio.

/// Returns the flag emoji for a given ISO 639-1 language code.
/// Falls back to the language code itself when not mapped.
String languageFlag(String langCode) {
  return _flags[langCode.toLowerCase()] ?? langCode.toUpperCase();
}

/// Returns the human-readable label for a given ISO 639-1 language code.
String languageLabel(String langCode) {
  return _labels[langCode.toLowerCase()] ?? langCode.toUpperCase();
}

const _flags = <String, String>{
  'original': '\u{1F3A4}', // microphone — lingua originale
  'it': '\u{1F1EE}\u{1F1F9}', // IT
  'en': '\u{1F1EC}\u{1F1E7}', // GB
  'de': '\u{1F1E9}\u{1F1EA}', // DE
  'fr': '\u{1F1EB}\u{1F1F7}', // FR
  'es': '\u{1F1EA}\u{1F1F8}', // ES
  'pt': '\u{1F1F5}\u{1F1F9}', // PT
  'nl': '\u{1F1F3}\u{1F1F1}', // NL
  'pl': '\u{1F1F5}\u{1F1F1}', // PL
  'ru': '\u{1F1F7}\u{1F1FA}', // RU
  'zh': '\u{1F1E8}\u{1F1F3}', // CN
  'ja': '\u{1F1EF}\u{1F1F5}', // JP
  'ar': '\u{1F1F8}\u{1F1E6}', // SA
};

const _labels = <String, String>{
  'original': 'Originale',
  'it': 'Italiano',
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Francais',
  'es': 'Espanol',
  'pt': 'Portugues',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ru': 'Русский',
  'zh': '中文',
  'ja': '日本語',
  'ar': 'العربية',
};
