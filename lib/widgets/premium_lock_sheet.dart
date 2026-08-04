import 'package:flutter/material.dart';
import '../l10n/language_provider.dart';
import '../screens/premium_screen.dart';
import '../services/sound_service.dart';

const _gold = Color(0xFFB07800);
const _goldBright = Color(0xFFE0A82E);

/// Bottom sheet shown when the user taps a locked story/legend card.
/// Shared by god_detail_screen.dart and genre_stories_screen.dart so the
/// paywall pitch lives in exactly one place.
Future<void> showPremiumLockSheet(BuildContext context) {
  SoundService.playClick();
  final lang = LanguageProvider.of(context).value;

  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: _goldBright, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              localize(lang, 'Konten Premium', 'Premium Content'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localize(
                lang,
                'Buka semua legenda dewa dan kisah mitologi selamanya, sekali bayar.',
                'Unlock every god\'s legend and every mythology story forever, with one payment.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  SoundService.playClick();
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const PremiumScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldBright]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    localize(lang, 'Buka Semua Kisah, Rp 18.000', 'Unlock All Stories, Rp 18,000'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(sheetContext),
              child: Text(
                localize(lang, 'Nanti saja', 'Maybe later'),
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    },
  );
}
