/// Backend social provider enum: 1=Google, 2=Apple, 3=Facebook.
enum SocialAuthProvider {
  google(1),
  apple(2),
  facebook(3);

  const SocialAuthProvider(this.apiValue);

  final int apiValue;
}
