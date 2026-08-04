# Mythopedia Premium Payment Backend

Two Vercel serverless functions:

- `api/create-transaction.ts` — the app calls this to start a payment. Verifies the caller's Firebase ID token, creates a fixed Rp 20,000 Midtrans charge (QRIS or BNI Virtual Account), and returns the QR image URL or VA number.
- `api/webhook.ts` — Midtrans calls this automatically when a payment settles. Verifies the notification signature, re-checks the transaction status directly with Midtrans, then sets `premium: true` on the user's Firestore doc.

## One-time setup

### 1. Install dependencies

```
cd backend
npm install
```

### 2. Get your Midtrans Sandbox keys

Midtrans Dashboard → make sure the environment switch (top-left) is set to **Sandbox** → **Settings → Access Keys** → copy **Server Key** and **Client Key**.

### 3. Prepare the Firebase service account value

The downloaded `serviceAccount.json` needs to become a single-line string for the `FIREBASE_SERVICE_ACCOUNT` environment variable. In PowerShell, from the folder containing the file:

```powershell
(Get-Content .\serviceAccount.json -Raw) -replace "`r`n", "" -replace "`n", "" | Set-Clipboard
```

That copies the minified JSON to your clipboard — paste it directly into the Vercel environment variable value (do not save it as a file anywhere in this repo).

### 4. Deploy to Vercel

From the `backend/` folder:

```
npx vercel
```

Follow the prompts (link to your Vercel account, create a new project — name it e.g. `mythopedia-payments`). Vercel will detect the `api/` folder automatically.

### 5. Set environment variables in Vercel

Vercel dashboard → your project → **Settings → Environment Variables** → add:

| Name | Value |
|---|---|
| `MIDTRANS_SERVER_KEY` | your Sandbox server key |
| `MIDTRANS_CLIENT_KEY` | your Sandbox client key |
| `MIDTRANS_IS_PRODUCTION` | `false` |
| `FIREBASE_SERVICE_ACCOUNT` | the single-line JSON from step 3 |

Redeploy after adding them (`npx vercel --prod` or trigger a redeploy from the dashboard).

### 6. Register the webhook URL with Midtrans

Midtrans Dashboard → **Settings → Configuration** → **Payment Notification URL** → set to:

```
https://<your-vercel-project>.vercel.app/api/webhook
```

### 7. Firestore security rules

Make sure `premium` can never be written by a client directly — only the Admin SDK (this backend) should be able to set it. In Firebase Console → Firestore → Rules, the `users/{uid}` document's `premium` field should be excluded from any client-writable field list.

## Firestore documents this backend touches

- `orders/{orderId}` — `{ uid, method, status: 'pending'|'paid'|'expire'|'cancel'|'deny', createdAt, paidAt? }`
- `users/{uid}` — merges `{ premium: true }` once payment settles.

## Testing in Sandbox

Midtrans Sandbox doesn't move real money. For QRIS, the Sandbox simulator lets you mark a transaction as paid from the Midtrans dashboard (**Transactions** page) without actually scanning anything. For VA, there's a simulator endpoint to trigger a fake transfer — see Midtrans's Sandbox docs for the current URL.
