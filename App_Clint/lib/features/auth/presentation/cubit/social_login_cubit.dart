import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/social_auth_config.dart';
import '../../../../core/error/failures.dart';
import '../../data/services/social_auth_service.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../../domain/usecases/social_login_usecase.dart';
import 'social_login_state.dart';

class SocialLoginCubit extends Cubit<SocialLoginState> {
  SocialLoginCubit({
    required this.socialAuthService,
    required this.socialLoginUseCase,
  }) : super(const SocialLoginInitial());

  final SocialAuthService socialAuthService;
  final SocialLoginUseCase socialLoginUseCase;

  Future<void> signIn(SocialAuthProvider provider) async {
    if (isClosed) return;

    if (!SocialAuthConfig.isProviderConfigured(provider)) {
      emit(SocialLoginError(SocialAuthConfig.notConfiguredMessage(provider)));
      return;
    }

    emit(SocialLoginLoading(provider));

    try {
      final sdkResult = await socialAuthService.signIn(provider);
      if (sdkResult.cancelled) {
        if (isClosed) return;
        emit(const SocialLoginCancelled());
        return;
      }
      if (!sdkResult.hasCredentials) {
        if (isClosed) return;
        emit(const SocialLoginError('تعذّر الحصول على بيانات المصادقة.'));
        return;
      }

      final apiResult = await socialLoginUseCase(
        provider: provider,
        idToken: sdkResult.idToken,
        accessToken: sdkResult.accessToken,
        fullName: sdkResult.fullName,
        phone: sdkResult.phone,
      );

      apiResult.fold(
        (failure) {
          if (isClosed) return;
          emit(SocialLoginError(_mapFailureToMessage(failure)));
        },
        (result) {
          if (isClosed) return;
          emit(
            SocialLoginSuccess(
              user: result.user,
              requiresProfileCompletion: result.requiresProfileCompletion,
            ),
          );
        },
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Social login SDK error: $e\n$st');
      }
      if (isClosed) return;
      emit(SocialLoginError(e.toString()));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is AuthFailure) {
      final msg = failure.message;
      if (msg.contains('رمز تسجيل الدخول الاجتماعي') ||
          (msg.contains('غير صالح') && msg.contains('اجتماعي'))) {
        return '$msg\n(الخادم يرفض الرمز — Backend يحتاج تحديث Google/Apple Client IDs)';
      }
      return msg;
    }
    if (failure is ServerFailure) return failure.message;
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. تحقق من اتصالك.';
    }
    return failure.message;
  }
}
