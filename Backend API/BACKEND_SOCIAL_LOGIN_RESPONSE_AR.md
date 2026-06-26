# رد فريق الباكند — تسجيل الدخول الاجتماعي (Bareq / sitt_app)

**التاريخ:** يونيو 2026  
**البيئة:** `https://apialbareq.al-earth.ly`  
**Endpoint:** `POST /api/AppUsers/SocialLoginCustomer`

---

## إجابة السؤال 9 (مختصر)

| السؤال | الجواب |
|--------|--------|
| هل `SocialLoginCustomer` جاهز على الإنتاج؟ | **نعم** — منشور ويعمل. تم التحقق: طلب بتوكن وهمي يُرجع **401** مع رسالة عربية (السلوك المتوقع). |
| ما قيم `provider`؟ | `1` = Google، `2` = Apple، `3` = Facebook (enum رقمي) |
| ما حقول التوكن المتوقعة؟ | Google/Apple → **`idToken`** فقط. Facebook → **`accessToken`** فقط. |

---

## 1) الوضع الحالي على السيرفر

| البند | الحالة |
|-------|--------|
| Endpoint `SocialLoginCustomer` | ✅ منشور |
| جدول `ExternalLogins` + migration | ✅ مطبّق على `CleaningHouseDB` |
| التحقق من Google `idToken` | ✅ مُنفَّذ (`Google.Apis.Auth`) |
| التحقق من Facebook `accessToken` | ✅ مُنفَّذ (Graph API `debug_token` + `/me`) |
| التحقق من Apple `idToken` | ✅ مُنفَّذ (جاهز للمستقبل) |
| **مفاتيح OAuth على السيرفر** | ✅ **مُفعّلة** — Google Web + legacy client، Apple `ly.albareq.customerapp`، Facebook (يونيو 2026) |

**الخلاصة:** الباكند **جاهز** للاختبار end-to-end من TestFlight بعد تحديث تطبيق الموبايل لإصدار توكنات بالـ `aud` الصحيح.

---

## 2) عقد الـ API الفعلي (مهم — اختلافات عن ما في كود التطبيق)

### الطلب

```http
POST /api/AppUsers/SocialLoginCustomer
Content-Type: application/json
```

```json
{
  "provider": 1,
  "idToken": "...",
  "accessToken": null,
  "fullName": "اختياري",
  "phone": "اختياري"
}
```

| provider | القيمة | الحقول المطلوبة |
|----------|--------|-----------------|
| Google | `1` | `idToken` |
| Apple | `2` | `idToken` (+ `fullName` اختياري عند أول تسجيل Apple) |
| Facebook | `3` | `accessToken` |

### الاستجابة الناجحة (`200`)

```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح",
  "token": "JWT...",
  "user": {
    "id": 123,
    "fullName": "اسم المستخدم",
    "phone": "0912345678",
    "email": "user@example.com",
    "userTypeId": 1,
    "userTypeName": "Customer",
    "createdAt": "2026-06-18T12:00:00Z"
  },
  "isNewUser": false,
  "requiresProfileCompletion": false
}
```

### ⚠️ تصحيح حقول `user` — لا يوجد `username` ولا `role`

الباكند **لا يُرجع** `username` أو `role` في كائن `user`. استخدموا:

| ما يتوقعه التطبيق (حسب ملاحظاتكم) | ما يُرجعه الباكند فعلياً |
|-----------------------------------|--------------------------|
| `username` | **غير موجود** — استخدموا `fullName` أو `email` |
| `role` | **غير موجود** في JSON — استخدموا `userTypeName` (`"Customer"`) |
| — | `userTypeId` (رقم) |

**JWT:** الدور موجود داخل التوكن في claim `role` بقيمة `"Customer"`.  
معرّف المستخدم في claim `nameidentifier` (User Id كـ string).

---

## 3) أخطاء HTTP المتوقعة

| HTTP | message (عربي) | متى |
|------|----------------|-----|
| `401` | رمز تسجيل الدخول الاجتماعي غير صالح أو منتهي الصلاحية | توكن Google/Apple/Facebook غير صالح، أو **Client IDs غير مُعدّة على السيرفر** |
| `409` | الحساب مسجل بكلمة مرور — سجّل الدخول بالبريد أو اربط الحساب | نفس البريد مسجّل بحساب email/password |
| `400` | البريد الإلكتروني مطلوب من مزود تسجيل الدخول | Apple/Google لم يُرجعا email (نادر في Google) |
| `400` | هذا الحساب مسجل عبر Google/Apple/Facebook — استخدم تسجيل الدخول الاجتماعي | من **`/api/AppUsers/Login`** إذا حاول مستخدم social-only الدخول بكلمة مرور |

---

## 4) ما يحتاجه الباكند من فريق الموبايل / DevOps

### Google — بعد إنشاء OAuth clients في Google Cloud

