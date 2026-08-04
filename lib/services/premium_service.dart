import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'onboarding_service.dart';

/// Tracks whether the user has purchased the one-time premium unlock.
///
/// Source of truth is the `premium` field on the user's Firestore doc
/// (flipped server-side by the payment webhook — the client can never set
/// it itself, see firestore.rules). A local cache mirrors the last known
/// value for an instant first-frame paint, refreshed live by [watch] once
/// signed in.
class PremiumService {
  static const _key = 'premium_unlocked';

  static bool _isPremium = false;

  /// Single app-wide notifier so widgets deep in the tree (story cards) can
  /// react live without each opening their own Firestore subscription.
  static final ValueNotifier<bool> premiumNotifier = ValueNotifier(false);

  /// Bumped whenever gating changes WITHOUT the premium bool changing — e.g.
  /// a daily free-god unlock. [premiumNotifier] wouldn't re-fire in that case
  /// (its value is unchanged), so lock-badge widgets also listen to this.
  static final ValueNotifier<int> gatingRevision = ValueNotifier(0);
  static void bumpGatingRevision() => gatingRevision.value++;

  /// Injected by DailyFreeService.init() so isGodStoryLocked can consult the
  /// free-unlocked set without PremiumService importing that service (which
  /// would create a cycle — DailyFreeService pokes this class's notifiers).
  /// Defaults to a no-op so nothing breaks before that init runs.
  static bool Function(String godId) freeUnlockCheck = (_) => false;

  /// Load the cached value for a fast first frame. Call once at startup.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_key) ?? false;
    premiumNotifier.value = _isPremium;
  }

  static bool get isPremium => _isPremium;

  /// A god's legend is free when premium, when it's the patron god chosen at
  /// onboarding, or when it's been unlocked via the daily free-god roll.
  static bool isGodStoryLocked(String godId) =>
      !_isPremium &&
      godId != OnboardingService.patronGodId &&
      !freeUnlockCheck(godId);

  /// All mythology Stories-tab entries are locked when not premium, with
  /// no exceptions (even ones mentioning the patron god).
  static bool isMythStoryLocked() => !_isPremium;

  /// Live Firestore listener on the signed-in user's premium flag. Starts
  /// once from main.dart and keeps [isPremium]/[premiumNotifier] in sync
  /// for the rest of the app's lifetime.
  static Stream<bool> watch() {
    final uid = FirebaseAuthService.instance.uid;
    if (uid == null || FirebaseAuthService.instance.isAnonymous) {
      return Stream.value(_isPremium);
    }
    return FirestoreService.instance.watchPremiumStatus(uid).map((premium) {
      _setPremium(premium);
      return premium;
    });
  }

  static Future<void> _setPremium(bool value) async {
    if (_isPremium == value) return;
    _isPremium = value;
    premiumNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  /// Debug-only local override so the unlock flow can be tested before the
  /// real Midtrans/Cloud Functions backend exists. Never reachable outside
  /// a debug build.
  static Future<void> debugSetPremium(bool value) async {
    if (!kDebugMode) return;
    await _setPremium(value);
  }
}
