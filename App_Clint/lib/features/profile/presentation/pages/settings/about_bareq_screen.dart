import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../widgets/about/about_back_button.dart';
import '../../widgets/about/about_description_section.dart';
import '../../widgets/about/about_footer_link.dart';
import '../../widgets/about/about_gradient_background.dart';
import '../../widgets/about/about_logo_header.dart';
import '../../widgets/about/about_social_links_row.dart';

class AboutBareqScreen extends StatefulWidget {
  const AboutBareqScreen({super.key});

  @override
  State<AboutBareqScreen> createState() => _AboutBareqScreenState();
}

class _AboutBareqScreenState extends State<AboutBareqScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.translate(context, 'couldNotOpenLink')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final version = _packageInfo?.version ?? '1.0.0';
    final build = _packageInfo?.buildNumber ?? '1';

    final versionLine =
        isArabic ? 'إصدار $version' : '${l10n?.translate('version') ?? 'Version'} $version';
    final buildLine =
        isArabic
            ? 'بناء $build'
            : '${l10n?.translate('build') ?? 'Build'} $build';

    final appName = l10n?.translate('bareqAppName') ?? (isArabic ? 'بريق' : 'Bareq');

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AboutGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AboutScreenConstants.horizontalPadding,
                ),
                child: AboutBackButton(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AboutScreenConstants.horizontalPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      AboutLogoHeader(
                            appName: appName,
                            versionLine: versionLine,
                            buildLine: buildLine,
                          )
                          .animate()
                          .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: AboutScreenConstants.sectionSpacing),
                      AboutDescriptionSection(
                            text:
                                l10n?.translate('aboutBareqDescription') ??
                                (isArabic
                                    ? 'بريق هو تطبيق متخصص في خدمات العاملات المنزلية والتنظيف، يتيح لك حجز العاملات بسهولة وأمان من أفضل الشركات المعتمدة في ليبيا، مع تجربة حجز احترافية وسريعة تناسب احتياجاتك اليومية.'
                                    : 'Bareq is a specialized app for domestic worker and cleaning services. Book trusted workers easily and securely from approved companies in Libya, with a fast, professional booking experience for your daily needs.'),
                          )
                          .animate(delay: 120.ms)
                          .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 480.ms,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: AboutScreenConstants.sectionSpacing),
                      AboutSocialLinksRow(
                            links: defaultAboutSocialLinks(
                              facebookLabel:
                                  l10n?.translate('facebook') ?? 'Facebook',
                              instagramLabel:
                                  l10n?.translate('instagram') ?? 'Instagram',
                              xLabel: l10n?.translate('xTwitter') ?? 'X',
                            ),
                            onLinkTap: _openExternalUrl,
                          )
                          .animate(delay: 220.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.04, end: 0, duration: 400.ms),
                      const SizedBox(height: 36),
                      Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              l10n?.translate('legalInformation') ??
                                  'Legal Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          )
                          .animate(delay: 280.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 12),
                      Column(
                            children: [
                              AboutFooterLink(
                                label:
                                    l10n?.translate('termsAndConditions') ??
                                    'Terms & Conditions',
                                onTap:
                                    () => context.push(
                                      AppStrings.routeTermsConditions,
                                    ),
                              ),
                              AboutFooterLink(
                                label:
                                    l10n?.translate('privacyPolicy') ??
                                    'Privacy Policy',
                                onTap:
                                    () => context.push(
                                      AppStrings.routePrivacyPolicy,
                                    ),
                              ),
                              AboutFooterLink(
                                label:
                                    l10n?.translate('contactUs') ??
                                    'Contact us',
                                onTap:
                                    () => context.push(
                                      AppStrings.routeHelpSupport,
                                    ),
                              ),
                            ],
                          )
                          .animate(delay: 320.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
