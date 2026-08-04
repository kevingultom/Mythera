import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/god_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'onboarding_service.dart';
import 'premium_service.dart';

/// Daily free-god unlock: once per day (day boundary anchored at 9 AM, to
/// match the daily notification), the user can roll a random god from the
/// locked pool and unlock its legend for free, permanently. Only affects
/// individual god legends — never the Stories tab.
///
/// Mirrors ReadingService's static-cache + SharedPreferences pattern, and
/// its fire-and-forget Firestore sync so collected gods survive reinstall.
class DailyFreeService {
  static const _unlockedKey = 'free_unlocked_god_ids';
  static const _lastClaimKey = 'free_last_claim_date';

  static Set<String> _freeUnlocked = {};
  static String _lastClaimDate = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _freeUnlocked = (prefs.getStringList(_unlockedKey) ?? const []).toSet();
    _lastClaimDate = prefs.getString(_lastClaimKey) ?? '';
    // Wire the gating hook so PremiumService.isGodStoryLocked consults the
    // free set without importing this service (avoids an import cycle).
    PremiumService.freeUnlockCheck = (id) => _freeUnlocked.contains(id);
  }

  /// The current "day", anchored at 9 AM: before 9 AM counts as the previous
  /// day, so a claim at 10 PM and a check at 8 AM next morning are the same
  /// day, but 9:01 AM rolls over to a fresh claim.
  static String _todayKey() {
    final now = DateTime.now();
    final anchor = now.hour < 9 ? now.subtract(const Duration(days: 1)) : now;
    return '${anchor.year.toString().padLeft(4, '0')}-'
        '${anchor.month.toString().padLeft(2, '0')}-'
        '${anchor.day.toString().padLeft(2, '0')}';
  }

  static bool isFreeUnlocked(String id) => _freeUnlocked.contains(id);

  static bool canClaimFreeToday() => _lastClaimDate != _todayKey();

  // A god is claimable only while locked: not premium-open, not the patron,
  // not already free-unlocked.
  static bool _isLocked(God g) =>
      !PremiumService.isPremium &&
      g.id != OnboardingService.patronGodId &&
      !_freeUnlocked.contains(g.id);

  static List<God> lockedPool(List<God> allGods) =>
      allGods.where(_isLocked).toList();

  static bool hasLockedGodsRemaining(List<God> allGods) =>
      allGods.any(_isLocked);

  /// Records a free unlock: persists locally, stamps today's claim, refreshes
  /// lock badges live, and syncs to the cloud. Call after the reveal dialog
  /// returns the chosen god.
  static Future<void> claim(God god) async {
    final prefs = await SharedPreferences.getInstance();
    _freeUnlocked.add(god.id);
    _lastClaimDate = _todayKey();
    await prefs.setStringList(_unlockedKey, _freeUnlocked.toList());
    await prefs.setString(_lastClaimKey, _lastClaimDate);
    PremiumService.bumpGatingRevision();
    _syncToCloud();
  }

  /// Fire-and-forget push to Firestore (mirrors ReadingService._syncToCloud).
  static void _syncToCloud() {
    final uid = FirebaseAuthService.instance.uid;
    if (uid == null || FirebaseAuthService.instance.isAnonymous) return;
    FirestoreService.instance
        .saveFreeUnlockedGods(uid, _freeUnlocked, _lastClaimDate)
        .catchError((e) => debugPrint('DailyFreeService cloud sync failed: $e'));
  }

  /// Merge cloud state into local on startup: union the unlocked sets, and
  /// keep the later claim date so a reinstall can't reset the daily limit and
  /// claim twice on the same day.
  static Future<void> mergeFromCloud(Set<String> ids, String cloudDate) async {
    _freeUnlocked.addAll(ids);
    // yyyy-MM-dd sorts lexicographically the same as chronologically.
    if (cloudDate.compareTo(_lastClaimDate) > 0) _lastClaimDate = cloudDate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, _freeUnlocked.toList());
    await prefs.setString(_lastClaimKey, _lastClaimDate);
    PremiumService.bumpGatingRevision();
  }

  /// Debug-only: clear today's claim so testers don't have to wait for 9 AM.
  static Future<void> debugResetDailyClaim() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    _lastClaimDate = '';
    await prefs.remove(_lastClaimKey);
  }
}
