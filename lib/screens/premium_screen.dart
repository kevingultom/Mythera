import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../l10n/language_provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/payment_service.dart';
import '../services/premium_service.dart';
import '../services/sound_service.dart';
import '../utils/app_fonts.dart';

const _gold = Color(0xFFB07800);
const _goldBright = Color(0xFFE0A82E);
const _bgTop = Color(0xFF1A140A);
const _bgBottom = Color(0xFF060606);

enum _Step { idle, signingIn, methodSelect, checkingOut, awaitingPayment, error }

/// Premium checkout screen. Reached from the locked-content bottom sheet
/// (widgets/premium_lock_sheet.dart) and from the Codex tab's support
/// banner. Requires Google Sign-In before purchase — an anonymous UID
/// resets on reinstall, so an anonymous purchase would be unrecoverable.
///
/// Payment is fully automatic: the user picks QRIS or a BNI Virtual
/// Account, the backend (backend/api/create-transaction.ts) creates a
/// Midtrans transaction, and once Midtrans notifies the backend's webhook
/// the user's Firestore doc flips `premium: true` on its own —
/// PremiumService.watch() is already listening, so this screen just waits
/// for isPremium to become true; no manual verification step exists.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  _Step _step = _Step.idle;
  String? _errorMessage;
  CheckoutResult? _checkout;

  Future<void> _handleSignIn(String lang) async {
    setState(() => _step = _Step.signingIn);
    try {
      await FirebaseAuthService.instance.signInWithGoogle();
      if (mounted) setState(() => _step = _Step.idle);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.error;
          _errorMessage = FirebaseAuthService.friendlyErrorMessage(e, lang);
        });
      }
    }
  }

  void _handlePurchase(String lang) {
    SoundService.playClick();
    setState(() => _step = _Step.methodSelect);
  }

  Future<void> _startCheckout(String lang, PaymentMethod method) async {
    SoundService.playClick();
    setState(() => _step = _Step.checkingOut);
    try {
      final result = await PaymentService.startCheckout(method);
      if (!mounted) return;
      setState(() {
        _checkout = result;
        _step = _Step.awaitingPayment;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.error;
        _errorMessage = localize(
          lang,
          'Tidak bisa membuat transaksi pembayaran. Coba lagi sebentar lagi.',
          'Couldn\'t start the payment transaction. Please try again shortly.',
        );
      });
    }
  }

  Future<void> _copyToClipboard(String value, String label) async {
    SoundService.playClick();
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label disalin'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;
    return Scaffold(
      backgroundColor: _bgBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<bool>(
            valueListenable: PremiumService.premiumNotifier,
            builder: (context, isPremium, _) {
              return StreamBuilder(
                stream: FirebaseAuthService.instance.authStateChanges,
                builder: (context, _) => _buildBody(lang, isPremium),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String lang, bool isPremium) {
    final inCheckoutFlow = !isPremium &&
        (_step == _Step.methodSelect ||
            _step == _Step.checkingOut ||
            _step == _Step.awaitingPayment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
          child: GestureDetector(
            // While mid-checkout, back returns to the pitch view first
            // instead of leaving the screen outright.
            onTap: () => inCheckoutFlow
                ? setState(() {
                    _step = _Step.idle;
                    _checkout = null;
                  })
                : Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    localize(lang, 'Kembali', 'Back'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: (isPremium || _step == _Step.checkingOut)
              // Owned state and the checking-out spinner are both short —
              // center them in the available space rather than pinning to
              // the top like the longer scrollable views below.
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: isPremium
                        ? _premiumOwnedView(lang)
                        : _checkingOutView(lang),
                  ),
                )
              // Every other view is potentially long — keep it scrollable,
              // top-aligned.
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: switch (_step) {
                    _Step.methodSelect => _methodSelectView(lang),
                    _Step.awaitingPayment => _awaitingPaymentView(lang),
                    _ => _pitchView(lang),
                  },
                ),
        ),
      ],
    );
  }

  Widget _pitchView(String lang) {
    final isAnon = FirebaseAuthService.instance.isAnonymous;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        _glowIcon(Icons.diamond_rounded, size: 78, iconSize: 36),
        const SizedBox(height: 24),
        Text(
          localize(lang, 'Buka Semua Kisah', 'Unlock All Stories'),
          textAlign: TextAlign.center,
          style: AppFonts.cinzel(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          localize(
            lang,
            'Sekali bayar, terbuka selamanya, tersinkron ke akun Google-mu.',
            'Pay once, unlocked forever, synced to your Google account.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 22),
        _priceBadge(lang),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            localize(lang, 'YANG KAMU DAPAT', "WHAT YOU'LL GET"),
            style: const TextStyle(
              color: _goldBright,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _benefit(Icons.menu_book_rounded,
            localize(lang, 'Semua legenda dewa', 'Every god\'s legend'),
            localize(lang, '326 dewa dari 6 mitologi dunia', '326 gods across 6 world mythologies')),
        const SizedBox(height: 10),
        _benefit(Icons.auto_stories_rounded,
            localize(lang, '58 kisah sejarah mitologi', '58 mythology history stories'),
            localize(lang, 'Perang, penciptaan, dan legenda besar', 'Wars, creation myths, and great legends')),
        const SizedBox(height: 10),
        _benefit(Icons.sync_rounded,
            localize(lang, 'Sinkron di semua perangkat', 'Synced across all your devices'),
            localize(lang, 'Ganti HP? Semua tetap terbuka', 'New phone? Everything stays unlocked')),
        const SizedBox(height: 28),
        if (_step == _Step.error && _errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _primaryButton(lang, isAnon),
      ],
    );
  }

  Widget _methodSelectView(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        _glowIcon(Icons.payments_rounded, size: 68, iconSize: 32),
        const SizedBox(height: 20),
        Text(
          localize(lang, 'Pilih Metode Pembayaran', 'Choose a Payment Method'),
          textAlign: TextAlign.center,
          style: AppFonts.cinzel(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          localize(
            lang,
            'Bayar Rp 18.000, langsung aktif otomatis setelah pembayaran berhasil.',
            'Pay Rp 18,000 — Premium unlocks automatically the moment payment succeeds.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 28),
        _methodOption(
          icon: Icons.qr_code_2_rounded,
          title: 'QRIS',
          subtitle: localize(lang, 'Scan dari aplikasi bank atau e-wallet apa pun',
              'Scan from any bank or e-wallet app'),
          onTap: () => _startCheckout(lang, PaymentMethod.qris),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            localize(lang, 'TRANSFER VIRTUAL ACCOUNT', 'VIRTUAL ACCOUNT TRANSFER'),
            style: const TextStyle(
              color: _goldBright,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _bankVaOption(lang, 'BCA', PaymentMethod.bcaVa),
        const SizedBox(height: 10),
        _bankVaOption(lang, 'BNI', PaymentMethod.bniVa),
        const SizedBox(height: 10),
        _bankVaOption(lang, 'BRI', PaymentMethod.briVa),
        const SizedBox(height: 10),
        _bankVaOption(lang, 'Permata', PaymentMethod.permataVa),
        const SizedBox(height: 10),
        _bankVaOption(lang, 'Mandiri', PaymentMethod.mandiriVa),
      ],
    );
  }

  Widget _bankVaOption(String lang, String bankName, PaymentMethod method) {
    return _methodOption(
      icon: Icons.account_balance_rounded,
      title: localize(lang, 'Virtual Account $bankName', '$bankName Virtual Account'),
      subtitle: localize(lang, 'Transfer ke nomor VA unik lewat m-banking $bankName',
          'Transfer to a unique VA number via $bankName mobile banking'),
      onTap: () => _startCheckout(lang, method),
    );
  }

  Widget _methodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _goldBright.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _goldBright, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF999999), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _checkingOutView(String lang) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _goldBright),
          const SizedBox(height: 18),
          Text(
            localize(lang, 'Menyiapkan pembayaran...', 'Preparing your payment...'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
          ),
        ],
      ),
    );
  }

  static const Map<PaymentMethod, String> _bankNames = {
    PaymentMethod.bcaVa: 'BCA',
    PaymentMethod.bniVa: 'BNI',
    PaymentMethod.briVa: 'BRI',
    PaymentMethod.permataVa: 'Permata',
    PaymentMethod.mandiriVa: 'Mandiri',
  };

  Widget _awaitingPaymentView(String lang) {
    final checkout = _checkout!;
    final bankName = _bankNames[checkout.method];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        if (checkout.method == PaymentMethod.qris && checkout.qrImageUrl != null)
          _qrCodeFromUrl(checkout.qrImageUrl!)
        else
          _glowIcon(Icons.account_balance_rounded, size: 68, iconSize: 32),
        const SizedBox(height: 20),
        Text(
          checkout.method == PaymentMethod.qris
              ? localize(lang, 'Scan untuk Membayar', 'Scan to Pay')
              : localize(lang, 'Transfer ke Virtual Account $bankName',
                  'Transfer to $bankName Virtual Account'),
          textAlign: TextAlign.center,
          style: AppFonts.cinzel(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          localize(
            lang,
            'Bayar Rp 18.000 dengan jumlah yang sudah otomatis terisi.',
            'Pay the pre-filled amount of Rp 18,000.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (checkout.method == PaymentMethod.mandiriVa &&
            checkout.billKey != null &&
            checkout.billerCode != null) ...[
          _paymentDestination(
            label: localize(lang, 'Kode Perusahaan (Biller Code)', 'Biller Code'),
            value: checkout.billerCode!,
            onCopy: () => _copyToClipboard(
                checkout.billerCode!, localize(lang, 'Kode Perusahaan', 'Biller code')),
          ),
          const SizedBox(height: 10),
          _paymentDestination(
            label: localize(lang, 'Kode Pembayaran (Bill Key)', 'Bill Key'),
            value: checkout.billKey!,
            onCopy: () => _copyToClipboard(
                checkout.billKey!, localize(lang, 'Kode Pembayaran', 'Bill key')),
          ),
        ] else if (bankName != null && checkout.vaNumber != null)
          _paymentDestination(
            label: localize(lang, 'Nomor Virtual Account $bankName', '$bankName Virtual Account Number'),
            value: checkout.vaNumber!,
            onCopy: () => _copyToClipboard(checkout.vaNumber!,
                localize(lang, 'Nomor Virtual Account', 'Virtual Account number')),
          ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _goldBright),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localize(
                    lang,
                    'Menunggu pembayaran... Halaman ini akan otomatis berubah begitu pembayaranmu terverifikasi, tanpa perlu tindakan lain.',
                    'Waiting for payment... This screen updates automatically once your payment is verified — no further action needed.',
                  ),
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentDestination({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldBright.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF999999), fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.copy_rounded, color: _goldBright, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCodeFromUrl(String url) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _goldBright.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 220,
              height: 220,
              child: Center(child: CircularProgressIndicator(color: _goldBright)),
            );
          },
          errorBuilder: (_, __, ___) =>
              _glowIcon(Icons.qr_code_2_rounded, size: 68, iconSize: 32),
        ),
      ),
    );
  }

  Widget _glowIcon(IconData icon, {required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_gold.withValues(alpha: 0.35), _gold.withValues(alpha: 0.0)],
        ),
        boxShadow: [
          BoxShadow(
            color: _goldBright.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.62,
        height: size * 0.62,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_goldBright, _gold],
          ),
        ),
        child: Icon(icon, color: Colors.black, size: iconSize),
      ),
    );
  }

  Widget _priceBadge(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _goldBright.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rp 18.000',
            style: AppFonts.cinzel(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            localize(lang, 'sekali bayar', 'one-time'),
            style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _premiumOwnedView(String lang) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF66BB6A).withValues(alpha: 0.28),
                const Color(0xFF66BB6A).withValues(alpha: 0.0),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF66BB6A), size: 58),
        ),
        const SizedBox(height: 22),
        Text(
          localize(lang, 'Semua Kisah Sudah Terbuka', 'Everything Is Already Unlocked'),
          textAlign: TextAlign.center,
          style: AppFonts.cinzel(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          localize(
            lang,
            'Terima kasih telah mendukung pengembangan Mythera!',
            'Thanks for supporting Mythera\'s development!',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13.5, height: 1.5),
        ),
      ],
    );
  }

  Widget _benefit(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _goldBright, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF999999), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String lang, bool isAnon) {
    final busy = _step == _Step.signingIn;
    final label = isAnon
        ? localize(lang, 'Masuk dengan Google untuk Melanjutkan', 'Sign in with Google to Continue')
        : localize(lang, 'Bayar Sekarang', 'Pay Now');

    return GestureDetector(
      onTap: busy
          ? null
          : () => isAnon ? _handleSignIn(lang) : _handlePurchase(lang),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_gold, _goldBright]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _goldBright.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isAnon) ...[
                      const Icon(Icons.lock_open_rounded, color: Colors.black, size: 17),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
