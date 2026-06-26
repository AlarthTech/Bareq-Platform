/// App asset paths constants
/// All asset paths should be defined here for easy management
class AppAssets {
  AppAssets._();

  // Images directory
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  static const String svgPath = 'assets/svg';

  // Brand
  static const String bareqLogo = '$imagesPath/bareq_logo.png';
  static const String bareqLoginHero = '$imagesPath/bareq_login_hero.png';
  static const String bareqRegistrationHero =
      '$imagesPath/bareq_registration_hero.png';
  static const String bareqLogoTopbar = '$imagesPath/bareq_logo_topbar.png';
  static const String appIcon = '$imagesPath/app_icon.png';

  // Placeholder images
  static const String placeholderAvatar = '$imagesPath/placeholder_avatar.png';
  static const String placeholderMaid = '$imagesPath/placeholder_maid.png';
  
  // Background images
  static const String maidDetailsBackground = '$imagesPath/maid_details_background.jpg';

  // Icons
  static const String iconHome = '$iconsPath/home.png';
  static const String iconSearch = '$iconsPath/search.png';

  // SVG Icons (if needed)
  static const String svgLogo = '$svgPath/logo.svg';
}

