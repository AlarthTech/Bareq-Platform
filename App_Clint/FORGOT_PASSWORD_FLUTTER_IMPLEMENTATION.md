# Forgot Password (Email OTP) — Flutter Implementation (May 2026 API)

## API alignment

All three endpoints are **anonymous** (no JWT). Every request includes:

```json
{
  "email": "<email OR phone — same value through all steps>",
  "userType": "Customer"
}
```

| Step | Endpoint | Notes |
|------|----------|--------|
| 1 | `POST /api/AppUsers/ForgotPassword` | Always show generic Arabic success on 200 |
| 2 | `POST /api/AppUsers/VerifyResetCode` | + `"code": "123456"` → `resetToken` |
| 3 | `POST /api/AppUsers/ResetPassword` | + `resetToken`, `newPassword` |

Request models: `lib/features/forgot_password/data/models/forgot_password_requests.dart`

## Flow state (memory only)

`ForgotPasswordFlowCubit` (singleton) holds:

- `identifier` — email or phone from step 1
- `resetToken` — from step 2 verify

**Never** stored in SharedPreferences or secure storage. Cleared on successful reset or when restarting step 1.

## Screens

| Screen | Route |
|--------|-------|
| ForgotPasswordScreen | `/forgot-password` |
| VerifyResetCodeScreen | `/verify-reset-code` |
| ResetPasswordScreen | `/reset-password` |

## Validation

- **Step 1**: `LoginIdentifierValidator` — email OR phone (8–15 digits)
- **Step 2**: 6 digits only
- **Step 3**: min 8 chars, upper, lower, digit; confirm match

## UI

Rose/pink customer accents: `#E11D48`, `#F43F5E`, `#FFF1F2`, `#881337`

## Errors

- 400 OTP → `رمز التحقق غير صحيح أو منتهي الصلاحية.`
- 400 reset token → `رمز إعادة التعيين غير صالح أو منتهي الصلاحية.`
- 429 → rate limit Arabic message

## Manual QA

- [ ] Step 1 email + `userType: Customer` → generic success
- [ ] Step 1 phone → generic success; OTP to registered email
- [ ] Same identifier in all 3 API calls
- [ ] Invalid OTP → Arabic 400
- [ ] Valid OTP → resetToken in flow cubit only
- [ ] Weak password blocked client-side
- [ ] Full flow → login with new password
- [ ] HTTP 429 friendly message
- [ ] No account-existence leak on step 1
