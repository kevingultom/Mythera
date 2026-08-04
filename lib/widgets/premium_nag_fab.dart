import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/language_provider.dart';
import '../services/premium_service.dart';
import '../services/sound_service.dart';
import '../screens/premium_screen.dart';

const _gold = Color(0xFFB07800);
const _goldBright = Color(0xFFE0A82E);

/// Small, persistent floating button reminding non-premium users that
/// Premium exists — present on every tab (mounted once in MainShell, above
/// the bottom nav) rather than only on screens the user has to seek out.
/// Disappears entirely once premium is active; there is nothing left to
/// advertise at that point.
///
/// Dismissible: closing the nag card via its "x" hides both the card and
/// this button for the rest of the day (day boundary anchored at 9 AM, same
/// as DailyFreeService's daily free-god unlock, so both resurface together).
class PremiumNagFab extends StatefulWidget {
  const PremiumNagFab({super.key});

  @override
  State<PremiumNagFab> createState() => _PremiumNagFabState();
}

class _PremiumNagFabState extends State<PremiumNagFab> {
  static const _dismissedDateKey = 'premium_nag_dismissed_date';

  bool _dismissedToday = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  static String _todayKey() {
    final now = DateTime.now();
    final anchor = now.hour < 9 ? now.subtract(const Duration(days: 1)) : now;
    return '${anchor.year.toString().padLeft(4, '0')}-'
        '${anchor.month.toString().padLeft(2, '0')}-'
        '${anchor.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDate = prefs.getString(_dismissedDateKey) ?? '';
    if (mounted) {
      setState(() => _dismissedToday = dismissedDate == _todayKey());
    }
  }

  Future<void> _dismissForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedDateKey, _todayKey());
    if (mounted) setState(() => _dismissedToday = true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.premiumNotifier,
      builder: (context, isPremium, _) {
        if (isPremium || _dismissedToday) return const SizedBox.shrink();
        return _NagButton(onTap: () => _showNagCard(context));
      },
    );
  }

  void _showNagCard(BuildContext context) {
    SoundService.playClick();
    showGeneralDialog(
      context: context,
      barrierLabel: 'Premium',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _NagCard(onDismiss: _dismissForToday),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _NagButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NagButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _goldBright.withValues(alpha: 0.75),
              _gold.withValues(alpha: 0.75),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _goldBright.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.diamond_rounded,
            color: Colors.black.withValues(alpha: 0.8), size: 16),
      ),
    );
  }
}

/// The floating mini-card shown when the nag button is tapped. Reuses the
/// same three benefits pitched on the full Premium screen, condensed, plus
/// a CTA that opens that screen for the actual purchase flow.
class _NagCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _NagCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            // Swallow taps on the card itself so they don't fall through
            // to the barrier-dismiss GestureDetector behind it.
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: const Color(0xFF141210),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _goldBright.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.diamond_rounded,
                            color: _goldBright, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localize(lang, 'Buka Semua Kisah', 'Unlock All Stories'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          onDismiss();
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF888888), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _benefit(Icons.menu_book_rounded,
                      localize(lang, 'Semua legenda dewa', 'Every god\'s legend')),
                  const SizedBox(height: 9),
                  _benefit(Icons.auto_stories_rounded,
                      localize(lang, '58 kisah sejarah mitologi', '58 mythology history stories')),
                  const SizedBox(height: 9),
                  _benefit(Icons.sync_rounded,
                      localize(lang, 'Sinkron di semua perangkat', 'Synced across all your devices')),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const PremiumScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 280),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_gold, _goldBright]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          localize(lang, 'Lihat Premium', 'View Premium'),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: _goldBright, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFCFCFCF), fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
