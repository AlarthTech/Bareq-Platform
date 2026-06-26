import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_type.dart';
import '../../domain/usecases/get_legal_document_usecase.dart';
import '../registration_legal_read_tracker.dart';
import '../widgets/legal_section.dart';

class LegalDocumentPage extends StatefulWidget {
  final LegalDocumentType documentType;
  final RegistrationLegalReadTracker? registrationReadTracker;

  const LegalDocumentPage({
    super.key,
    required this.documentType,
    this.registrationReadTracker,
  });

  bool get _requiresFullRead => registrationReadTracker != null;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  LegalDocument? _document;
  bool _loading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0;
  bool _reachedBottom = false;

  bool _documentRequested = false;

  LegalReadDocument get _readDocument =>
      widget.documentType == LegalDocumentType.terms
          ? LegalReadDocument.terms
          : LegalReadDocument.privacy;

  bool get _alreadyMarkedRead =>
      widget.registrationReadTracker?.isReadFor(_readDocument) ?? false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (_alreadyMarkedRead) {
      _reachedBottom = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_documentRequested) {
      _documentRequested = true;
      _loadDocument();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final progress = maxExtent <= 0
        ? 1.0
        : (position.pixels / maxExtent).clamp(0.0, 1.0);

    final atBottom = maxExtent <= 32 || position.pixels >= maxExtent - 32;

    if (progress != _scrollProgress || atBottom != _reachedBottom) {
      setState(() {
        _scrollProgress = progress;
        if (atBottom) _reachedBottom = true;
      });
    }
  }

  void _checkScrollAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  Future<void> _loadDocument() async {
    final l10n = L10n.of(context);
    final languageCode = l10n?.locale.languageCode ?? 'en';
    final result = await sl<GetLegalDocumentUseCase>()(
      type: widget.documentType,
      languageCode: languageCode,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _errorMessage = failure.message;
      }),
      (document) {
        setState(() {
          _loading = false;
          _document = document;
        });
        _checkScrollAfterLayout();
      },
    );
  }

  void _confirmRead() {
    widget.registrationReadTracker?.markReadFor(_readDocument);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n?.isRTL ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final title = _document?.title ??
        (widget.documentType == LegalDocumentType.terms
            ? (l10n?.translate('termsAndConditions') ?? 'Terms & Conditions')
            : (l10n?.translate('privacyPolicy') ?? 'Privacy Policy'));

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          AppTopBar(
            title: title,
            showBackButton: true,
            onBackPressed: () => context.pop(),
            showLeadingIdentity: false,
            showLeftNotificationIcon: false,
          ),
          LinearProgressIndicator(
            value: _scrollProgress,
            minHeight: 3,
            backgroundColor:
                isDark ? AppColors.darkSurfaceVariant : AppColors.divider,
            color: AppColors.primary,
          ),
          Expanded(child: _buildBody(context, isArabic, isDark)),
          if (widget._requiresFullRead) _buildReadConfirmationBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildReadConfirmationBar(BuildContext context, bool isDark) {
    final l10n = L10n.of(context);
    final canConfirm = _reachedBottom || _alreadyMarkedRead;
    final hint = l10n?.translate('legalScrollToReadAll') ??
        'Scroll to the end to read the full document';
    final buttonLabel = l10n?.translate('legalConfirmRead') ?? 'I have read this';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canConfirm)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_vertical,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: canConfirm ? _confirmRead : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textDisabled,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isArabic, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final doc = _document!;
    final introStyle = _introStyle(context, isArabic, isDark);
    final metaStyle = _metaStyle(context, isArabic, isDark);
    final bottomPadding = widget._requiresFullRead ? 24.0 : 28.0;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (doc.intro != null && doc.intro!.isNotEmpty) ...[
                Text(doc.intro!, style: introStyle),
                const SizedBox(height: 12),
              ],
              Text(
                '${L10n.translate(context, 'lastUpdated')}: ${doc.lastUpdated}',
                style: metaStyle,
              ),
              const SizedBox(height: 20),
              ...doc.sections.map(
                (section) => LegalSection(
                  section: section,
                  isArabic: isArabic,
                  isDark: isDark,
                ),
              ),
              if (doc.acceptance != null && doc.acceptance!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    doc.acceptance!,
                    style: introStyle.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  TextStyle _introStyle(BuildContext context, bool isArabic, bool isDark) {
    final color =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final base = Theme.of(context).textTheme.bodyLarge;
    if (isArabic) {
      return GoogleFonts.almarai(
        textStyle: base?.copyWith(color: color, height: 1.6, fontSize: 15),
      );
    }
    return base?.copyWith(color: color, height: 1.6, fontSize: 15) ??
        TextStyle(color: color, height: 1.6, fontSize: 15);
  }

  TextStyle _metaStyle(BuildContext context, bool isArabic, bool isDark) {
    final color =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final base = Theme.of(context).textTheme.labelMedium;
    if (isArabic) {
      return GoogleFonts.almarai(
        textStyle: base?.copyWith(color: color, fontWeight: FontWeight.w500),
      );
    }
    return base?.copyWith(color: color, fontWeight: FontWeight.w500) ??
        TextStyle(color: color, fontWeight: FontWeight.w500);
  }
}
