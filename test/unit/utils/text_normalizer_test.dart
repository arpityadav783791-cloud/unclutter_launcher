import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_launcher/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer Tests', () {
    test('folds Latin diacritics and accents correctly', () {
      expect(TextNormalizer.foldDiacritics('Café'), equals('Cafe'));
      expect(TextNormalizer.foldDiacritics('Pokémon'), equals('Pokemon'));
      expect(TextNormalizer.foldDiacritics('München'), equals('Munchen'));
      expect(TextNormalizer.foldDiacritics('Español'), equals('Espanol'));
      expect(TextNormalizer.foldDiacritics('François'), equals('Francois'));
      expect(TextNormalizer.foldDiacritics('Straße'), equals('Strasse'));
      expect(TextNormalizer.foldDiacritics('Cœur'), equals('Coeur'));
    });

    test('strips separators and punctuation', () {
      expect(TextNormalizer.stripSeparators('Whats-App'), equals('WhatsApp'));
      expect(TextNormalizer.stripSeparators('sub_zero.app!'), equals('subzeroapp'));
      expect(TextNormalizer.stripSeparators('Google / Maps (Beta)'), equals('GoogleMapsBeta'));
    });

    test('matches queries with accents against unaccented targets and vice-versa', () {
      expect(TextNormalizer.matches('Pokémon GO', 'pokemon'), isTrue);
      expect(TextNormalizer.matches('Pokemon GO', 'pokémon'), isTrue);
      expect(TextNormalizer.matches('Café Racer', 'cafe'), isTrue);
      expect(TextNormalizer.matches('Uber Eats', 'über'), isTrue);
    });

    test('matches queries ignoring dashes, dots, spaces, and punctuation', () {
      expect(TextNormalizer.matches('Whats-App Messenger', 'whatsapp'), isTrue);
      expect(TextNormalizer.matches('WhatsApp', 'whats-app'), isTrue);
      expect(TextNormalizer.matches('E-Mail Client', 'email'), isTrue);
      expect(TextNormalizer.matches('TickTick: To-Do', 'ticktick todo'), isTrue);
    });

    test('multi-word prefix search works', () {
      expect(TextNormalizer.matches('Google Maps', 'g m'), isTrue);
      expect(TextNormalizer.matches('YouTube Music', 'yt m'), isFalse); // 'yt' is not prefix of 'youtube'
      expect(TextNormalizer.matches('YouTube Music', 'you mus'), isTrue);
    });

    test('scoreMatch ranks exact and prefix matches higher than substrings', () {
      final exactScore = TextNormalizer.scoreMatch('Camera', 'camera');
      final prefixScore = TextNormalizer.scoreMatch('Camera Pro', 'camera');
      final wordScore = TextNormalizer.scoreMatch('Pro Camera', 'camera');
      final substringScore = TextNormalizer.scoreMatch('MyCameraApp', 'camera');
      final noScore = TextNormalizer.scoreMatch('Phone', 'camera');

      expect(exactScore, equals(0));
      expect(prefixScore, equals(1));
      expect(wordScore, equals(3));
      expect(substringScore, equals(4));
      expect(noScore, equals(999));

      expect(exactScore < prefixScore, isTrue);
      expect(prefixScore < wordScore, isTrue);
      expect(wordScore < substringScore, isTrue);
      expect(substringScore < noScore, isTrue);
    });
  });
}
