import 'package:flutter/material.dart';
import '../l10n/language_provider.dart';
import '../widgets/static_page_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;

    return StaticPageScaffold(
      title: localize(lang, 'Ketentuan Layanan', 'Terms of Service'),
      children: [
        StaticPageHeading(localize(lang, 'Tujuan Aplikasi', 'Purpose of the App')),
        StaticPageParagraph(
          localize(lang,
              'Mythera dibuat semata-mata untuk tujuan hiburan dan edukasi seputar mitologi dunia. Seluruh konten, termasuk fitur "Adu Dewa", tidak dimaksudkan untuk menyinggung, menyalahgunakan, atau merendahkan kepercayaan maupun tradisi budaya mana pun.',
              'Mythera is built solely for entertainment and educational purposes about world mythology. All content, including the "God Battle" feature, is not intended to offend, misuse, or belittle any belief system or cultural tradition.'),
        ),
        StaticPageHeading(localize(lang, 'Konten', 'Content')),
        StaticPageParagraph(
          localize(lang,
              'Kisah dan informasi dalam aplikasi ini disusun berdasarkan tradisi mitologi yang telah dikenal luas secara publik, kemudian ditulis ulang dan disederhanakan agar mudah dibaca. Kami berupaya menjaga keakuratan, namun konten dapat berbeda dari satu sumber atau tradisi ke tradisi lainnya.',
              'The stories and information in this app are compiled from widely known public mythological traditions, then rewritten and simplified for readability. We strive for accuracy, but content may vary between sources and traditions.'),
        ),
        StaticPageHeading(localize(lang, 'Penggunaan Aplikasi', 'Use of the App')),
        StaticPageParagraph(
          localize(lang,
              'Aplikasi ini gratis digunakan dan tidak memerlukan akun. Kamu bebas menjelajahi, menyimpan favorit, membaca kisah, dan mengikuti kuis sesuai keinginan.',
              'This app is free to use and does not require an account. You are free to explore, bookmark favorites, read stories, and take quizzes as you like.'),
        ),
        StaticPageHeading(localize(lang, 'Fitur Premium', 'Premium Feature')),
        StaticPageParagraph(
          localize(lang,
              'Sebagian besar legenda dewa dan kisah sejarah mitologi terkunci sampai kamu membeli Premium sekali bayar, atau membukanya satu per satu lewat Kartu Dewa Gratis harian. Pembayaran diproses otomatis lewat mitra pembayaran (Midtrans) menggunakan QRIS atau transfer Virtual Account bank, dan Premium aktif otomatis begitu pembayaran terverifikasi, tanpa perlu konfirmasi manual. Pembayaran Premium bersifat final dan tidak dapat dikembalikan.',
              'Most god legends and mythology history stories are locked until you buy Premium as a one-time payment, or unlock them one at a time through the daily Free God Card. Payment is processed automatically through a payment partner (Midtrans) using QRIS or bank Virtual Account transfer, and Premium activates automatically once payment is verified, with no manual confirmation needed. Premium payments are final and non-refundable.'),
        ),
        StaticPageParagraph(
          localize(lang,
              'Fitur "Adu Dewa" adalah simulasi hiburan berbasis angka kekuatan fiktif dan tidak merepresentasikan pandangan atau penilaian nyata terhadap kekuatan relatif antar dewa dari kepercayaan apa pun.',
              'The "God Battle" feature is an entertainment simulation based on fictional power ratings and does not represent any real judgment about the relative power of deities from any belief system.'),
        ),
        StaticPageHeading(localize(lang, 'Perubahan', 'Changes')),
        StaticPageParagraph(
          localize(lang,
              'Konten dan fitur aplikasi dapat diperbarui, ditambah, atau diubah dari waktu ke waktu tanpa pemberitahuan sebelumnya.',
              'App content and features may be updated, added to, or changed over time without prior notice.'),
        ),
      ],
    );
  }
}
