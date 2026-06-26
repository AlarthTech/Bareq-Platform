using System.Net;

namespace CleaningHouse_API.Services.Email;

public static class EmailLayoutBuilder
{
    public const string SupportEmail = "support@albareq.ly";
    public const string InfoEmail = "info@albareq.ly";

    public static string BuildFooterHtml() =>
        $"""
        <div style="border-top:1px solid {BareqEmailTheme.FooterBorder};padding:22px 24px;text-align:center;background:{BareqEmailTheme.FooterBg};">
          <p style="margin:0 0 12px 0;font-size:13px;font-weight:bold;color:{BareqEmailTheme.Primary};">للدعم والمساعدة:</p>
          <p style="margin:0 0 6px 0;font-size:13px;line-height:1.8;">
            <a href="mailto:{SupportEmail}" style="color:{BareqEmailTheme.Primary};text-decoration:none;">{SupportEmail}</a>
          </p>
          <p style="margin:0 0 14px 0;font-size:13px;line-height:1.8;">
            <a href="mailto:{InfoEmail}" style="color:{BareqEmailTheme.Primary};text-decoration:none;">{InfoEmail}</a>
          </p>
          <p style="margin:0;font-size:12px;color:#999;line-height:1.8;">
            هذه رسالة تلقائية، يرجى عدم الرد عليها.
          </p>
        </div>
        """;

    public static string BuildFooterText() =>
        $"""

        للدعم والمساعدة:
        {SupportEmail}
        {InfoEmail}

        هذه رسالة تلقائية، يرجى عدم الرد عليها.
        """;

    public static string BuildHeaderHtml(string? subtitle = null)
    {
        var subtitleBlock = string.IsNullOrWhiteSpace(subtitle)
            ? string.Empty
            : $"""<div style="font-size:14px;color:rgba(255,255,255,0.9);margin-top:10px;">{WebUtility.HtmlEncode(subtitle)}</div>""";

        return $"""
        <div style="background:linear-gradient(135deg,{BareqEmailTheme.GradientStart},{BareqEmailTheme.GradientEnd});padding:34px 24px;text-align:center;">
          <div style="font-size:34px;font-weight:700;color:#FFFFFF;">بريق</div>
          {subtitleBlock}
        </div>
        """;
    }

    public static string BuildLayoutHtml(string headerSubtitle, string innerContentHtml) =>
        $"""
        <div dir="rtl" lang="ar" style="margin:0;padding:0;background:{BareqEmailTheme.Background};font-family:Arial,Tahoma,sans-serif;color:{BareqEmailTheme.Text};">
          <div style="max-width:560px;margin:0 auto;padding:40px 16px;">
            <div style="background:{BareqEmailTheme.Card};border-radius:24px;overflow:hidden;border:1px solid {BareqEmailTheme.CardBorder};box-shadow:0 10px 30px rgba(0,0,0,0.05);">
              {BuildHeaderHtml(headerSubtitle)}
              <div style="padding:34px 28px;">
                {innerContentHtml}
              </div>
              {BuildFooterHtml()}
            </div>
          </div>
        </div>
        """;

    public static string WrapHtmlDocument(string title, string layoutHtml) =>
        $"""
        <!DOCTYPE html>
        <html lang="ar" dir="rtl">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>{WebUtility.HtmlEncode(title)}</title>
        </head>
        <body style="margin:0;padding:0;">
        {layoutHtml}
        </body>
        </html>
        """;

    private static string Encode(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);

    public static string P(string html, string style = "") =>
        $"""<p style="font-size:16px;line-height:2;margin:0 0 16px;color:{BareqEmailTheme.TextMuted};{style}">{html}</p>""";

    public static string H2(string text) =>
        $"""<h2 style="margin:0 0 18px;font-size:26px;color:{BareqEmailTheme.Primary};text-align:center;">{Encode(text)}</h2>""";

    public static string Greeting(string userName) =>
        P($"مرحباً <strong style=\"color:{BareqEmailTheme.Primary};\">{Encode(userName)}</strong>،");
}
