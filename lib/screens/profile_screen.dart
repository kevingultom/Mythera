import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/language_provider.dart';
import '../services/onboarding_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import 'about_screen.dart';
import 'onboarding_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  static const _cardBg = Color(0xFF111111);
  static const _cardBorder = Color(0xFF1E1E1E);
  static const _gold = Color(0xFFB07800);

  bool _dailyReminders = false;
  bool _soundEffects = true;
  bool _haptics = true;

  final _scrollCtrl = ScrollController();

  void scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final reminders = await SettingsService.getDailyReminders();
    if (!mounted) return;
    setState(() {
      _dailyReminders = reminders;
      _soundEffects = SoundService.soundEnabled;
      _haptics = SoundService.hapticsEnabled;
    });
  }

  /// Called by MainShell whenever this tab becomes visible again.
  void refresh() {
    if (mounted) _loadSettings();
  }

  /// Confirms, then clears the saved onboarding state and replays the
  /// 7-page intro from the root navigator — same landing point a
  /// first-time install reaches, so the patron-god pick and reminder
  /// choice all run fresh.
  Future<void> _replayIntro(String lang) async {
    SoundService.playClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localize(lang, 'Ulangi Intro?', 'Replay Intro?'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          localize(
            lang,
            'Kamu akan memilih ulang dewa pujaan dan preferensi lainnya dari awal.',
            'You\'ll pick your patron god and other preferences again from scratch.',
          ),
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localize(lang, 'Batal', 'Cancel'),
                style: const TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(localize(lang, 'Ulangi', 'Replay'),
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await OnboardingService.reset();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Text(
              localize(lang, 'Profil', 'Profile'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // Account card
            _buildAccountCard(lang),

            const SizedBox(height: 20),

            _sectionLabel(localize(lang, 'PENGATURAN', 'PREFERENCES')),
            const SizedBox(height: 10),

            // Preferences card
            _card(
              children: [
                _toggleRow(
                  title: localize(lang, 'Pengingat Harian', 'Daily Reminders'),
                  subtitle: localize(lang,
                      'Temukan dewa dan mitologi baru setiap hari.',
                      'Discover a new god and mythology every day.'),
                  value: _dailyReminders,
                  onChanged: (v) async {
                    setState(() => _dailyReminders = v);
                    await SettingsService.setDailyReminders(v);
                    if (v) {
                      await NotificationService.instance.scheduleDailyReminder();
                    } else {
                      await NotificationService.instance.cancelDailyReminder();
                    }
                  },
                ),
                _divider(),
                _toggleRow(
                  title: localize(lang, 'Efek Suara', 'Sound Effects'),
                  subtitle: localize(lang,
                      'Mainkan suara saat menekan tombol dan interaksi.',
                      'Play sounds on button taps and interactions.'),
                  value: _soundEffects,
                  onChanged: (v) async {
                    setState(() => _soundEffects = v);
                    await SoundService.setSoundEnabled(v);
                  },
                ),
                _divider(),
                _toggleRow(
                  title: localize(lang, 'Getaran', 'Haptics'),
                  subtitle: localize(lang,
                      'Umpan balik getaran saat menekan dan berinteraksi.',
                      'Vibration feedback on taps and interactions.'),
                  value: _haptics,
                  onChanged: (v) async {
                    setState(() => _haptics = v);
                    await SoundService.setHapticsEnabled(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionLabel(localize(lang, 'INFORMASI', 'INFORMATION')),
            const SizedBox(height: 10),

            // Information card
            _card(
              children: [
                _infoRow(
                  label: localize(lang, 'Tentang', 'About'),
                  onTap: () => _openPage(const AboutScreen()),
                ),
                _divider(),
                _infoRow(
                  label: localize(lang, 'Ketentuan Layanan', 'Terms of Service'),
                  onTap: () => _openPage(const TermsOfServiceScreen()),
                ),
                _divider(),
                _infoRow(
                  label: localize(lang, 'Kebijakan Privasi', 'Privacy Policy'),
                  onTap: () => _openPage(const PrivacyPolicyScreen()),
                ),
                _divider(),
                _infoRow(
                  label: localize(lang, 'Bantuan', 'Help'),
                  onTap: () => _openPage(const HelpScreen()),
                ),
                _divider(),
                _infoRow(
                  label: localize(lang, 'Ulangi Intro', 'Replay Intro'),
                  onTap: () => _replayIntro(lang),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // App info footer
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore Every God, Every Legend, Every Realm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(String lang) {
    final auth = FirebaseAuthService.instance;
    final user = auth.currentUser;
    final isAnon = auth.isAnonymous;
    final rawName = user?.displayName;
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (isAnon
            ? localize(lang, 'Pengguna Anonim', 'Anonymous User')
            : (user?.email ?? localize(lang, 'Akun Google', 'Google Account')));
    final photoUrl = user?.photoURL;

    Future<void> _handleAuthTap() async {
      if (isAnon) {
        try {
          final result = await auth.signInWithGoogle();
          if (mounted) {
            setState(() {});
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localize(
                      lang, 'Berhasil login!', 'Signed in successfully!')),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            }
          }
        } catch (e, st) {
          // ignore: avoid_print
          print('Google sign-in failed: $e\n$st');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    FirebaseAuthService.friendlyErrorMessage(e, lang)),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
        }
      } else {
        try {
          await auth.signOutGoogle();
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(localize(lang, 'Telah logout', 'Signed out')),
              ),
            );
          }
        } catch (e, st) {
          // ignore: avoid_print
          print('Sign-out failed: $e\n$st');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    FirebaseAuthService.friendlyErrorMessage(e, lang)),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111111),
            isAnon ? const Color(0xFF151515) : const Color(0xFF141210),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAnon
              ? _cardBorder
              : _gold.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar with ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAnon
                      ? Colors.white.withValues(alpha: 0.12)
                      : _gold,
                  width: 1.6,
                ),
                gradient: isAnon
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _gold,
                          _gold.withValues(alpha: 0.5),
                        ],
                      ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Icon(
                        isAnon
                            ? Icons.person_outline_rounded
                            : Icons.person_rounded,
                        color: isAnon
                            ? const Color(0xFF666666)
                            : _gold.withValues(alpha: 0.7),
                        size: 21,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAnon
                              ? const Color(0xFF666666)
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isAnon
                              ? localize(lang, 'Belum login', 'Not signed in')
                              : localize(
                                  lang, 'Tersync ke cloud', 'Synced to cloud'),
                          style: TextStyle(
                            color: isAnon
                                ? const Color(0xFF777777)
                                : const Color(0xFF4CAF50),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Auth button — compact icon-only for a signed-in user, a
            // small pill for the sign-in call-to-action (needs a label
            // since it's the primary action on this screen).
            GestureDetector(
              onTap: _handleAuthTap,
              child: isAnon
                  ? Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_gold, _gold.withValues(alpha: 0.75)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login_rounded,
                              color: Colors.black, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            localize(lang, 'Masuk', 'Sign in'),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Color(0xFF999999), size: 17),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8A8A8A),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: _cardBorder);
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _gold,
            inactiveTrackColor: const Color(0xFF3A3A3C),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF6B6B6B), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
