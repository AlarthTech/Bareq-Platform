import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PagedListFooter extends StatelessWidget {
  const PagedListFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasNextPage,
  });

  final bool isLoadingMore;
  final bool hasNextPage;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (!hasNextPage) {
      return const SizedBox(height: AppTheme.spacing16);
    }
    return const SizedBox(height: AppTheme.spacing24);
  }
}

/// Triggers [onLoadMore] when the user scrolls near the bottom.
mixin PagedScrollLoader<T extends StatefulWidget> on State<T> {
  ScrollController get pagingScrollController;

  VoidCallback get onLoadMoreRequested;

  @override
  void initState() {
    super.initState();
    pagingScrollController.addListener(_handlePagedScroll);
  }

  @override
  void dispose() {
    pagingScrollController.removeListener(_handlePagedScroll);
    super.dispose();
  }

  void _handlePagedScroll() {
    if (!pagingScrollController.hasClients) return;
    final position = pagingScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      onLoadMoreRequested();
    }
  }
}
