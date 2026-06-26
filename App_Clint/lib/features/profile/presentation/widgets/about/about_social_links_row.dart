import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/constants/about_screen_constants.dart';
import '../../../../../core/constants/app_colors.dart';

class AboutSocialLink {
  const AboutSocialLink({
    required this.icon,
    required this.url,
    required this.semanticLabel,
  });

  final IconData icon;
  final String url;
  final String semanticLabel;
}

class AboutSocialLinksRow extends StatelessWidget {
  const AboutSocialLinksRow({
    super.key,
    required this.links,
    required this.onLinkTap,
  });

  final List<AboutSocialLink> links;
  final Future<void> Function(String url) onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          _SocialIconButton(
            link: links[i],
            onTap: () => onLinkTap(links[i].url),
          ),
        ],
      ],
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  const _SocialIconButton({required this.link, required this.onTap});

  final AboutSocialLink link;
  final VoidCallback onTap;

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.92 : 1.0;

    return Semantics(
      button: true,
      label: widget.link.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: AboutScreenConstants.socialButtonSize,
            height: AboutScreenConstants.socialButtonSize,
            decoration: BoxDecoration(
              color:
                  _pressed
                      ? Colors.white.withValues(alpha: 0.28)
                      : AboutScreenConstants.socialButtonFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _pressed
                        ? Colors.white.withValues(alpha: 0.85)
                        : AboutScreenConstants.socialButtonBorder,
              ),
              boxShadow:
                  _pressed
                      ? [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: FaIcon(
              widget.link.icon,
              size: AboutScreenConstants.socialIconSize,
              color:
                  _pressed
                      ? Colors.white
                      : AboutScreenConstants.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

List<AboutSocialLink> defaultAboutSocialLinks({
  required String facebookLabel,
  required String instagramLabel,
  required String xLabel,
}) {
  return [
    AboutSocialLink(
      icon: FontAwesomeIcons.facebookF,
      url: AboutScreenConstants.facebookUrl,
      semanticLabel: facebookLabel,
    ),
    AboutSocialLink(
      icon: FontAwesomeIcons.instagram,
      url: AboutScreenConstants.instagramUrl,
      semanticLabel: instagramLabel,
    ),
    AboutSocialLink(
      icon: FontAwesomeIcons.xTwitter,
      url: AboutScreenConstants.xTwitterUrl,
      semanticLabel: xLabel,
    ),
  ];
}
