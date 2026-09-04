import '../models/app_info.dart';

/// Service to automatically detect and classify apps that belong to
/// distracting categories such as Social Media, Video/Entertainment, and Games.
class DistractionDetector {
  /// Well-known package names for distracting applications
  static const Set<String> _knownDistractionPackages = {
    // Social Media
    'com.instagram.android',
    'com.instagram.lite',
    'com.instagram.barcelona', // Threads
    'com.facebook.katana',
    'com.facebook.lite',
    'com.facebook.orca', // Messenger
    'com.zhiliaoapp.musically', // TikTok
    'com.ss.android.ugc.trill', // TikTok
    'com.ss.android.ugc.aweme',
    'com.twitter.android',
    'com.twitter.android.lite',
    'com.snapchat.android',
    'com.reddit.frontpage',
    'com.pinterest',
    'com.linkedin.android',
    'com.discord',
    'org.telegram.messenger',
    'org.telegram.messenger.web',
    'org.thunderdog.challegram',
    'com.bereal.ft',
    'com.tumblr',

    // Video Streaming & Entertainment
    'com.google.android.youtube',
    'com.google.android.apps.youtube.music',
    'com.netflix.mediaclient',
    'com.amazon.avod.thirdpartyclient', // Prime Video
    'tv.twitch.android.app',
    'in.startv.hotstar',
    'com.disney.disneyplus',
    'com.spotify.music',

    // Popular Games
    'com.king.candycrushsaga',
    'com.king.candycrushsodasaga',
    'com.dts.freefireth',
    'com.dts.freefiremax',
    'com.pubg.imobile',
    'com.pubg.krmobile',
    'com.tencent.ig',
    'com.supercell.clashofclans',
    'com.supercell.clashroyale',
    'com.supercell.brawlstars',
    'com.ea.gp.fifamobile',
    'com.roblox.client',
    'com.activision.callofduty.shooter',
    'com.subwaysurfers',
    'com.kiloo.subwaysurf',
    'com.playrix.gardenscapes',
    'com.playrix.homescapes',
    'com.miHoYo.GenshinImpact',
  };

  /// Common keywords found in distracting app package names and app titles
  static const List<String> _distractionKeywords = [
    'instagram',
    'facebook',
    'tiktok',
    'snapchat',
    'twitter',
    'reddit',
    'pinterest',
    'netflix',
    'twitch',
    'hotstar',
    'youtube',
    'reels',
    'shorts',
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
  ];

  /// Package prefixes or names that must NEVER be classified as distraction
  static const Set<String> _essentialPackages = {
    'com.android.settings',
    'com.android.dialer',
    'com.google.android.dialer',
    'com.android.contacts',
    'com.google.android.contacts',
    'com.android.deskclock',
    'com.google.android.deskclock',
    'com.android.calculator2',
    'com.google.android.calculator',
    'com.android.calendar',
    'com.google.android.calendar',
  };

  /// Checks whether an application belongs to distracting categories
  /// (Social Media, Video/Entertainment, or Games).
  static bool isDistraction(AppInfo app) {
    final pkgLower = app.packageName.toLowerCase();
    if (_essentialPackages.contains(pkgLower)) return false;

    // 1. Android OS ApplicationInfo.category checks
    // CATEGORY_GAME = 0, CATEGORY_VIDEO = 2, CATEGORY_SOCIAL = 4
    if (app.isGame || app.category == 0 || app.category == 4 || app.category == 2) {
      return true;
    }

    // 2. Known package registry
    if (_knownDistractionPackages.contains(pkgLower)) {
      return true;
    }

    // 3. Name or package keywords
    final nameLower = app.name.toLowerCase();
    for (final keyword in _distractionKeywords) {
      if (pkgLower.contains(keyword) || nameLower.contains(keyword)) {
        return true;
      }
    }

    // If it did not match any distraction rule, and is a system app, exclude it
    if (app.isSystemApp) return false;

    return false;
  }
}
