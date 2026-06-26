import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_session_notifier.dart';
import '../auth/secure_token_storage.dart';
import '../services/app_icon_badge_service.dart';
import '../network/dio_client.dart';
import '../routing/app_router.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_cities_usecase.dart';
import '../../features/auth/domain/usecases/register_customer_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/social_login_usecase.dart';
import '../../features/auth/data/services/social_auth_service.dart';
import '../../features/forgot_password/data/datasources/forgot_password_remote_datasource.dart';
import '../../features/forgot_password/data/repositories/forgot_password_repository_impl.dart';
import '../../features/forgot_password/domain/repositories/forgot_password_repository.dart';
import '../../features/forgot_password/domain/usecases/request_reset_otp_usecase.dart';
import '../../features/forgot_password/domain/usecases/verify_reset_code_usecase.dart';
import '../../features/forgot_password/domain/usecases/reset_password_with_token_usecase.dart';
import '../../features/forgot_password/presentation/cubit/forgot_password_flow_cubit.dart';
import '../../features/forgot_password/presentation/cubit/forgot_password_cubit.dart';
import '../../features/forgot_password/presentation/cubit/verify_reset_code_cubit.dart';
import '../../features/forgot_password/presentation/cubit/reset_password_cubit.dart';
import '../../features/auth/domain/usecases/save_user_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/clear_user_usecase.dart';
import '../../features/auth/domain/usecases/check_authentication_usecase.dart';
import '../../features/auth/domain/usecases/get_all_app_users_usecase.dart';
import '../../features/auth/domain/usecases/change_phone_usecase.dart';
import '../../features/auth/domain/usecases/complete_profile_usecase.dart';
import '../../features/auth/domain/usecases/change_personal_info_usecase.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/delete_account_usecase.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_available_maids_usecase.dart';
import '../../features/home/domain/usecases/get_top_rated_maids_usecase.dart';
import '../../features/home/domain/usecases/get_top_rated_maids_page_usecase.dart';
import '../../features/home/domain/usecases/get_available_maids_page_usecase.dart';
import '../../features/home/domain/usecases/get_company_maids_page_usecase.dart';
import '../../features/home/domain/usecases/get_favorite_maids_usecase.dart';
import '../../features/home/domain/usecases/get_languages_usecase.dart';
import '../../features/home/domain/usecases/get_worker_by_id_usecase.dart';
import '../../features/companies/data/datasources/companies_remote_datasource.dart';
import '../../features/companies/data/repositories/companies_repository_impl.dart';
import '../../features/companies/domain/repositories/companies_repository.dart';
import '../../features/companies/domain/usecases/get_companies_usecase.dart';
import '../../features/companies/domain/usecases/get_company_by_id_usecase.dart';
import '../../features/booking/data/datasources/booking_remote_datasource.dart';
import '../../features/booking_pricing/data/datasources/booking_pricing_remote_datasource.dart';
import '../../features/booking_pricing/data/repositories/booking_pricing_repository_impl.dart';
import '../../features/booking_pricing/domain/repositories/booking_pricing_repository.dart';
import '../../features/booking_pricing/domain/usecases/preview_booking_price.dart';
import '../../features/booking_pricing/presentation/state/booking_price_preview_cubit.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/create_wallet_top_up.dart';
import '../../features/wallet/domain/usecases/get_bank_transfer_account.dart';
import '../../features/wallet/domain/usecases/get_top_up_status.dart';
import '../../features/wallet/domain/usecases/upload_receipt_image.dart';
import '../../features/wallet/domain/usecases/get_wallet_booking_quote.dart';
import '../../features/wallet/domain/usecases/get_wallet_summary.dart';
import '../../features/wallet/domain/usecases/get_wallet_transactions.dart';
import '../../features/wallet/domain/usecases/start_bank_card_top_up.dart';
import '../../features/wallet/domain/usecases/testing_instant_bank_card_top_up.dart';
import '../../features/wallet/data/wallet_testing_settings.dart';
import '../../features/wallet/data/wallet_top_up_url_cache.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';
import '../../features/wallet/presentation/cubit/wallet_transactions_cubit.dart';
import '../../features/booking/data/repositories/booking_repository_impl.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/get_worker_work_types_usecase.dart';
import '../../features/booking/domain/usecases/get_work_types_by_company_usecase.dart';
import '../../features/booking/domain/usecases/get_all_work_types_usecase.dart';
import '../../features/booking/domain/usecases/get_my_bookings_page_usecase.dart';
import '../../features/booking/domain/usecases/get_ongoing_bookings_usecase.dart';
import '../../features/booking/domain/usecases/get_my_bookings_usecase.dart';
import '../../features/booking/domain/usecases/get_company_bookings_usecase.dart';
import '../../features/booking/domain/usecases/create_booking_usecase.dart';
import '../../features/booking/domain/usecases/confirm_worker_arrival_usecase.dart';
import '../../features/booking/domain/usecases/update_booking_status_usecase.dart';
import '../../features/booking/domain/usecases/submit_review_usecase.dart';
import '../../features/user_locations/data/datasources/user_locations_remote_datasource.dart';
import '../../features/user_locations/data/repositories/user_locations_repository_impl.dart';
import '../../features/user_locations/domain/repositories/user_locations_repository.dart';
import '../../features/user_locations/domain/usecases/get_my_locations_usecase.dart';
import '../../features/user_locations/domain/usecases/get_my_locations_page_usecase.dart';
import '../../features/user_locations/domain/usecases/create_user_location_usecase.dart';
import '../../features/user_locations/domain/usecases/update_user_location_usecase.dart';
import '../../features/user_locations/domain/usecases/delete_user_location_usecase.dart';
import '../../features/legal/data/datasources/legal_asset_datasource.dart';
import '../../features/legal/data/repositories/legal_repository_impl.dart';
import '../../features/legal/domain/repositories/legal_repository.dart';
import '../../features/legal/domain/usecases/get_legal_document_usecase.dart';
import '../../features/reports/data/datasources/report_remote_datasource.dart';
import '../../features/reports/data/repositories/report_repository_impl.dart';
import '../../features/reports/domain/repositories/report_repository.dart';
import '../../features/reports/domain/usecases/create_report_usecase.dart';
import '../../features/reports/domain/usecases/get_my_reports_usecase.dart';
import '../../features/reports/domain/usecases/get_report_by_id_usecase.dart';
import '../../features/reports/domain/usecases/delete_report_usecase.dart';
import '../../features/reports/presentation/cubit/create_report_cubit.dart';
import '../../features/reports/presentation/cubit/my_reports_cubit.dart';
import '../../features/reports/presentation/models/create_report_args.dart';
import '../../features/booking_reports/data/datasources/booking_report_remote_datasource.dart';
import '../../features/booking_reports/data/repositories/booking_report_repository_impl.dart';
import '../../features/booking_reports/domain/repositories/booking_report_repository.dart';
import '../../features/booking_reports/domain/usecases/create_booking_report_usecase.dart';
import '../../features/booking_reports/domain/usecases/get_booking_reports_by_booking_usecase.dart';
import '../../features/booking_reports/domain/usecases/get_my_booking_reports_usecase.dart';
import '../../features/booking_reports/presentation/models/create_booking_report_args.dart';
import '../../features/booking_reports/presentation/state/booking_reports_by_booking_cubit.dart';
import '../../features/booking_reports/presentation/state/create_booking_report_cubit.dart';
import '../../features/booking_reports/presentation/state/my_booking_reports_cubit.dart';
import '../../features/reviews/data/datasources/review_remote_datasource.dart';
import '../../features/reviews/data/repositories/review_repository_impl.dart';
import '../../features/reviews/domain/repositories/review_repository.dart';
import '../../features/reviews/domain/usecases/review_usecases.dart';
import '../../features/reviews/presentation/state/booking_review_status_cubit.dart';
import '../../features/reviews/presentation/state/create_review_cubit.dart';
import '../../features/reviews/presentation/state/my_review_cubit.dart';
import '../../features/reviews/presentation/state/worker_reviews_cubit.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/datasources/notification_signalr_datasource.dart';
import '../../features/notifications/data/datasources/notification_preferences_local_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/data/repositories/notification_preferences_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/repositories/notification_preferences_repository.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/domain/usecases/notification_preferences_usecases.dart';
import '../../features/notifications/presentation/state/notification_preferences_cubit.dart';
import '../../features/notifications/data/services/notification_realtime_service.dart';
import '../../features/notifications/presentation/state/notifications_cubit.dart';
import '../../features/notifications/presentation/utils/notifications_badge_count.dart';
import '../../features/booking/presentation/state/booking_realtime_cubit.dart';
import '../../features/ratings/data/datasources/rating_cache.dart';
import '../../features/ratings/data/datasources/rating_remote_datasource.dart';
import '../../features/ratings/data/repositories/rating_repository_impl.dart';
import '../../features/ratings/domain/repositories/rating_repository.dart';
import '../../features/ratings/domain/usecases/rating_usecases.dart';
import '../../features/ratings/presentation/rating_refresh_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerLazySingleton<SecureTokenStorage>(
    () => SecureTokenStorageImpl(sl<FlutterSecureStorage>()),
  );
  sl.registerSingleton<AuthSessionNotifier>(AuthSessionNotifier());

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<SharedPreferences>(), sl<SecureTokenStorage>()),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      tokenStorage: sl<SecureTokenStorage>(),
      onUnauthorized: () async {
        await disconnectCustomerNotifications();
        await sl<AuthLocalDataSource>().clearUser();
        sl<AuthSessionNotifier>().clear();
      },
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<DioClient>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<AuthLocalDataSource>(),
      onSessionCleared: () {
        disconnectCustomerNotifications();
        sl<AuthSessionNotifier>().clear();
      },
    ),
  );

  sl.registerLazySingleton<GetCitiesUseCase>(
    () => GetCitiesUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterCustomerUseCase>(
    () => RegisterCustomerUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SocialLoginUseCase>(
    () => SocialLoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SocialAuthService>(
    () => SocialAuthService(),
  );
  sl.registerLazySingleton<ForgotPasswordRemoteDataSource>(
    () => ForgotPasswordRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<ForgotPasswordRepository>(
    () => ForgotPasswordRepositoryImpl(sl<ForgotPasswordRemoteDataSource>()),
  );
  sl.registerLazySingleton<RequestResetOtpUseCase>(
    () => RequestResetOtpUseCase(sl<ForgotPasswordRepository>()),
  );
  sl.registerLazySingleton<VerifyResetCodeUseCase>(
    () => VerifyResetCodeUseCase(sl<ForgotPasswordRepository>()),
  );
  sl.registerLazySingleton<ResetPasswordWithTokenUseCase>(
    () => ResetPasswordWithTokenUseCase(sl<ForgotPasswordRepository>()),
  );
  sl.registerLazySingleton<ForgotPasswordFlowCubit>(
    () => ForgotPasswordFlowCubit(),
  );
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(
      sl<RequestResetOtpUseCase>(),
      sl<ForgotPasswordFlowCubit>(),
    ),
  );
  sl.registerFactory<VerifyResetCodeCubit>(
    () => VerifyResetCodeCubit(
      flowCubit: sl<ForgotPasswordFlowCubit>(),
      requestResetOtpUseCase: sl<RequestResetOtpUseCase>(),
      verifyResetCodeUseCase: sl<VerifyResetCodeUseCase>(),
    ),
  );
  sl.registerFactory<ResetPasswordCubit>(
    () => ResetPasswordCubit(
      flowCubit: sl<ForgotPasswordFlowCubit>(),
      resetPasswordWithTokenUseCase: sl<ResetPasswordWithTokenUseCase>(),
    ),
  );
  sl.registerLazySingleton<SaveUserUseCase>(
    () => SaveUserUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ClearUserUseCase>(
    () => ClearUserUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CheckAuthenticationUseCase>(
    () => CheckAuthenticationUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetAllAppUsersUseCase>(
    () => GetAllAppUsersUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ChangePhoneUseCase>(
    () => ChangePhoneUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<CompleteProfileUseCase>(
    () => CompleteProfileUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ChangePersonalInfoUseCase>(
    () => ChangePersonalInfoUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<DeleteAccountUseCase>(
    () => DeleteAccountUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<CompaniesRemoteDataSource>(
    () => CompaniesRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<CompaniesRepository>(
    () => CompaniesRepositoryImpl(
      remoteDataSource: sl<CompaniesRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetCompaniesUseCase>(
    () => GetCompaniesUseCase(sl<CompaniesRepository>()),
  );
  sl.registerLazySingleton<GetCompanyByIdUseCase>(
    () => GetCompanyByIdUseCase(sl<CompaniesRepository>()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl<HomeRemoteDataSource>(),
      companiesRepository: sl<CompaniesRepository>(),
      ratingRepository: sl<RatingRepository>(),
    ),
  );
  sl.registerLazySingleton<GetAvailableMaidsUseCase>(
    () => GetAvailableMaidsUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetTopRatedMaidsUseCase>(
    () => GetTopRatedMaidsUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetTopRatedMaidsPageUseCase>(
    () => GetTopRatedMaidsPageUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetAvailableMaidsPageUseCase>(
    () => GetAvailableMaidsPageUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetCompanyMaidsPageUseCase>(
    () => GetCompanyMaidsPageUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetFavoriteMaidsUseCase>(
    () => GetFavoriteMaidsUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetLanguagesUseCase>(
    () => GetLanguagesUseCase(sl<HomeRepository>()),
  );
  sl.registerLazySingleton<GetWorkerByIdUseCase>(
    () => GetWorkerByIdUseCase(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl<BookingRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetWorkerWorkTypesUseCase>(
    () => GetWorkerWorkTypesUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetWorkTypesByCompanyUseCase>(
    () => GetWorkTypesByCompanyUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetAllWorkTypesUseCase>(
    () => GetAllWorkTypesUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetMyBookingsUseCase>(
    () => GetMyBookingsUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetMyBookingsPageUseCase>(
    () => GetMyBookingsPageUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetOngoingBookingsUseCase>(
    () => GetOngoingBookingsUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<GetCompanyBookingsUseCase>(
    () => GetCompanyBookingsUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<CreateBookingUseCase>(
    () => CreateBookingUseCase(sl<BookingRepository>()),
  );

  sl.registerLazySingleton<BookingPricingRemoteDataSource>(
    () => BookingPricingRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<BookingPricingRepository>(
    () => BookingPricingRepositoryImpl(sl<BookingPricingRemoteDataSource>()),
  );
  sl.registerLazySingleton<PreviewBookingPrice>(
    () => PreviewBookingPrice(sl<BookingPricingRepository>()),
  );
  sl.registerFactory<BookingPricePreviewCubit>(
    () => BookingPricePreviewCubit(sl<PreviewBookingPrice>()),
  );

  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<WalletTestingSettings>(
    () => WalletTestingSettings(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<WalletTopUpUrlCache>(
    () => WalletTopUpUrlCache(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(
      remoteDataSource: sl<WalletRemoteDataSource>(),
      testingSettings: sl<WalletTestingSettings>(),
      topUpUrlCache: sl<WalletTopUpUrlCache>(),
    ),
  );
  sl.registerLazySingleton<GetWalletSummaryUseCase>(
    () => GetWalletSummaryUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<GetWalletTransactionsUseCase>(
    () => GetWalletTransactionsUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<CreateWalletTopUpUseCase>(
    () => CreateWalletTopUpUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<GetTopUpStatusUseCase>(
    () => GetTopUpStatusUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<GetBankTransferAccountUseCase>(
    () => GetBankTransferAccountUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<UploadReceiptImageUseCase>(
    () => UploadReceiptImageUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<StartBankCardTopUpUseCase>(
    () => StartBankCardTopUpUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<TestingInstantBankCardTopUpUseCase>(
    () => TestingInstantBankCardTopUpUseCase(sl<WalletRepository>()),
  );
  sl.registerLazySingleton<GetWalletBookingQuoteUseCase>(
    () => const GetWalletBookingQuoteUseCase(),
  );
  sl.registerFactory<WalletCubit>(
    () => WalletCubit(sl<GetWalletSummaryUseCase>()),
  );
  sl.registerFactory<WalletTransactionsCubit>(
    () => WalletTransactionsCubit(sl<GetWalletTransactionsUseCase>()),
  );
  sl.registerLazySingleton<ConfirmWorkerArrivalUseCase>(
    () => ConfirmWorkerArrivalUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<UpdateBookingStatusUseCase>(
    () => UpdateBookingStatusUseCase(sl<BookingRepository>()),
  );
  sl.registerLazySingleton<SubmitReviewUseCase>(
    () => SubmitReviewUseCase(sl<BookingRepository>()),
  );

  sl.registerLazySingleton<UserLocationsRemoteDataSource>(
    () => UserLocationsRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<UserLocationsRepository>(
    () => UserLocationsRepositoryImpl(sl<UserLocationsRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetMyLocationsUseCase>(
    () => GetMyLocationsUseCase(sl<UserLocationsRepository>()),
  );
  sl.registerLazySingleton<GetMyLocationsPageUseCase>(
    () => GetMyLocationsPageUseCase(sl<UserLocationsRepository>()),
  );
  sl.registerLazySingleton<CreateUserLocationUseCase>(
    () => CreateUserLocationUseCase(sl<UserLocationsRepository>()),
  );
  sl.registerLazySingleton<UpdateUserLocationUseCase>(
    () => UpdateUserLocationUseCase(sl<UserLocationsRepository>()),
  );
  sl.registerLazySingleton<DeleteUserLocationUseCase>(
    () => DeleteUserLocationUseCase(sl<UserLocationsRepository>()),
  );

  sl.registerLazySingleton<LegalAssetDataSource>(
    () => LegalAssetDataSourceImpl(),
  );
  sl.registerLazySingleton<LegalRepository>(
    () => LegalRepositoryImpl(sl<LegalAssetDataSource>()),
  );
  sl.registerLazySingleton<GetLegalDocumentUseCase>(
    () => GetLegalDocumentUseCase(sl<LegalRepository>()),
  );

  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl<ReportRemoteDataSource>()),
  );
  sl.registerLazySingleton<CreateReportUseCase>(
    () => CreateReportUseCase(sl<ReportRepository>()),
  );
  sl.registerLazySingleton<GetMyReportsUseCase>(
    () => GetMyReportsUseCase(sl<ReportRepository>()),
  );
  sl.registerLazySingleton<GetReportByIdUseCase>(
    () => GetReportByIdUseCase(sl<ReportRepository>()),
  );
  sl.registerLazySingleton<DeleteReportUseCase>(
    () => DeleteReportUseCase(sl<ReportRepository>()),
  );
  sl.registerFactoryParam<CreateReportCubit, CreateReportArgs, void>(
    (args, _) => CreateReportCubit(
      createReportUseCase: sl<CreateReportUseCase>(),
      args: args,
    ),
  );
  sl.registerFactory<MyReportsCubit>(
    () => MyReportsCubit(sl<GetMyReportsUseCase>()),
  );

  sl.registerLazySingleton<BookingReportRemoteDataSource>(
    () => BookingReportRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<BookingReportRepository>(
    () => BookingReportRepositoryImpl(sl<BookingReportRemoteDataSource>()),
  );
  sl.registerLazySingleton<CreateBookingReportUseCase>(
    () => CreateBookingReportUseCase(sl<BookingReportRepository>()),
  );
  sl.registerLazySingleton<GetMyBookingReportsUseCase>(
    () => GetMyBookingReportsUseCase(sl<BookingReportRepository>()),
  );
  sl.registerLazySingleton<GetBookingReportsByBookingUseCase>(
    () => GetBookingReportsByBookingUseCase(sl<BookingReportRepository>()),
  );
  sl.registerFactoryParam<CreateBookingReportCubit, CreateBookingReportArgs,
      void>(
    (args, _) => CreateBookingReportCubit(
      createBookingReportUseCase: sl<CreateBookingReportUseCase>(),
      args: args,
    ),
  );
  sl.registerFactory<MyBookingReportsCubit>(
    () => MyBookingReportsCubit(sl<GetMyBookingReportsUseCase>()),
  );
  sl.registerFactoryParam<BookingReportsByBookingCubit, int, void>(
    (bookingId, _) => BookingReportsByBookingCubit(
      getBookingReportsByBookingUseCase:
          sl<GetBookingReportsByBookingUseCase>(),
      bookingId: bookingId,
    ),
  );

  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(sl<ReviewRemoteDataSource>()),
  );
  sl.registerLazySingleton<CreateReviewUseCase>(
    () => CreateReviewUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<UpdateReviewUseCase>(
    () => UpdateReviewUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<DeleteReviewUseCase>(
    () => DeleteReviewUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<GetReviewsByWorkerUseCase>(
    () => GetReviewsByWorkerUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<GetReviewsByBookingUseCase>(
    () => GetReviewsByBookingUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<GetReviewByIdUseCase>(
    () => GetReviewByIdUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<HasReviewForBookingUseCase>(
    () => HasReviewForBookingUseCase(sl<ReviewRepository>()),
  );
  sl.registerLazySingleton<BookingReviewStatusCubit>(
    () => BookingReviewStatusCubit(sl<HasReviewForBookingUseCase>()),
  );
  sl.registerFactory<CreateReviewCubit>(
    () => CreateReviewCubit(
      createReviewUseCase: sl<CreateReviewUseCase>(),
    ),
  );
  sl.registerFactory<WorkerReviewsCubit>(
    () => WorkerReviewsCubit(sl<GetReviewsByWorkerUseCase>()),
  );
  sl.registerFactory<MyReviewCubit>(
    () => MyReviewCubit(
      getReviewsByBookingUseCase: sl<GetReviewsByBookingUseCase>(),
      updateReviewUseCase: sl<UpdateReviewUseCase>(),
      deleteReviewUseCase: sl<DeleteReviewUseCase>(),
    ),
  );

  sl.registerLazySingleton<RatingCache>(() => RatingCache());
  sl.registerLazySingleton<RatingRefreshNotifier>(() => RatingRefreshNotifier());
  sl.registerLazySingleton<RatingRemoteDataSource>(
    () => RatingRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(
      remoteDataSource: sl<RatingRemoteDataSource>(),
      cache: sl<RatingCache>(),
    ),
  );
  sl.registerLazySingleton<GetWorkerRatingSummaryUseCase>(
    () => GetWorkerRatingSummaryUseCase(sl<RatingRepository>()),
  );
  sl.registerLazySingleton<GetCompanyRatingSummaryUseCase>(
    () => GetCompanyRatingSummaryUseCase(sl<RatingRepository>()),
  );
  sl.registerLazySingleton<GetCompanyWorkerSummariesUseCase>(
    () => GetCompanyWorkerSummariesUseCase(sl<RatingRepository>()),
  );
  sl.registerLazySingleton<InvalidateRatingCacheUseCase>(
    () => InvalidateRatingCacheUseCase(sl<RatingRepository>()),
  );

  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl<DioClient>()),
  );
  sl.registerLazySingleton<NotificationSignalRDataSource>(
    () => NotificationSignalRDataSourceImpl(sl<SecureTokenStorage>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl<NotificationRemoteDataSource>(),
      signalRDataSource: sl<NotificationSignalRDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetNotificationsUseCase>(
    () => GetNotificationsUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<GetUnreadCountUseCase>(
    () => GetUnreadCountUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<MarkNotificationReadUseCase>(
    () => MarkNotificationReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<MarkAllNotificationsReadUseCase>(
    () => MarkAllNotificationsReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<DeleteNotificationUseCase>(
    () => DeleteNotificationUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<WatchRealtimeNotificationsUseCase>(
    () => WatchRealtimeNotificationsUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<ConnectNotificationHubUseCase>(
    () => ConnectNotificationHubUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<DisconnectNotificationHubUseCase>(
    () => DisconnectNotificationHubUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<WatchBookingStatusChangesUseCase>(
    () => WatchBookingStatusChangesUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<NotificationPreferencesLocalDataSource>(
    () => NotificationPreferencesLocalDataSourceImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<NotificationPreferencesRepository>(
    () => NotificationPreferencesRepositoryImpl(
      sl<NotificationPreferencesLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<LoadNotificationPreferencesUseCase>(
    () => LoadNotificationPreferencesUseCase(
      sl<NotificationPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<SetNotificationsEnabledUseCase>(
    () => SetNotificationsEnabledUseCase(
      sl<NotificationPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<WatchNotificationPreferencesUseCase>(
    () => WatchNotificationPreferencesUseCase(
      sl<NotificationPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<IsNotificationEnabledUseCase>(
    () => IsNotificationEnabledUseCase(
      sl<NotificationPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<NotificationPreferencesCubit>(
    () => NotificationPreferencesCubit(
      loadPreferencesUseCase: sl<LoadNotificationPreferencesUseCase>(),
      setNotificationsEnabledUseCase: sl<SetNotificationsEnabledUseCase>(),
      watchPreferencesUseCase: sl<WatchNotificationPreferencesUseCase>(),
    ),
  );
  sl.registerLazySingleton<BookingRealtimeCubit>(() => BookingRealtimeCubit());
  sl.registerLazySingleton<AppIconBadgeService>(() => AppIconBadgeService());
  sl.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(
      getNotificationsUseCase: sl<GetNotificationsUseCase>(),
      getUnreadCountUseCase: sl<GetUnreadCountUseCase>(),
      markNotificationReadUseCase: sl<MarkNotificationReadUseCase>(),
      markAllNotificationsReadUseCase: sl<MarkAllNotificationsReadUseCase>(),
      deleteNotificationUseCase: sl<DeleteNotificationUseCase>(),
      watchRealtimeNotificationsUseCase:
          sl<WatchRealtimeNotificationsUseCase>(),
      connectNotificationHubUseCase: sl<ConnectNotificationHubUseCase>(),
      disconnectNotificationHubUseCase:
          sl<DisconnectNotificationHubUseCase>(),
      notificationPreferencesRepository:
          sl<NotificationPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<NotificationRealtimeService>(
    () => NotificationRealtimeService(
      watchBookingStatusChangesUseCase:
          sl<WatchBookingStatusChangesUseCase>(),
      notificationsCubit: sl<NotificationsCubit>(),
      bookingRealtimeCubit: sl<BookingRealtimeCubit>(),
      notificationPreferencesRepository:
          sl<NotificationPreferencesRepository>(),
    ),
  );

  AppRouter.configure(authSession: sl<AuthSessionNotifier>());
  await sl<AuthSessionNotifier>().restore(
    checkAuth: sl<CheckAuthenticationUseCase>(),
    getCurrentUser: sl<GetCurrentUserUseCase>(),
    getRequiresProfileCompletion: () async {
      final result = await sl<AuthRepository>().getRequiresProfileCompletion();
      return result.fold((_) => false, (value) => value);
    },
  );
  await initializeCustomerNotificationsIfNeeded();
}

/// Connect SignalR + load unread badge after login / cold start.
Future<void> initializeCustomerNotificationsIfNeeded() async {
  final session = sl<AuthSessionNotifier>();
  if (session.isLoggedIn) {
    await sl<NotificationPreferencesRepository>().load();
    sl<NotificationPreferencesCubit>().startWatching();
    await sl<NotificationsCubit>().initialize();
    await _syncAppIconBadgeFromNotificationsState();
    await sl<NotificationRealtimeService>().start();
  }
}

Future<void> _syncAppIconBadgeFromNotificationsState() async {
  final count = sl<NotificationsCubit>().state.launcherBadgeUnreadCount;
  if (count != null) {
    await sl<AppIconBadgeService>().updateUnreadCount(count);
  }
}

/// Disconnect hub and clear notification state on logout.
Future<void> disconnectCustomerNotifications() async {
  await sl<NotificationRealtimeService>().stop();
  await sl<NotificationsCubit>().reset();
  await sl<AppIconBadgeService>().clear();
}
