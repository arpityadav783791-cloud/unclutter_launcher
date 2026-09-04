import '../../apps/models/app_info.dart';

/// Abstract rule interface for extensible app classification.
abstract class ClassificationRule {
  bool matches(AppInfo app);
  String get categoryName;
}

/// Identifies Games using Android OS category metadata (CATEGORY_GAME = 0),
/// the isGame system flag, and gaming package/keyword heuristics.
class GameClassificationRule implements ClassificationRule {
  @override
  String get categoryName => 'Games';

  static const List<String> _gameKeywords = [
    'game',
    'gaming',
    'arcade',
    'casino',
    'puzzle',
    'candycrush',
    'pubg',
    'freefire',
    'clashofclans',
    'brawlstars',
    'subwaysurf',
    'roblox',
    'genshin',
    'rpg',
    'shooter',
    'racing',
    'fifa',
  ];

  @override
  bool matches(AppInfo app) {
    if (app.isGame || app.category == 0) return true;

    final pkgLower = app.packageName.toLowerCase();
    final nameLower = app.name.toLowerCase();

    for (final kw in _gameKeywords) {
      if (pkgLower.contains(kw) || nameLower.contains(kw)) {
        return true;
      }
    }
    return false;
  }
}

/// Identifies Social Media using Android OS metadata (CATEGORY_SOCIAL = 4),
/// well-known social media package structures, and keyword heuristics.
class SocialMediaClassificationRule implements ClassificationRule {
  @override
  String get categoryName => 'Social Media';

  static const List<String> _socialKeywords = [
    'instagram',
    'facebook',
    'tiktok',
    'snapchat',
    'twitter',
    'reddit',
    'pinterest',
    'threads',
    'discord',
    'telegram',
    'tumblr',
    'bereal',
    'mastodon',
    'bluesky',
    'wechat',
    'weibo',
  ];

  @override
  bool matches(AppInfo app) {
    if (app.category == 4) return true;

    final pkgLower = app.packageName.toLowerCase();
    final nameLower = app.name.toLowerCase();

    for (final kw in _socialKeywords) {
      if (pkgLower.contains(kw) || nameLower.contains(kw)) {
        return true;
      }
    }
    return false;
  }
}

/// Identifies Video and Short-Video streaming entertainment apps
/// using Android OS metadata (CATEGORY_VIDEO = 2) and video streaming patterns.
class VideoEntertainmentClassificationRule implements ClassificationRule {
  @override
  String get categoryName => 'Video & Entertainment';

  static const List<String> _videoKeywords = [
    'youtube',
    'netflix',
    'twitch',
    'hotstar',
    'primevideo',
    'disneyplus',
    'hulu',
    'streaming',
    'reels',
    'shorts',
    'vimeo',
    'dailymotion',
    'peacock',
    'paramount',
  ];

  @override
  bool matches(AppInfo app) {
    if (app.category == 2) return true;

    final pkgLower = app.packageName.toLowerCase();
    final nameLower = app.name.toLowerCase();

    for (final kw in _videoKeywords) {
      if (pkgLower.contains(kw) || nameLower.contains(kw)) {
        return true;
      }
    }
    return false;
  }
}

/// Identifies general high-distraction entertainment, audio streaming,
/// and infinite-scroll feeds (CATEGORY_AUDIO = 1, CATEGORY_NEWS = 5).
class GeneralEntertainmentClassificationRule implements ClassificationRule {
  @override
  String get categoryName => 'Entertainment';

  static const List<String> _entertainmentKeywords = [
    'spotify',
    'deezer',
    'soundcloud',
    'buzzfeed',
    '9gag',
    'memedroid',
    'funnyordie',
  ];

  @override
  bool matches(AppInfo app) {
    if (app.category == 1 || app.category == 5) return true;

    final pkgLower = app.packageName.toLowerCase();
    final nameLower = app.name.toLowerCase();

    for (final kw in _entertainmentKeywords) {
      if (pkgLower.contains(kw) || nameLower.contains(kw)) {
        return true;
      }
    }
    return false;
  }
}

/// Essential utilities that must NEVER be classified as a distraction.
class EssentialAppsExclusionRule {
  static const Set<String> _essentialPackages = {
    'com.android.settings',
    'com.android.dialer',
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.android.contacts',
    'com.google.android.contacts',
    'com.android.deskclock',
    'com.google.android.deskclock',
    'com.android.calculator2',
    'com.google.android.calculator',
    'com.sec.android.app.popupcalculator',
    'com.android.calendar',
    'com.google.android.calendar',
    'com.google.android.apps.maps',
    'com.android.camera',
    'com.google.android.GoogleCamera',
    'com.minimal.launcher',
    'com.minimal.launcher.settings',
  };

  static bool isEssential(AppInfo app) {
    final pkgLower = app.packageName.toLowerCase();
    return _essentialPackages.contains(pkgLower);
  }
}

/// Maintainable and extensible classifier orchestrating all detection rules.
class DistractionClassifier {
  static final List<ClassificationRule> _rules = [
    GameClassificationRule(),
    SocialMediaClassificationRule(),
    VideoEntertainmentClassificationRule(),
    GeneralEntertainmentClassificationRule(),
  ];

  /// Register custom classification rules dynamically at runtime.
  static void registerRule(ClassificationRule rule) {
    _rules.add(rule);
  }

  /// Evaluates whether an installed application is classified as a distraction.
  static bool isDistraction(AppInfo app) {
    if (EssentialAppsExclusionRule.isEssential(app)) {
      return false;
    }

    for (final rule in _rules) {
      if (rule.matches(app)) {
        return true;
      }
    }
    return false;
  }

  /// Returns the human-readable category name if detected, or null.
  static String? getCategoryLabel(AppInfo app) {
    if (EssentialAppsExclusionRule.isEssential(app)) {
      return null;
    }

    for (final rule in _rules) {
      if (rule.matches(app)) {
        return rule.categoryName;
      }
    }
    return null;
  }
}
