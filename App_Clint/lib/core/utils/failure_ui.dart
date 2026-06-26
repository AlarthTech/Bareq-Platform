import 'package:flutter/material.dart';

import '../error/failures.dart';
import '../localization/l10n_helper.dart';

/// User-facing message for a domain [Failure].
String failureMessage(BuildContext context, Failure failure) {
  final l10n = L10n.of(context);
  if (failure is BookingConflictFailure || failure is ConflictFailure) {
    return failure.message;
  }
  if (failure is RateLimitFailure) {
    return failure.message;
  }
  if (failure is AuthFailure) {
    return l10n?.translate('sessionExpired') ?? failure.message;
  }
  if (failure is ForbiddenFailure) {
    return l10n?.translate('accessDenied') ?? failure.message;
  }
  if (failure is NotFoundFailure) {
    return l10n?.translate('notFound') ?? failure.message;
  }
  if (failure is ValidationFailure) {
    return failure.message;
  }
  if (failure is ServerFailure) {
    final code = failure.statusCode;
    if (code != null && code >= 500) {
      return l10n?.translate('serverErrorRetry') ?? failure.message;
    }
    return failure.message;
  }
  return failure.message;
}

bool failureRequiresLogout(Failure failure) => failure is AuthFailure;
