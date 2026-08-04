import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_auth_service.dart';

/// Payment method offered at checkout — QRIS (scan with any e-wallet/bank
/// app) or a Midtrans-issued Virtual Account number for a specific bank.
/// Every VA option settles into the same Midtrans merchant account
/// regardless of which bank the user picks — the bank only determines which
/// VA number they're shown.
enum PaymentMethod { qris, bcaVa, bniVa, briVa, permataVa, mandiriVa }

extension PaymentMethodWire on PaymentMethod {
  String get wireValue => switch (this) {
        PaymentMethod.qris => 'qris',
        PaymentMethod.bcaVa => 'bca_va',
        PaymentMethod.bniVa => 'bni_va',
        PaymentMethod.briVa => 'bri_va',
        PaymentMethod.permataVa => 'permata_va',
        PaymentMethod.mandiriVa => 'mandiri_va',
      };
}

/// Result of starting a checkout: what to show the user so they can pay.
/// For QRIS, [qrImageUrl] is set. For most VA banks, [vaNumber] is set. For
/// Mandiri specifically, Midtrans uses its separate bill-payment (echannel)
/// API, so [billKey]/[billerCode] are set instead of [vaNumber].
class CheckoutResult {
  final String orderId;
  final PaymentMethod method;
  final String? qrImageUrl;
  final String? vaNumber;
  final String? billKey;
  final String? billerCode;

  const CheckoutResult({
    required this.orderId,
    required this.method,
    this.qrImageUrl,
    this.vaNumber,
    this.billKey,
    this.billerCode,
  });
}

/// Talks to the Vercel payment backend (see /backend in the repo) to start
/// a Midtrans transaction. The backend itself verifies the caller's
/// Firebase ID token and hardcodes the Rp 18,000 price — this client never
/// sends an amount.
///
/// Payment completion isn't polled here: once Midtrans notifies the
/// backend's webhook, the backend sets `premium: true` on the user's
/// Firestore doc, and PremiumService.watch() (already running) picks that
/// up live, so the UI updates on its own.
class PaymentService {
  PaymentService._();

  static const _baseUrl = 'https://mythera-payments.vercel.app';

  static Future<CheckoutResult> startCheckout(PaymentMethod method) async {
    final user = FirebaseAuthService.instance.currentUser;
    if (user == null) {
      throw StateError('Cannot start checkout: no signed-in user');
    }
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/create-transaction'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'method': method.wireValue}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Checkout failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CheckoutResult(
      orderId: data['orderId'] as String,
      method: method,
      qrImageUrl: data['qrImageUrl'] as String?,
      vaNumber: data['vaNumber'] as String?,
      billKey: data['billKey'] as String?,
      billerCode: data['billerCode'] as String?,
    );
  }
}
