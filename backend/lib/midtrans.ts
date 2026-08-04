import midtransClient from 'midtrans-client';

const isProduction = process.env.MIDTRANS_IS_PRODUCTION === 'true';

function coreApi() {
  return new midtransClient.CoreApi({
    isProduction,
    serverKey: requireEnv('MIDTRANS_SERVER_KEY'),
    clientKey: requireEnv('MIDTRANS_CLIENT_KEY'),
  });
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} environment variable is not set`);
  return value;
}

export const PREMIUM_PRICE_IDR = 18_000;

export type PaymentMethod =
  | 'qris'
  | 'bca_va'
  | 'bni_va'
  | 'bri_va'
  | 'permata_va'
  | 'mandiri_va';

// All *_va methods settle into the same Midtrans merchant account (Kevin's
// BNI-linked account) regardless of which bank's VA the user pays through —
// the bank choice only affects which VA number the user is shown, not where
// the money ends up.
const BANK_TRANSFER_BANK: Partial<Record<PaymentMethod, string>> = {
  bca_va: 'bca',
  bni_va: 'bni',
  bri_va: 'bri',
};

/// Creates a Midtrans Core API charge for the fixed Premium price. The
/// caller never supplies an amount — it's hardcoded here so the client
/// can't request a discounted or zero price.
export async function createCharge(orderId: string, uid: string, method: PaymentMethod) {
  const base = {
    transaction_details: {
      order_id: orderId,
      gross_amount: PREMIUM_PRICE_IDR,
    },
    // Carried through to the webhook payload so we can map the paid
    // transaction back to the Firebase user without a separate lookup.
    custom_field1: uid,
  };

  if (method === 'qris') {
    return coreApi().charge({ ...base, payment_type: 'qris' });
  }

  if (method === 'permata_va') {
    return coreApi().charge({ ...base, payment_type: 'permata' });
  }

  if (method === 'mandiri_va') {
    // Mandiri VA goes through the separate echannel (bill payment) API
    // rather than bank_transfer — Midtrans returns bill_key/biller_code
    // instead of a va_numbers entry.
    return coreApi().charge({
      ...base,
      payment_type: 'echannel',
      echannel: { bill_info1: 'Mythopedia Premium', bill_info2: 'Pembayaran Premium' },
    });
  }

  return coreApi().charge({
    ...base,
    payment_type: 'bank_transfer',
    bank_transfer: { bank: BANK_TRANSFER_BANK[method]! },
  });
}

/// Re-fetches transaction status from Midtrans by order_id — used by the
/// webhook handler to verify the notification instead of trusting its body
/// outright (Midtrans's own recommended pattern).
export async function getTransactionStatus(orderId: string) {
  return coreApi().transaction.status(orderId);
}
