import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/language_provider.dart';
import 'services/sound_service.dart';
import 'services/bookmark_service.dart';
import 'services/reading_service.dart';
import 'services/pop_culture_bookmark_service.dart';
import 'services/onboarding_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/premium_service.dart';
import 'services/daily_free_service.dart';
import 'services/settings_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized first. On web there's no bundled config
  // (google-services.json only covers Android), so init throws — and every
  // later Firebase call (auth, Firestore) would then throw too and freeze
  // the app before it renders. Track whether init actually succeeded and
  // skip all Firebase/notification work if it didn't, so the UI still shows
  // (login & cloud sync just won't work — fine for a web preview).
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed (expected on web without config): $e');
  }

  // Local services.
  final langNotifier = LanguageNotifier();
  await langNotifier.init();
  await SoundService.init();
  await ReadingService.init();
  await PopCultureBookmarkService.init();
  await OnboardingService.init();
  await PremiumService.init();
  await DailyFreeService.init();

  if (firebaseReady) {
    // Firebase services — non-blocking, fail silently.
    FirebaseAuthService.instance.ensureAnonymous().then((_) {
      // Sync cloud → local on startup in the background (fire-and-forget).
      _syncFromCloud().catchError((e) {
        debugPrint('Firestore sync failed: $e');
      });
      // Live premium-status listener for the app's lifetime — keeps
      // PremiumService's cache/notifier in sync so gating updates instantly
      // without needing a restart once payment is confirmed.
      PremiumService.watch().listen((_) {}, onError: (e) {
        debugPrint('Premium status listener failed: $e');
      });
    }).catchError((e) {
      debugPrint('Auth init failed: $e');
    });

    // Notifications aren't needed for the first frame, and requesting the
    // permission can pop a system dialog that blocks on the user's response —
    // run it in the background instead of delaying the splash screen.
    unawaited(_initNotifications());
  }

  runApp(LanguageProvider(notifier: langNotifier, child: const MytheraApp()));
}

Future<void> _initNotifications() async {
  try {
    await NotificationService.instance.init();
    // Re-arm the daily reminder if the user has it enabled. force: true
    // because Android clears scheduled alarms on every device reboot and
    // this app has no boot receiver to redo it automatically — the saved
    // "already scheduled" flag can be stale, so always re-issue the alarm
    // here rather than trusting it.
    if (await SettingsService.getDailyReminders()) {
      await NotificationService.instance.scheduleDailyReminder(force: true);
    }
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
}

/// Downloads data from Firestore and merges into local SharedPreferences.
/// Local data is kept as cache; Firestore is the source of truth.
Future<void> _syncFromCloud() async {
  final uid = FirebaseAuthService.instance.uid;
  if (uid == null) return;

  try {
    final cloud = await FirestoreService.instance.syncCloudToLocal(uid);

    // ── God favorites — cloud + local union ──
    final cloudGodFavs = (cloud['godFavorites'] as Set<String>?) ?? {};
    final localGodFavs = await BookmarkService.load();
    final mergedGodFavs = {...localGodFavs, ...cloudGodFavs};
    await BookmarkService.save(mergedGodFavs);

    // ── Pop culture favorites — cloud + local union ──
    final cloudPcFavs = (cloud['pcFavorites'] as Set<String>?) ?? {};
    final localPcFavs = PopCultureBookmarkService.ids;
    final mergedPcFavs = {...localPcFavs, ...cloudPcFavs};
    for (final id in mergedPcFavs) {
      if (!PopCultureBookmarkService.isFavorite(id)) {
        await PopCultureBookmarkService.toggle(id);
      }
    }

    // ── Reading progress — cloud overwrites if cloud has more data ──
    final cloudReading = (cloud['reading'] as Map<String, dynamic>?) ?? {};
    if (cloudReading.isNotEmpty) {
      final cloudReadGods =
          (cloudReading['readGodIds'] as List?)?.cast<String>().toSet() ?? {};
      final cloudReadStories =
          (cloudReading['readStoryIds'] as List?)?.cast<String>().toSet() ?? {};
      final localReadGods = await _loadLocalReadGods();
      final localReadStories = await _loadLocalReadStories();
      // Union: merge cloud + local
      final mergedReadGods = {...localReadGods, ...cloudReadGods};
      final mergedReadStories = {...localReadStories, ...cloudReadStories};
      await _saveLocalReadGods(mergedReadGods);
      await _saveLocalReadStories(mergedReadStories);
      debugPrint(
          'Reading sync: ${mergedReadGods.length} gods, ${mergedReadStories.length} stories');
    }

    // ── Settings — cloud overwrites local if cloud has data ──
    final cloudSettings = (cloud['settings'] as Map<String, dynamic>?) ?? {};
    if (cloudSettings.isNotEmpty) {
      await _mergeCloudSettings(cloudSettings);
    }

    // ── Daily free-unlocked gods — union set, keep later claim date ──
    final cloudFree = (cloud['freeGods'] as Map<String, dynamic>?) ?? {};
    final cloudFreeIds =
        (cloudFree['ids'] as List?)?.cast<String>().toSet() ?? <String>{};
    final cloudFreeDate = cloudFree['lastClaimDate'] as String? ?? '';
    await DailyFreeService.mergeFromCloud(cloudFreeIds, cloudFreeDate);

    debugPrint(
        'Firestore sync done: ${mergedGodFavs.length} gods, ${mergedPcFavs.length} pc');
  } catch (e) {
    // Silently fail — local data is still valid.
    debugPrint('Firestore sync failed: $e');
  }
}

/// Helper to read local read god IDs from SharedPreferences.
Future<Set<String>> _loadLocalReadGods() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList('read_god_ids') ?? const []).toSet();
}

Future<void> _saveLocalReadGods(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('read_god_ids', ids.toList());
}

Future<Set<String>> _loadLocalReadStories() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList('read_story_ids') ?? const []).toSet();
}

Future<void> _saveLocalReadStories(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('read_story_ids', ids.toList());
}

/// Merge cloud settings into local. Cloud wins if value exists.
Future<void> _mergeCloudSettings(Map<String, dynamic> cs) async {
  final prefs = await SharedPreferences.getInstance();
  if (cs.containsKey('dailyReminders')) {
    await prefs.setBool('setting_daily_reminders', cs['dailyReminders'] as bool);
  }
  if (cs.containsKey('soundEffects')) {
    await prefs.setBool('setting_sound_effects', cs['soundEffects'] as bool);
  }
  if (cs.containsKey('haptics')) {
    await prefs.setBool('setting_haptics', cs['haptics'] as bool);
  }
}

class MytheraApp extends StatelessWidget {
  const MytheraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SoundService.ensureMusicStarted(),
      child: MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Mythera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFF5F5F5),
          primary: Color(0xFFB07800),
          secondary: Color(0xFF7B1FA2),
          onSurface: Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: OnboardingService.isComplete
          ? const SplashWelcomeScreen()
          : const OnboardingScreen(),
      ),
    );
  }
}
