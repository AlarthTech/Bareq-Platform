# Flutter Customer App — Forgot Password Update (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

You are updating **Forgot Password** in the **Bareq Customer** Flutter app to match the latest CleaningHouse API (May 2026). Use Clean Architecture (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`

This flow is for **Customer accounts only**. The backend sends a **rose/pink branded** OTP email with subject **"رمز إعادة تعيين كلمة المرور - بريق"**.

---

## What changed on the API (update your app)

If you already have a forgot-password flow, apply these fixes:

| Before (wrong / outdated) | Now (required) |
|---------------------------|----------------|
| No `userType` in body | Send `"userType": "Customer"` on **all 3** requests |
| Flutter sends `user_type` only | API accepts **both** `userType` and `user_type` — ensure one is sent |
| Email field = email only | `email` field accepts **email OR phone** (same as login `username`) |
| Different identifier per step | Use the **same** email/phone string in steps 1, 2, and 3 |
| Strict client email-only validation | Allow phone format on step 1 if user logs in with phone |
| Expect error when email not found | **Always show generic success** on step 1 (200 even if account unknown) |
| Store `resetToken` in SharedPreferences | Keep `resetToken` **in memory only** (Cubit/Bloc state) |
| Skip password rules | Validate: min 8 chars, upper, lower, digit **before** submit |

---

## User flow (3 screens)

1. **Forgot password** — user enters email or phone → `POST ForgotPassword` → always show generic Arabic success message.
2. **Verify OTP** — 6-digit code → `POST VerifyResetCode` → receive `resetToken`.
3. **New password** — new + confirm → `POST ResetPassword` → success → navigate to Login.

Use **rose/pink** UI accents to match customer emails: `#E11D48`, `#F43F5E`, `#FFF1F2`, `#881337`.

---

## API endpoints (anonymous — no JWT)

### Step 1 — Request OTP

```http
POST /api/AppUsers/ForgotPassword
Content-Type: application/json
```

```json
{
  "email": "customer@example.com",
  "userType": "Customer"
}
```

Or with phone (same field name):

```json
{
  "email": "0912345678",
  "userType": "Customer"
}
```

**Response (always 200 when request is valid):**

```json
{
  "message": "إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق."
}
```

- OTP is sent to the user's **registered email** (even if they entered phone in step 1).
- OTP expires in **10 minutes**.
- Rate limit: ~5 requests/hour per IP — handle **HTTP 429** with a friendly Arabic message.

---

### Step 2 — Verify OTP

```http
POST /api/AppUsers/VerifyResetCode
Content-Type: application/json
```

```json
{
  "email": "customer@example.com",
  "code": "123456",
  "userType": "Customer"
}
```

Use the **same** `email` value (email or phone) from step 1.

**Success (200):**

```json
{
  "resetToken": "url-safe-token-string"
}
```

**Failure (400):**

```json
{
  "message": "رمز التحقق غير صحيح أو منتهي الصلاحية."
}
```

- `code` must be exactly **6 digits**.
- Reset token expires **15 minutes** after verification.

---

### Step 3 — Reset password

```http
POST /api/AppUsers/ResetPassword
Content-Type: application/json
```

```json
{
  "email": "customer@example.com",
  "resetToken": "token-from-step-2",
  "newPassword": "NewStrongPass1",
  "userType": "Customer"
}
```

**Success (200):**

```json
{
  "message": "تم تغيير كلمة المرور بنجاح."
}
```

**Failure (400)** — invalid/expired token:

```json
{
  "message": "رمز إعادة التعيين غير صالح أو منتهي الصلاحية."
}
```

**Password policy** (validate client-side):

- Minimum **8** characters
- At least one **uppercase** letter
- At least one **lowercase** letter
- At least one **digit**

After success, user receives a **password-changed confirmation email** (do not block UI on email delivery).

---

## Data layer — request models

Ensure JSON matches API (camelCase **or** snake_case for `userType`):

```dart
class ForgotPasswordRequest {
  final String email; // email OR phone
  final String userType;

  ForgotPasswordRequest({
    required this.email,
    this.userType = 'Customer',
  });

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'userType': userType, // if using FieldRename.snake → sends user_type (also accepted)
  };
}
```

Apply the same `userType: 'Customer'` to `VerifyResetCodeRequest` and `ResetPasswordRequest`.

**Remote datasource example:**

```dart
Future<String> requestOtp(String identifier) async {
  final response = await _client.post(
    '/api/AppUsers/ForgotPassword',
    data: {
      'email': identifier.trim(),
      'userType': 'Customer',
    },
  );
  return response.data['message'] as String;
}
```

Map errors:

- **400** → parse `{ "message": "..." }`
- **429** → rate limit message in Arabic
- Network/timeout → `NetworkFailure`

---

## Presentation layer — UI updates

### Login screen
- Add / keep **"نسيت كلمة المرور؟"** → navigates to forgot-password flow.

### Step 1 field label
- Label as **"البريد الإلكتروني أو رقم الهاتف"** (not email-only).
- Validate: non-empty; email format OR phone digits (match your login rules).

### Step 1 success
- Always show: **"إذا كان البريد الإلكتروني مسجلاً لدينا، سيتم إرسال رمز التحقق."**
- Never show "email not found" or "email sent" differently.

### Pass identifier through flow
- Carry `identifier` (email/phone) from step 1 → 2 → 3 in Cubit/Bloc state.

### OTP screen
- 6-digit input, digits only.
- Optional: resend → go back to step 1 (respect rate limits).

### New password screen
- Password + confirm fields, visibility toggle.
- Disable submit while loading.

---

## Clean Architecture (if not built yet)

```
features/forgot_password/
├── domain/
│   ├── repositories/forgot_password_repository.dart
│   └── usecases/
│       ├── request_password_reset_otp.dart
│       ├── verify_password_reset_code.dart
│       └── reset_password.dart
├── data/
│   ├── models/...
│   ├── datasources/forgot_password_remote_datasource.dart
│   └── repositories/forgot_password_repository_impl.dart
└── presentation/
    ├── state/forgot_password_cubit.dart
    └── pages/
        ├── forgot_password_page.dart
        ├── verify_otp_page.dart
        └── reset_password_page.dart
```

Repository contract:

```dart
abstract class ForgotPasswordRepository {
  Future<Either<Failure, String>> requestOtp(String identifier);
  Future<Either<Failure, String>> verifyCode(String identifier, String code);
  Future<Either<Failure, String>> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  });
}
```

---

## Testing checklist

- [ ] Step 1 with **email** + `userType: Customer` → generic success
- [ ] Step 1 with **phone** + `userType: Customer` → generic success; OTP arrives at user's email
- [ ] Invalid OTP → Arabic 400 message
- [ ] Valid OTP → `resetToken` received
- [ ] Weak password blocked client-side
- [ ] Full flow → login works with `userType: "Customer"`
- [ ] Same identifier used in all 3 API calls
- [ ] `user_type` works if app uses snake_case JSON
- [ ] HTTP 429 shows friendly message

---

## Do NOT

- Send `userType: "Company"` from the Customer app
- Use different email/phone values between steps 1, 2, and 3
- Call API from widgets directly (use repository + use case + Cubit)
- Log OTP, resetToken, or passwords
- Reveal whether an account exists on step 1

---

## PROMPT END
