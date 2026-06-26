using System.Net;

namespace CleaningHouse_API.Services.Email;

public static class EmailTemplateService
{
    public const string PasswordResetSubject = "رمز إعادة تعيين كلمة المرور - بريق";
    public const string WelcomeSubject = "مرحباً بك في بريق";
    public const string PasswordChangedSubject = "تم تغيير كلمة المرور - بريق";
    public const string AutoReplySubject = "شكراً لتواصلك - بريق";

    public const string PreviewOtpCode = "123456";
    public const string PreviewUserName = "عميل بريق";

    public static string BuildPasswordResetOtpHtml(string otpCode)
    {
        var safeOtp = WebUtility.HtmlEncode(otpCode);
        var content = $"""
            {EmailLayoutBuilder.H2("إعادة تعيين كلمة المرور")}
            {EmailLayoutBuilder.P("استخدم رمز التحقق التالي لإعادة تعيين كلمة المرور الخاصة بك في تطبيق بريق.")}
            <div style="background:{BareqEmailTheme.AccentBox};border:2px dashed {BareqEmailTheme.GradientEnd};border-radius:18px;padding:24px;text-align:center;margin:28px 0;">
              <div style="font-size:13px;color:#999;margin-bottom:10px;">رمز التحقق</div>
              <div style="font-size:42px;font-weight:700;letter-spacing:10px;color:{BareqEmailTheme.Primary};direction:ltr;">{safeOtp}</div>
            </div>
            <div style="background:{BareqEmailTheme.SoftBox};border-radius:14px;padding:16px 18px;margin-bottom:22px;">
              <p style="margin:0;font-size:14px;line-height:1.9;color:{BareqEmailTheme.PrimaryDark};">هذا الرمز صالح لمدة 10 دقائق فقط.</p>
            </div>
            {EmailLayoutBuilder.P("إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذه الرسالة بأمان.", $"color:{BareqEmailTheme.TextLight};font-size:14px;")}
            <p style="font-size:15px;line-height:2;margin:0;">مع تحيات،<br><strong style="color:{BareqEmailTheme.Primary};">فريق بريق</strong></p>
            """;

        return EmailLayoutBuilder.WrapHtmlDocument(
            PasswordResetSubject,
            EmailLayoutBuilder.BuildLayoutHtml("رمز التحقق", content));
    }

    public static string BuildPasswordResetOtpText(string otpCode) =>
        $"""
        مرحباً،

        استخدم رمز التحقق التالي لإعادة تعيين كلمة المرور الخاصة بك في تطبيق بريق:

        {otpCode}

        هذا الرمز صالح لمدة 10 دقائق فقط.

        إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذه الرسالة بأمان.

        مع تحيات،
        فريق بريق
        {EmailLayoutBuilder.BuildFooterText()}
        """;

    public static string BuildWelcomeEmailHtml(string userName)
    {
        var content = $"""
            {EmailLayoutBuilder.H2("مرحباً بك في بريق")}
            {EmailLayoutBuilder.Greeting(userName)}
            {EmailLayoutBuilder.P("شكراً لانضمامك إلى تطبيق بريق.")}
            {EmailLayoutBuilder.P("يمكنك الآن:")}
            <ul style="margin:0 0 24px 0;padding-right:22px;font-size:16px;line-height:2.2;color:{BareqEmailTheme.TextMuted};">
              <li>استعراض شركات التنظيف</li>
              <li>حجز العاملات بسهولة</li>
              <li>متابعة حجوزاتك</li>
              <li>إدارة حسابك بكل سهولة</li>
            </ul>
            <div style="background:{BareqEmailTheme.CtaBg};border-radius:16px;padding:20px;text-align:center;margin:8px 0 24px 0;border:1px solid {BareqEmailTheme.CardBorder};">
              <p style="margin:0;font-size:17px;font-weight:bold;color:{BareqEmailTheme.Primary};">ابدأ رحلتك الآن مع بريق</p>
            </div>
            <p style="font-size:15px;line-height:2;margin:0;">مع تحيات،<br><strong style="color:{BareqEmailTheme.Primary};">فريق بريق</strong></p>
            """;

        return EmailLayoutBuilder.WrapHtmlDocument(
            WelcomeSubject,
            EmailLayoutBuilder.BuildLayoutHtml("أهلاً بك", content));
    }

