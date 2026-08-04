import 'package:flutter/material.dart';
import '../l10n/language_provider.dart';
import '../widgets/static_page_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;

    return StaticPageScaffold(
      title: localize(lang, 'Kebijakan Privasi', 'Privacy Policy'),
      children: [
        StaticPageHeading(localize(lang, 'Akun & Masuk', 'Account & Sign-In')),
        StaticPageParagraph(
          localize(lang,
              'Mythera tidak mewajibkan pendaftaran akun. Secara default kamu memakai sesi anonim di perangkatmu. Kamu bisa memilih untuk masuk dengan akun Google agar favorit, progres membaca, dan status premium tersimpan dan tersinkron kalau kamu ganti perangkat.',
              'Mythera doesn\'t require account registration. By default you use an anonymous session on your device. You can choose to sign in with a Google account so your favorites, reading progress, and premium status are saved and synced if you switch devices.'),
        ),
        StaticPageHeading(localize(lang, 'Data yang Disimpan', 'Data We Store')),
        StaticPageParagraph(
          localize(lang,
              'Preferensi seperti bahasa, favorit, dan pengaturan suara atau getaran selalu disimpan secara lokal di perangkatmu. Jika kamu masuk dengan Google, data yang sama juga disimpan di Firebase, layanan cloud milik Google, agar bisa disinkronkan. Ini meliputi favorit, progres dan streak membaca, pengaturan, status premium, dan token notifikasi jika kamu mengaktifkannya.',
              'Preferences like language, favorites, and sound or haptics settings are always stored locally on your device. If you sign in with Google, that same data is also stored on Firebase, Google\'s cloud service, so it can sync. This includes favorites, reading progress and streak, settings, premium status, and a notification token if you enable it.'),
        ),
        StaticPageHeading(localize(lang, 'Pembayaran Premium', 'Premium Payments')),
        StaticPageParagraph(
          localize(lang,
              'Pembayaran Premium diproses otomatis lewat mitra pembayaran pihak ketiga (Midtrans) menggunakan QRIS atau transfer Virtual Account bank. Aplikasi ini tidak pernah memproses atau menyimpan detail kartu, rekening bank, maupun data pembayaran lainnya secara langsung — semua itu ditangani oleh Midtrans sesuai kebijakan privasi mereka sendiri. Begitu pembayaran terverifikasi, sistem kami hanya menerima dan menyimpan status "premium aktif atau tidak" pada akunmu.',
              'Premium payments are processed automatically through a third-party payment partner (Midtrans) using QRIS or bank Virtual Account transfer. This app never directly processes or stores your card details, bank account, or other payment data — all of that is handled by Midtrans under its own privacy policy. Once payment is verified, our system only receives and stores your "premium active or not" status.'),
        ),
        StaticPageHeading(localize(lang, 'Tidak Ada Iklan atau Pelacak', 'No Ads or Trackers')),
        StaticPageParagraph(
          localize(lang,
              'Aplikasi ini tidak menampilkan iklan dan tidak menggunakan layanan analitik atau pelacak pihak ketiga mana pun. Layanan pihak ketiga yang dipakai hanya Firebase (Google) untuk masuk akun dan sinkronisasi data, serta Midtrans untuk memproses pembayaran Premium — keduanya tunduk pada kebijakan privasi masing-masing.',
              'This app shows no ads and doesn\'t use any third-party analytics or tracking service. The only third-party services used are Firebase (Google) for sign-in and data sync, and Midtrans for processing Premium payments — both governed by their own respective privacy policies.'),
        ),
        StaticPageHeading(localize(lang, 'Kontrol Kamu', 'Your Control')),
        StaticPageParagraph(
          localize(lang,
              'Kamu dapat menghapus dewa favorit kapan saja, mengubah pengaturan suara atau getaran, atau keluar dari akun Google, semuanya lewat halaman Profil. Menghapus aplikasi akan menghapus seluruh data lokal di perangkat. Kalau kamu ingin data cloud-mu, termasuk status premium, dihapus permanen, hubungi developer lewat email kevingultom3110@gmail.com.',
              'You can remove favorited gods anytime, change sound or haptics settings, or sign out of your Google account, all from the Profile page. Uninstalling the app removes all local data on your device. If you want your cloud data, including premium status, permanently deleted, contact the developer at kevingultom3110@gmail.com.'),
        ),
        StaticPageHeading(localize(lang, 'Perubahan Kebijakan', 'Changes to This Policy')),
        StaticPageParagraph(
          localize(lang,
              'Kebijakan ini akan diperbarui setiap kali aplikasi menambah fitur yang mengubah cara data dikumpulkan atau dipakai.',
              'This policy will be updated whenever the app adds a feature that changes how data is collected or used.'),
        ),
      ],
    );
  }
}
