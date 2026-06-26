# Flutter Customer App — Social Login Integration

Backend endpoint for **Customer users only** (Google, Apple, Facebook). The mobile app obtains tokens via native SDKs and exchanges them for the existing JWT.

**Base URL (production):** `https://apialbareq.al-earth.ly`

---

## Endpoint

`POST /api/AppUsers/SocialLoginCustomer`

- **Auth:** none (`AllowAnonymous`)
- **Rate limit:** `auth` (same as password login)

### Request body

```json
{
  "provider": 1,
  "idToken": "…",
  "accessToken": null,
  "fullName": "optional fallback name",
  "phone": "optional if available from app"
}
```

| Field | Type | Notes |
|-------|------|--------|
| `provider` | int enum | `1` = Google, `2` = Apple, `3` = Facebook |
| `idToken` | string | **Required** for Google and Apple |
| `accessToken` | string | **Required** for Facebook |
| `fullName` | string | Optional; used if provider omits name (common with Apple) |
| `phone` | string | Optional; if omitted user may need profile completion |

### Success response (`200`)

Same shape as password login, with two extra flags:

```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح",
  "token": "JWT…",
  "user": {
    "id": 123,
    "fullName": "…",
    "phone": null,
    "email": "…",
    "userTypeId": 1,
    "userTypeName": "Customer",
    "createdAt": "…"
  },
  "isNewUser": false,
  "requiresProfileCompletion": true
}
```

| Flag | When `true` |
|------|-------------|
| `isNewUser` | Account was just created on this request |
| `requiresProfileCompletion` | `phone` is missing — show phone/profile screen before main app |

Store `token` exactly as for `POST /api/AppUsers/Login`. Send `Authorization: Bearer {token}` on all authenticated calls.

### Error responses

| HTTP | Message (Arabic) | Meaning |
|------|------------------|---------|
| `401` | رمز تسجيل الدخول الاجتماعي غير صالح أو منتهي الصلاحية | Invalid/expired provider token |
| `409` | الحساب مسجل بكلمة مرور — سجّل الدخول بالبريد أو اربط الحساب | Email already registered with password — use email login |
| `400` | هذا الحساب مسجل عبر Google/Apple/Facebook — استخدم تسجيل الدخول الاجتماعي | Returned from **password** login if account is social-only |

---

## Recommended Flutter packages

| Provider | Package |
|----------|---------|
| Google | `google_sign_in` |
| Apple | `sign_in_with_apple` |
| Facebook | `flutter_facebook_auth` |

---

## Flow (do not use `CreateNewCustomer` for social sign-up)

1. User taps social button → native SDK returns token.
2. Call `SocialLoginCustomer` with token (and optional `fullName` / `phone`).
3. Persist JWT (SecureStorage / shared prefs — same as password login).
4. If `requiresProfileCompletion` → block main navigation until phone is set via `PUT /api/AppUsers/ChangePhoneNumber` or your profile screen.
5. **Do not** call `CreateNewCustomer` for social registration.

---

## Platform notes

- **Android / iOS:** Configure OAuth client IDs in Google Cloud, Apple Developer, Meta Developer consoles. Backend validates tokens server-side; only **public** client IDs belong in the app.
- **iOS:** If you offer Google/Facebook sign-in, Apple Sign-In is required by App Store guidelines.
- **Web:** Google/Facebook need web OAuth client IDs in Flutter config; Apple Sign-In is limited on web.
- Send **`idToken`** for Google and Apple; send **`accessToken`** for Facebook.

---

## Password login interaction

Customers who registered with social login have **no password**. If they try email/password login, the API returns **400** with a message directing them to social login.

---

## Backend configuration (ops)

OAuth credentials are set on the server via environment variables (not in the Flutter app):

```bash
SocialAuth__Google__ClientIds__0=106533226272-ohk9d2tf1lvnd9i6rnacffurtichatde.apps.googleusercontent.com
SocialAuth__Google__ClientIds__1=890986624234-31gjrl3sk8opup5j1m4g5euqmmtt4930.apps.googleusercontent.com
SocialAuth__Facebook__AppId=…
SocialAuth__Facebook__AppSecret=…
SocialAuth__Apple__ClientIds__0=ly.albareq.customerapp
```

See [`CleaningHouse_API/deploy/albareqapi.env.example`](CleaningHouse_API/deploy/albareqapi.env.example) for the full server env template.

Until these are configured with real values from each provider console, token validation will fail with **401**.

---

## Testing checklist

- [ ] Google sign-in → `200` + JWT + `isNewUser: true` on first login
- [ ] Same Google account → `200` + `isNewUser: false`
- [ ] Apple first login with `fullName` when token has no name
- [ ] Facebook with `accessToken` only
- [ ] User with existing email/password account → `409`
- [ ] Social user tries password login → `400`
- [ ] Missing phone → `requiresProfileCompletion: true` → phone screen → `ChangePhoneNumber`