    public static string BuildWelcomeEmailText(string userName) =>
        $"""
        مرحباً {userName}،

        شكراً لانضمامك إلى تطبيق بريق.

        يمكنك الآن:
        - استعراض شركات التنظيف
        - حجز العاملات بسهولة
        - متابعة حجوزاتك
        - إدارة حسابك بكل سهولة

        ابدأ رحلتك الآن مع بريق.

        مع تحيات،
        فريق بريق
        {EmailLayoutBuilder.BuildFooterText()}
        """;

    public static string BuildPasswordChangedHtml(string userName)
    {
        var content = $"""
            {EmailLayoutBuilder.H2("تم تغيير كلمة المرور بنجاح")}
            {EmailLayoutBuilder.Greeting(userName)}
            {EmailLayoutBuilder.P("تم تغيير كلمة المرور الخاصة بحسابك في بريق بنجاح.")}
            <div style="background:{BareqEmailTheme.WarningBg};border:1px solid {BareqEmailTheme.WarningBorder};border-radius:14px;padding:16px 18px;margin:22px 0;">
              <p style="margin:0;font-size:14px;line-height:1.9;color:{BareqEmailTheme.WarningText};font-weight:bold;">
                إذا لم تقم بهذا التغيير، يرجى تأمين حسابك والتواصل مع فريق الدعم فوراً.
              </p>
            </div>
            {EmailLayoutBuilder.P($"يرجى التواصل معنا فوراً عبر <a href=\"mailto:{EmailLayoutBuilder.SupportEmail}\" style=\"color:{BareqEmailTheme.Primary};\">{EmailLayoutBuilder.SupportEmail}</a> إذا لم تكن أنت من قام بهذا التغيير.", "font-size:14px;")}
            <p style="font-size:15px;line-height:2;margin:0;">مع تحيات،<br><strong style="color:{BareqEmailTheme.Primary};">فريق بريق</strong></p>
            """;

        return EmailLayoutBuilder.WrapHtmlDocument(
            PasswordChangedSubject,
            EmailLayoutBuilder.BuildLayoutHtml("تنبيه أمني", content));
    }

    public static string BuildPasswordChangedText(string userName) =>
        $"""
        مرحباً {userName}،

        تم تغيير كلمة المرور الخاصة بحسابك في بريق بنجاح.

        إذا لم تقم بهذا التغيير، يرجى تأمين حسابك والتواصل مع فريق الدعم فوراً.
        الدعم: {EmailLayoutBuilder.SupportEmail}

        مع تحيات،
        فريق بريق
        {EmailLayoutBuilder.BuildFooterText()}
        """;

    public static string BuildAutoReplyEmailHtml(string? senderName = null)
    {
        var greeting = string.IsNullOrWhiteSpace(senderName)
            ? EmailLayoutBuilder.P("شكراً لتواصلك مع بريق.")
            : EmailLayoutBuilder.Greeting(senderName);

        var content = $"""
            {EmailLayoutBuilder.H2("شكراً لتواصلك")}
            {greeting}
            {EmailLayoutBuilder.P("لقد استلمنا رسالتك وسيقوم فريقنا بالرد عليك في أقرب وقت ممكن.")}
            {EmailLayoutBuilder.P("للاستفسارات العاجلة، يمكنك التواصل معنا عبر البريد الإلكتروني أدناه.")}
            <p style="font-size:15px;line-height:2;margin:0;">مع تحيات،<br><strong style="color:{BareqEmailTheme.Primary};">فريق بريق</strong></p>
            """;

        return EmailLayoutBuilder.WrapHtmlDocument(
            AutoReplySubject,
            EmailLayoutBuilder.BuildLayoutHtml("تأكيد استلام", content));
    }

    public static string BuildAutoReplyEmailText(string? senderName = null)
    {
        var greeting = string.IsNullOrWhiteSpace(senderName) ? "مرحباً،" : $"مرحباً {senderName}،";
        return $"""
            {greeting}

            شكراً لتواصلك مع بريق.
            لقد استلمنا رسالتك وسيقوم فريقنا بالرد عليك في أقرب وقت ممكن.

            مع تحيات،
            فريق بريق
            {EmailLayoutBuilder.BuildFooterText()}
            """;
    }
}
