class SocialSdkResult {
  const SocialSdkResult({
    this.idToken,
    this.accessToken,
    this.fullName,
    this.phone,
    this.cancelled = false,
  });

  final String? idToken;
  final String? accessToken;
  final String? fullName;
  final String? phone;
  final bool cancelled;

  bool get hasCredentials =>
      (idToken != null && idToken!.isNotEmpty) ||
      (accessToken != null && accessToken!.isNotEmpty);
}