أرسلوا لنا **جميع** Client IDs التي تصدر `idToken`:

```
SocialAuth__Google__ClientIds__0=106533226272-ohk9d2tf1lvnd9i6rnacffurtichatde.apps.googleusercontent.com
SocialAuth__Google__ClientIds__1=890986624234-31gjrl3sk8opup5j1m4g5euqmmtt4930.apps.googleusercontent.com
```

**مهم:** الباكند يتحقق من `aud` داخل `idToken` ضد **كل** الـ IDs في هذه القائمة.  
TestFlight الحالي يستخدم **Web Client ID** كـ `aud`. أضيفوا Android/iOS client IDs إذا كان `aud` في التوكن يختلف.

Bundle ID الحالي: `ly.albareq.customerapp` (Firebase project: albarerq).

### Facebook — على السيرفر (ليس Client Token)

| على السيرفر | على التطبيق فقط |
|-------------|-----------------|
| `SocialAuth__Facebook__AppId` | App ID في `social_auth_config.dart` |
| `SocialAuth__Facebook__AppSecret` | — |
| — | Client Token في `strings.xml` (Meta SDK) |

**Client Token لا يُرسل للباكند** — الباكند يتحقق من `y `accessToken` عبر Graph API باستخدام App ID + App Secret.

### Apple

```
SocialAuth__Apple__ClientIds__0=ly.albareq.customerapp
```

Team ID: `CL77WG373V` — Issuer: `https://appleid.apple.com`  
**لا** تستخدم `com.bareq.sittapp` (قديم).

---

## 5) إعداد Google Cloud — يمكن للباكند/DevOps تنفيذه

1. مشروع Google Cloud لتطبيق Bareq
2. OAuth consent screen
3. إنشاء clients:
   - **Web application** → Web Client ID للموبايل + السيرفر
   - **Android** → Package `ly.albareq.customerapp` + SHA-1 (debug + release من فريق الموبايل)
4. تسليم Web Client ID (+ Android/iOS IDs) لفريق الموبايل **والباكند**

---

## 6) إعداد Meta (Facebook)

1. تطبيق Consumer + Facebook Login
2. Android: Package + Key Hash (من SHA-1)
3. تسليم **App ID + Client Token** للموبايل
4. تسليم **App ID + App Secret** للباكند (App Secret **لا يوضع في التطبيق**)

---

## 7) قائمة التسليم — حالة الباكند

| البند | الحالة |
|-------|--------|
| `POST /api/AppUsers/SocialLoginCustomer` يعمل ويُرجع `token` + `user` | ✅ جاهز |
| التحقق من Google `idToken` على السيرفر | ✅ مُفعّل (Web + legacy client IDs) |
| التحقق من Facebook `accessToken` على السيرفر | ✅ مُفعّل |
| Google Web Client ID للموبايل | ✅ `106533226272-ohk9d2tf1lvnd9i6rnacffurtichatde.apps.googleusercontent.com` |
| Facebook App ID + Client Token للموبايل | ✅ مُفعّل على السيرفر |
| Bundle ID النهائي | ✅ `ly.albareq.customerapp` |
| iOS + Sign in with Apple | ✅ `ly.albareq.customerapp` على السيرفر |

---

## 8) تدفق التشخيص عند الأخطاء

```
[خطأ في popup Google/Facebook]
  → مشكلة موبايل / Google Cloud / Meta Console
  → SHA-1، Web Client ID، App ID، Key Hash
  → الباكند غير involved

[نجح popup + وصل طلب للAPI + 401]
  → توكن غير صالح، أو Client IDs غير مُضافة على السيرفر
  → راجع SocialAuth__Google__ClientIds__* و Facebook AppId/Secret

[409]
  → البريد مسجّل مسبقاً بكلمة مرور — استخدم Login العادي
```

---

## 9) إكمال الملف الشخصي بعد Social Login

إذا `requiresProfileCompletion: true` (الهاتف فارغ):

```http
PUT /api/AppUsers/ChangePhoneNumber
Authorization: Bearer {token}

{ "phone": "0912345678" }
```

---

## 10) خطوات DevOps بعد استلام المفاتيح

1. تعديل `/etc/albareqapi/env` — إلغاء التعليق وإضافة القيم الحقيقية
2. `sudo systemctl restart albareqapi.service`
3. اختبار: تسجيل دخول Google/Facebook من التطبيق → يجب `200` + JWT

---

## مرجع إضافي للموبايل

- `FLUTTER_CUSTOMER_SOCIAL_LOGIN_PROMPT.md` — دليل تكامل Flutter (إنجليزي)

---

**جهة الاتصال:** فريق Albareq API / DevOps  
**عند استلام:** Google Client IDs + Facebook App ID/Secret + SHA-1 debug/release → نُفعّل على السيرفر خلال دقائق.
