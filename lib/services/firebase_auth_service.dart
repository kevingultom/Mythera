import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/language_provider.dart';

/// Manages Firebase Authentication.
///
/// Strategy:
/// - On first launch the user is silently signed in as **anonymous** so
///   every piece of data (favorites, reading progress …) is already backed
///   up to Firestore without friction.
/// - The user can later upgrade to a **Google account**. When they do,
///   the anonymous UID's data is merged into the Google UID so nothing
///   is lost.
class FirebaseAuthService {
  FirebaseAuthService._();
  static final instance = FirebaseAuthService._();

  // Accessed lazily and defensively: on platforms where Firebase wasn't
  // initialized (e.g. web without config), FirebaseAuth.instance throws.
  // We return null there so the rest of the app keeps working — auth just
  // becomes a no-op instead of crashing every screen that reads `uid`.
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // Lazy + nullable, same reason as _auth: constructing GoogleSignIn() on
  // web throws immediately if the OAuth client ID meta tag isn't set up
  // (see web/index.html), and this class is instantiated the moment any
  // screen reads FirebaseAuthService.instance — including screens that
  // build eagerly at startup (e.g. ProfileScreen, kept alive by MainShell's
  // IndexedStack) well before the user ever taps "Sign in".
  GoogleSignIn? get _google {
    try {
      return GoogleSignIn();
    } catch (_) {
      return null;
    }
  }

  // ── Current user ──────────────────────────────────────────────
  User? get currentUser => _auth?.currentUser;
  String? get uid => _auth?.currentUser?.uid;
  bool get isSignedIn => _auth?.currentUser != null;
  bool get isAnonymous => _auth?.currentUser?.isAnonymous ?? true;

  /// Stream that emits whenever the auth state changes. Empty stream when
  /// Firebase is unavailable.
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  // ── Anonymous sign-in ─────────────────────────────────────────
  /// Signs in anonymously if no user is currently signed in.
  /// Returns the [UserCredential].
  Future<UserCredential?> ensureAnonymous() async {
    final auth = _auth;
    if (auth == null) return null;
    // Already signed in — reuse existing session.
    if (auth.currentUser != null) return null;
    return auth.signInAnonymously();
  }

  // ── Google sign-in ────────────────────────────────────────────
  /// Triggers the Google Sign-In flow and links the credential to the
  /// current anonymous account so the UID (and its Firestore data) is
  /// preserved.
  ///
  /// Returns the [User] on success, or `null` if the user cancelled.
  Future<User?> signInWithGoogle() async {
    final auth = _auth;
    final google = _google;
    if (auth == null || google == null) return null; // Unavailable (e.g. web preview).

    // 1. Trigger the Google Sign-In flow.
    final googleUser = await google.signIn();
    if (googleUser == null) return null;

    // 2. Obtain the auth credential.
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Link or sign in.
    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      // Upgrade the anonymous account → data stays on same UID.
      try {
        await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked' ||
            e.code == 'credential-already-in-use') {
          // Already linked to another account — sign in to that account
          // instead (the anonymous session's data can't be merged in).
          return (await auth.signInWithCredential(credential)).user;
        }
        rethrow;
      }
      return auth.currentUser;
    }

    // Fresh sign-in (no anonymous session).
    final result = await auth.signInWithCredential(credential);
    return result.user;
  }

  // ── Sign out ──────────────────────────────────────────────────
  /// Signs out of the Google provider and Firebase, then immediately
  /// starts a fresh anonymous session so the uid stays valid for
  /// Firestore writes.
  Future<void> signOutGoogle() async {
    await _google?.signOut();
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
    await auth.signInAnonymously();
  }

  // ── Delete account ────────────────────────────────────────────
  Future<void> deleteAccount() async {
    await _auth?.currentUser?.delete();
  }

  // ── Friendly error messages ────────────────────────────────────
  /// Turns a sign-in failure into a short, localized message suitable for
  /// showing directly to the user (instead of the raw exception dump).
  static String friendlyErrorMessage(Object error, String lang) {
    if (error is PlatformException) {
      switch (error.code) {
        case 'network_error':
          return localize(
            lang,
            'Gagal login: koneksi internet bermasalah. Periksa jaringanmu lalu coba lagi.',
            'Sign-in failed: a network problem occurred. Check your connection and try again.',
          );
        case 'sign_in_canceled':
        case 'sign_in_failed':
          return localize(
            lang,
            'Login Google gagal. Pastikan Google Play Services aktif lalu coba lagi.',
            'Google sign-in failed. Make sure Google Play Services is up to date and try again.',
          );
      }
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return localize(
            lang,
            'Gagal login: koneksi internet bermasalah. Periksa jaringanmu lalu coba lagi.',
            'Sign-in failed: a network problem occurred. Check your connection and try again.',
          );
        case 'user-disabled':
          return localize(
            lang,
            'Akun ini telah dinonaktifkan.',
            'This account has been disabled.',
          );
        case 'too-many-requests':
          return localize(
            lang,
            'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
            'Too many attempts. Please try again in a moment.',
          );
      }
    }
    return localize(
      lang,
      'Login gagal. Coba lagi.',
      'Sign-in failed. Please try again.',
    );
  }
}
