import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../di/injection_container.dart';
import 'app_back_button.dart';
import '../../../features/notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../../features/auth/domain/entities/user.dart';

/// Top app bar with optional title, user identity, and notification bell.
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  final int? notificationCount;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? title;
  final bool showLeadingIdentity;
  final bool showLeftNotificationIcon;
  final bool showNotificationBell;

  const AppTopBar({
    super.key,
    this.notificationCount,
    this.showBackButton = false,
    this.onBackPressed,
    this.title,
    this.showLeadingIdentity = true,
    this.showLeftNotificationIcon = false,
    this.showNotificationBell = false,
  });

  @override
  State<AppTopBar> createState() => _AppTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppTopBarState extends State<AppTopBar> {
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load user after the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCurrentUser();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user when dependencies change (e.g., after navigation)
    // Use microtask to avoid setState during build
    Future.microtask(() {
      if (mounted && !_isLoading) {
        _loadCurrentUser();
      }
    });
  }

  /// Get display name for the user
  /// Prioritizes fullName, falls back to username
  String _getDisplayName() {
    if (_currentUser == null) return '';
    
    // Prioritize fullName if available and not empty
    if (_currentUser!.fullName != null && 
        _currentUser!.fullName!.trim().isNotEmpty) {
      return _currentUser!.fullName!.trim();
    }
    
    // Fall back to username if available
    if (_currentUser!.username.trim().isNotEmpty) {
      return _currentUser!.username.trim();
    }
    
    // Default fallback
    return 'User';
  }

  Future<void> _loadCurrentUser() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
    });

    try {
      final getCurrentUserUseCase = sl<GetCurrentUserUseCase>();
      final result = await getCurrentUserUseCase();
      
      if (!mounted) return;
      
      result.fold(
        (_) {
          if (mounted) {
            setState(() {
              _currentUser = null;
              _isLoading = false;
            });
          }
        },
        (user) {
          if (mounted) {
            setState(() {
              _currentUser = user;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.03), // Very subtle Light Sand tint (2-3%)
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.4), // Slightly more visible divider
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Directionality(
            textDirection: textDirection,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Start edge: back (subscreens), notification, or home identity.
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showBackButton)
                          AppBackButton(
                            onPressed:
                                widget.onBackPressed ??
                                () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppStrings.routeHome);
                                  }
                                },
                          ),
                        if (widget.title == null &&
                              !widget.showBackButton &&
                              widget.showLeadingIdentity)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cleaning_services,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                if (_currentUser != null) ...[
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      _getDisplayName(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                      ],
                    ),
                  ),

                  // Center title (independent of left/right widgets to avoid RTL spacing issues)
                  if (widget.title != null)
                    Center(
                      child: Text(
                        widget.title!,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (widget.showNotificationBell)
                    const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: NotificationBellIcon(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

