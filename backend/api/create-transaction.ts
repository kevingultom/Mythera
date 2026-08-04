import type { VercelRequest, VercelResponse } from '@vercel/node';
import { auth, db } from '../lib/firebase';
import { createCharge, PaymentMethod } from '../lib/midtrans';

/// POST /api/create-transaction
/// Body: { method: 'qris' | 'bni_va' }
/// Header: Authorization: Bearer <Firebase ID token>
///
/// Verifies the caller's Firebase ID token (so a user can only buy Premium
/// for their own account, never spoof another uid), creates a Midtrans
/// charge for the fixed premium price, records a pending order in
/// Firestore, and returns the payment details (QR image or VA number) for
/// the app to display.
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing Authorization header' });
    return;
  }

  let uid: string;
  try {
    const idToken = authHeader.slice('Bearer '.length);
    const decoded = await auth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (e: any) {
    console.error('ID token verification failed:', e?.message ?? e);
    res.status(401).json({
      error: 'Invalid or expired ID token',
      detail: e?.message ?? String(e),
    });
    return;
  }

  const method = req.body?.method as PaymentMethod | undefined;
  const validMethods: PaymentMethod[] = [
    'qris',
    'bca_va',
    'bni_va',
    'bri_va',
    'permata_va',
    'mandiri_va',
  ];
  if (!method || !validMethods.includes(method)) {
    res.status(400).json({ error: `method must be one of: ${validMethods.join(', ')}` });
    return;
  }

  // One order id per attempt so retries don't collide with a still-pending
  // Midtrans transaction for the same user.
  const orderId = `premium-${uid}-${Date.now()}`;

  let charge;
  try {
    charge = await createCharge(orderId, uid, method);
  } catch (e: any) {
    console.error('Midtrans charge failed', e?.ApiResponse ?? e);
    res.status(502).json({ error: 'Payment gateway request failed' });
    return;
  }

  await db().collection('orders').doc(orderId).set({
    uid,
    method,
    status: 'pending',
    createdAt: new Date().toISOString(),
  });

  if (method === 'qris') {
    const qrAction = (charge.actions ?? []).find(
      (a: any) => a.name === 'generate-qr-code',
    );
    res.status(200).json({
      orderId,
      method,
      qrImageUrl: qrAction?.url ?? null,
    });
    return;
  }

  if (method === 'permata_va') {
    res.status(200).json({
      orderId,
      method,
      bank: 'permata',
      vaNumber: charge.permata_va_number ?? null,
    });
    return;
  }

  if (method === 'mandiri_va') {
    res.status(200).json({
      orderId,
      method,
      bank: 'mandiri',
      billKey: charge.bill_key ?? null,
      billerCode: charge.biller_code ?? null,
    });
    return;
  }

  // bca_va / bni_va / bri_va
  const bank = method.replace('_va', '');
  const vaNumber = charge.va_numbers?.[0]?.va_number ?? null;
  res.status(200).json({
    orderId,
    method,
    bank,
    vaNumber,
  });
}
