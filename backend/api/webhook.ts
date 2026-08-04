import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createHash } from 'crypto';
import { db } from '../lib/firebase';
import { getTransactionStatus } from '../lib/midtrans';

/// POST /api/webhook — Midtrans payment notification.
///
/// Two layers of verification before ever touching Firestore, per
/// Midtrans's own guidance: (1) the signature_key hash must match, proving
/// the payload wasn't tampered with, and (2) we re-fetch the transaction
/// status directly from Midtrans by order_id rather than trusting the
/// posted status — a forged webhook can't fake what Midtrans itself
/// reports.
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const body = req.body ?? {};
  const { order_id, status_code, gross_amount, signature_key } = body;

  if (!order_id || !status_code || !gross_amount || !signature_key) {
    res.status(400).json({ error: 'Missing required notification fields' });
    return;
  }

  const serverKey = process.env.MIDTRANS_SERVER_KEY;
  if (!serverKey) {
    res.status(500).json({ error: 'Server misconfigured' });
    return;
  }

  const expectedSignature = createHash('sha512')
    .update(order_id + status_code + gross_amount + serverKey)
    .digest('hex');

  if (expectedSignature !== signature_key) {
    console.warn('Webhook signature mismatch', { order_id });
    res.status(403).json({ error: 'Invalid signature' });
    return;
  }

  // Re-verify with Midtrans directly rather than trusting the notification
  // body's own transaction_status field.
  let verified;
  try {
    verified = await getTransactionStatus(order_id);
  } catch (e) {
    console.error('Failed to verify transaction status', order_id, e);
    res.status(502).json({ error: 'Could not verify transaction' });
    return;
  }

  const orderRef = db().collection('orders').doc(order_id);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    console.warn('Webhook for unknown order', order_id);
    res.status(404).json({ error: 'Unknown order' });
    return;
  }
  const uid = orderSnap.data()?.uid as string | undefined;
  if (!uid) {
    res.status(500).json({ error: 'Order missing uid' });
    return;
  }

  const isSettled =
    verified.transaction_status === 'settlement' ||
    verified.transaction_status === 'capture';

  if (isSettled) {
    await Promise.all([
      orderRef.update({ status: 'paid', paidAt: new Date().toISOString() }),
      db().collection('users').doc(uid).set({ premium: true }, { merge: true }),
    ]);
  } else if (
    verified.transaction_status === 'expire' ||
    verified.transaction_status === 'cancel' ||
    verified.transaction_status === 'deny'
  ) {
    await orderRef.update({ status: verified.transaction_status });
  }

  // Midtrans only requires a 200 response to stop retrying the webhook.
  res.status(200).json({ received: true });
}
