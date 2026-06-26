import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../localization/l10n_helper.dart';

const String kSupportEmail = 'support@bareq.ly';

/// Launch phone dialer when [phone] has dialable digits.
Future<bool> launchPhoneCall(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.length < 6) {
    _showActionError(context, 'callUnavailable');
    return false;
  }
  final uri = Uri(scheme: 'tel', path: digits);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  _showActionError(context, 'callUnavailable');
  return false;
}

/// Open maps app for a text address (no lat/lng required).
Future<bool> launchMapsForAddress(BuildContext context, String address) async {
  final query = address.trim();
  if (query.isEmpty) {
    _showActionError(context, 'addressNotAvailable');
    return false;
  }
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  _showActionError(context, 'locationUnavailable');
  return false;
}

/// Opens the device email app to request a password reset via support.
Future<bool> launchSupportEmailForPasswordReset(
  BuildContext context, {
  required String identifier,
}) async {
  final l10n = L10n.of(context);
  final subject =
      l10n?.translate('forgotPasswordEmailSubject') ?? 'Password reset request';
  final bodyTemplate =
      l10n?.translate('forgotPasswordEmailBody') ??
      'Hello,\n\nI would like to reset my password for my Bareq account.\n\nAccount (email or phone): {identifier}\n\nThank you.';
  final body = bodyTemplate.replaceAll('{identifier}', identifier);

  final uri = Uri(
    scheme: 'mailto',
    path: kSupportEmail,
    queryParameters: <String, String>{
      'subject': subject,
      'body': body,
    },
  );

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  _showActionError(context, 'emailUnavailable');
  return false;
}

void _showActionError(BuildContext context, String key) {
  final l10n = L10n.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n?.translate(key) ?? 'Unable to open'),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
