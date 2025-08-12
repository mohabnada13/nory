# Nory Shop — Project Setup & Deployment Guide

Welcome to **Nory Shop**, a Flutter + Firebase e-commerce solution for bakery & sweets with an admin dashboard and Paymob payments.

---

## 1. Prerequisites

| Tool | Minimum version | Install / Check |
|------|-----------------|-----------------|
| Flutter SDK | Stable channel ≥ 3.0 | `flutter --version` |
| Dart | Bundled with Flutter | ― |
| Android SDK & device/emulator | Android 8.0 (API 26)+ | Android Studio / `sdkmanager` |
| Firebase CLI | ≥ 13 | `npm i -g firebase-tools` |
| Node.js (for Cloud Functions) | ≥ 18 LTS | `node -v` |
| Git | any modern version | `git --version` |

---

## 2. Repository Structure

```
nory_shop/
 ├─ apps/
 │   ├─ mobile/        # Flutter Android app (package: com.noryshop.app)
 │   └─ admin_web/     # Flutter Web admin dashboard
 ├─ packages/
 │   ├─ models/        # Shared domain models
 │   └─ services/      # Shared service helpers (Paymob, paths, config)
 ├─ functions/         # Firebase Cloud Functions (TypeScript)
 ├─ firestore.rules    # Firestore security rules
 ├─ storage.rules      # Storage rules
 └─ SETUP.md           # ← you are here
```

---

## 3. Firebase Project Creation & Configuration

1. Create a Firebase project in the console (replace **`your-project-id`** below).
2. Log in & initialize:

   ```bash
   firebase login
   cd nory_shop
   firebase use --add your-project-id
   ```

3. Configure platforms via FlutterFire:

   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure \
     --project=your-project-id \
     --out=apps/mobile/lib/firebase_options.dart
   ```

4. Android:
   * Download the generated **google-services.json** and place it in  
     `apps/mobile/android/app/`.
   * Run `flutterfire configure` again if you later add SHA-1/256 for Google sign-in.

5. Web (admin):
   * In the Firebase console **> Project settings > Web**, register an app.  
     Copy the web config snippet and overwrite the placeholder in  
     `apps/admin_web/lib/main.dart → DefaultFirebaseOptions`.

---

## 4. Enabling Firebase Products

| Console Section | Setting |
|-----------------|---------|
| Authentication  | Providers → enable **Email/Password** and **Google** |
| Firestore DB    | Start in **Production** mode, then overwrite with the provided `firestore.rules` |
| Storage         | Enable → replace default rules with `storage.rules` |
| Cloud Functions | Upgrade Blaze/Billing tier (needed for outbound HTTP) |
| Cloud Messaging | Nothing extra; FCM auto-enabled |

Deploy rules:

```bash
firebase deploy --only firestore:rules,storage:rules
```

---

## 5. Cloud Functions

### 5.1 Environment variables (Paymob)

```bash
firebase functions:config:set paymob.api_key="LIVE_API_KEY" \
  paymob.hmac="LIVE_HMAC" \
  paymob.merchant_id="MERCHANT_ID" \
  paymob.integration_id_card="INTEGRATION_ID_CARD" \
  paymob.integration_id_wallet="INTEGRATION_ID_WALLET"
```

To inspect later: `firebase functions:config:get`.

### 5.2 Install & Deploy

```bash
cd nory_shop/functions
npm ci                    # installs locked deps
npm run build             # tsc compile to lib/
firebase deploy --only functions
```

If **placeholders** are kept, Functions run in **mock mode** (no real Paymob calls) which is safe for dev/testing.

---

## 6. Seeding Sample Data

After signing-in (any user) call the callable function:

```bash
firebase functions:shell
# In the shell prompt:
seedSampleData()
```

or from Admin Web → Dashboard → Products (Add sample manually).  
20 products across 5 categories will be written to Firestore.

---

## 7. Running the Mobile App (Android)

```bash
cd nory_shop/apps/mobile
flutter pub get
flutter run             # plug a device / start an emulator
```

First launch flow:

1. Splash → Onboarding → Sign-in.
2. Use email/password **or** Google (after SHA keys added in Firebase console).
3. Browse products, add to cart, checkout → Paymob mock checkout page.

---

## 8. Running the Admin Web & Hosting

Local dev:

```bash
cd nory_shop/apps/admin_web
flutter pub get
flutter run -d chrome   # or edge
```

Production build & deploy:

```bash
flutter build web --release
firebase deploy --only hosting
```

The deploy target is auto-created by `firebase init hosting`, pointing to `apps/admin_web/build/web`.

---

## 9. Environment Variables & Secrets

| Location | Purpose |
|----------|---------|
| `functions.config().paymob.*` | Sensitive Paymob keys (never commit) |
| `apps/**/lib/firebase_options.dart` | Non-secret Firebase app IDs (safe to commit) |
| `.env` (optional) | If you add `flutter_dotenv` for runtime keys |

---

## 10. Payment Flow

| Mode | How | Behaviour |
|------|-----|-----------|
| **Mock** (default) | Leave Paymob config as placeholders | Functions return fake tokens & always verify `true`. |
| **Live** | Set real keys with `firebase functions:config:set` | Real order, payment key, HMAC verification. |

UI automatically switches to wallet vs card iframe based on method chosen at checkout.

---

## 11. Notifications (FCM)

1. `firebase-messaging` is configured in `apps/mobile`.
2. On order creation, Cloud Function `onOrderCreated`:
   * Sends topic `orders` (for admins)
   * Sends user device token (store tokens in Firestore under `/users/{uid}/fcmToken`)
3. For promo broadcasts, publish to topic `promotions`:

   ```bash
   firebase messaging:send \
     --topic promotions \
     --notification.title "New Pastries!" \
     --notification.body "Try our butter croissants with 10% off!"
   ```

---

## 12. Unit Tests

Run model tests:

```bash
cd nory_shop/packages/models
dart test
```

The provided `promo_test.dart` validates discount logic.

---

## 13. Git & GitHub Workflow

```bash
git init
git remote add origin https://github.com/<your-user>/nory-shop.git
git add .
git commit -m "Initial scaffold"
git push -u origin main
```

Standard flow:

1. `git checkout -b feature/<name>`
2. Code → commit → `git push`
3. Create Pull Request → CI/CD (if configured) → merge.

---

## 14. Troubleshooting

| Issue | Fix |
|-------|-----|
| `FirebaseOptions have not been configured` | Rerun `flutterfire configure`, commit generated file. |
| Google sign-in fails on device | Add SHA-1 & SHA-256 of debug/release keystores to Firebase console → re-download `google-services.json`. |
| Paymob HMAC verification error | Ensure `paymob.hmac` in functions config matches Dashboard → Settings → HMAC. |
| `PERMISSION_DENIED` Firestore | Confirm correct rules deployed & authenticated user has required claims/UID. |

---

Happy baking! 🍞🍰
