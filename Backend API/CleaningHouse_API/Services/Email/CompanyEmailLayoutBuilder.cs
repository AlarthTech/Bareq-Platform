using System.Net;

namespace CleaningHouse_API.Services.Email;

/// <summary>RTL layout helpers for Bareq Company (teal) emails.</summary>
public static class CompanyEmailLayoutBuilder
{
    public static string BuildFooterHtml() =>
        $"""
        <div style="border-top:1px solid {BareqCompanyEmailTheme.FooterBorder};padding:22px 24px;text-align:center;background:{BareqCompanyEmailTheme.FooterBg};">
          <p style="margin:0 0 12px 0;font-size:13px;font-weight:bold;color:{BareqCompanyEmailTheme.Primary};">للدعم والمساعدة:</p>
          <p style="margin:0 0 6px 0;font-size:13px;line-height:1.8;">
            <a href="mailto:{EmailLayoutBuilder.SupportEmail}" style="color:{BareqCompanyEmailTheme.Primary};text-decoration:none;">{EmailLayoutBuilder.SupportEmail}</a>
          </p>
          <p style="margin:0 0 14px 0;font-size:13px;line-height:1.8;">
            <a href="mailto:{EmailLayoutBuilder.InfoEmail}" style="color:{BareqCompanyEmailTheme.Primary};text-decoration:none;">{EmailLayoutBuilder.InfoEmail}</a>
          </p>
          <p style="margin:0;font-size:12px;color:#999;line-height:1.8;">
            هذه رسالة تلقائية، يرجى عدم الرد عليها.
          </p>
        </div>
        """;

    public static string BuildHeaderHtml(string? subtitle = null)
    {
        var subtitleBlock = string.IsNullOrWhiteSpace(subtitle)
            ? string.Empty
            : $"""<div style="font-size:14px;color:rgba(255,255,255,0.92);margin-top:10px;">{WebUtility.HtmlEncode(subtitle)}</div>""";

        return $"""
        <div style="background:linear-gradient(135deg,{BareqCompanyEmailTheme.GradientStart},{BareqCompanyEmailTheme.GradientEnd});padding:34px 24px;text-align:center;">
          <div style="font-size:34px;font-weight:700;color:#FFFFFF;">بريق</div>
          <div style="font-size:12px;color:rgba(255,255,255,0.85);margin-top:6px;letter-spacing:0.5px;">للشركات</div>
          {subtitleBlock}
        </div>
        """;
    }

    public static string BuildLayoutHtml(string headerSubtitle, string innerContentHtml) =>
        $"""
        <div dir="rtl" lang="ar" style="margin:0;padding:0;background:{BareqCompanyEmailTheme.Background};font-family:Arial,Tahoma,sans-serif;color:{BareqCompanyEmailTheme.Text};">
          <div style="max-width:560px;margin:0 auto;padding:40px 16px;">
            <div style="background:{BareqCompanyEmailTheme.Card};border-radius:24px;overflow:hidden;border:1px solid {BareqCompanyEmailTheme.CardBorder};box-shadow:0 10px 30px rgba(13,148,136,0.08);">
              {BuildHeaderHtml(headerSubtitle)}
              <div style="padding:34px 28px;">
                {innerContentHtml}
              </div>
              {BuildFooterHtml()}
            </div>
          </div>
        </div>
        """;

    public static string H2(string text) =>
        $"""<h2 style="margin:0 0 18px;font-size:26px;color:{BareqCompanyEmailTheme.Primary};text-align:center;">{WebUtility.HtmlEncode(text)}</h2>""";

    public static string P(string html, string extraStyle = "") =>
        $"""<p style="font-size:16px;line-height:2;margin:0 0 16px;color:{BareqCompanyEmailTheme.TextMuted};{extraStyle}">{html}</p>""";
}
