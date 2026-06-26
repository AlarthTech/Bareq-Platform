import 'package:get_it/get_it.dart';
import '../network/api_client.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/change_personal_info_usecase.dart';
import '../../features/auth/domain/usecases/change_phone_number_usecase.dart';
import '../../features/auth/domain/usecases/delete_my_company_account_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/account_settings_cubit.dart';
import '../../features/auth/presentation/bloc/delete_account_cubit.dart';

// Company
import '../../features/company/data/datasources/company_remote_datasource.dart';
import '../../features/company/data/repositories/company_repository_impl.dart';
import '../../features/company/domain/repositories/company_repository.dart';
import '../../features/company/domain/usecases/get_my_company_usecase.dart';
import '../../features/company/domain/usecases/create_company_usecase.dart';
import '../../features/company/domain/usecases/get_all_cities_usecase.dart';
import '../../features/company/domain/usecases/update_company_usecase.dart';
import '../../features/company/domain/usecases/upload_commercial_register_usecase.dart';
import '../../features/company/presentation/cubit/company_guard_cubit.dart';
import '../../features/company/presentation/bloc/company_bloc.dart';

// Workers
import '../../features/workers/data/datasources/worker_remote_datasource.dart';
import '../../features/workers/data/repositories/worker_repository_impl.dart';
import '../../features/workers/domain/repositories/worker_repository.dart';
import '../../features/workers/domain/usecases/get_workers_usecase.dart';
import '../../features/workers/domain/usecases/create_worker_usecase.dart';
import '../../features/workers/domain/usecases/update_worker_usecase.dart';
import '../../features/workers/domain/usecases/get_nationalities_usecase.dart';
import '../../features/workers/domain/usecases/get_languages_usecase.dart';
import '../../features/workers/presentation/bloc/worker_bloc.dart';

// Work Types
import '../../features/work_types/data/datasources/work_type_remote_datasource.dart';
import '../../features/work_types/data/repositories/work_type_repository_impl.dart';
import '../../features/work_types/domain/repositories/work_type_repository.dart';
import '../../features/work_types/domain/usecases/get_work_types_usecase.dart';
import '../../features/work_types/domain/usecases/create_work_type_usecase.dart';
import '../../features/work_types/domain/usecases/update_work_type_usecase.dart';
import '../../features/work_types/domain/usecases/delete_work_type_usecase.dart';
import '../../features/work_types/domain/usecases/assign_work_type_to_worker_usecase.dart';
import '../../features/work_types/domain/usecases/get_worker_work_types_usecase.dart';
import '../../features/work_types/presentation/bloc/work_type_bloc.dart';

// Bookings
import '../../features/bookings/data/datasources/booking_remote_datasource.dart';
import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/bookings/domain/usecases/get_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/get_booking_by_id_usecase.dart';
import '../../features/bookings/domain/usecases/update_booking_status_usecase.dart';
import '../../features/bookings/presentation/bloc/booking_bloc.dart';

// Dashboard
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Forgot Password
import '../../features/forgot_password/data/datasources/forgot_password_remote_datasource.dart';
import '../../features/forgot_password/data/repositories/forgot_password_repository_impl.dart';
import '../../features/forgot_password/domain/repositories/forgot_password_repository.dart';
import '../../features/forgot_password/domain/usecases/request_password_reset_otp.dart';
import '../../features/forgot_password/domain/usecases/verify_password_reset_code.dart';
import '../../features/forgot_password/domain/usecases/reset_password.dart';
import '../../features/forgot_password/presentation/state/forgot_password_cubit.dart';

// Notifications
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/datasources/notification_signalr_datasource.dart';
import '../../features/notifications/data/services/notification_realtime_service.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/get_unread_count.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/subscribe_to_notifications.dart';
import '../../features/notifications/presentation/state/notifications_cubit.dart';
import '../../features/bookings/presentation/cubit/booking_realtime_cubit.dart';

// Worker Reviews
import '../../features/worker_reviews/data/datasources/worker_reviews_remote_datasource.dart';
import '../../features/worker_reviews/data/repositories/worker_reviews_repository_impl.dart';
import '../../features/worker_reviews/domain/repositories/worker_reviews_repository.dart';
import '../../features/worker_reviews/domain/usecases/get_company_rating_summary.dart';
import '../../features/worker_reviews/domain/usecases/get_company_worker_summaries.dart';
import '../../features/worker_reviews/domain/usecases/get_worker_rating_summary.dart';
import '../../features/worker_reviews/domain/usecases/get_worker_reviews.dart';
import '../../features/worker_reviews/domain/usecases/get_review_by_id.dart';
import '../../features/worker_reviews/domain/usecases/get_company_workers_with_ratings.dart';
import '../../features/worker_reviews/presentation/state/company_ratings_cubit.dart';
import '../../features/worker_reviews/presentation/state/worker_reviews_cubit.dart';

// Booking Reports
import '../../features/booking_reports/data/datasources/booking_report_remote_datasource.dart';
import '../../features/booking_reports/data/repositories/booking_report_repository_impl.dart';
import '../../features/booking_reports/domain/repositories/booking_report_repository.dart';
import '../../features/booking_reports/domain/usecases/get_company_booking_reports_usecase.dart';
import '../../features/booking_reports/domain/usecases/get_booking_report_by_id_usecase.dart';
import '../../features/booking_reports/domain/usecases/update_booking_report_status_usecase.dart';
import '../../features/booking_reports/presentation/state/company_booking_reports_cubit.dart';
import '../../features/booking_reports/presentation/state/booking_report_detail_cubit.dart';
import '../../features/booking_reports/presentation/state/update_booking_report_status_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Network
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  
  // ========== AUTH ==========
  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<ApiClient>(),
    ),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ChangePasswordUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ChangePersonalInfoUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ChangePhoneNumberUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => DeleteMyCompanyAccountUseCase(getIt<AuthRepository>()),
  );
  
  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      apiClient: getIt<ApiClient>(),
    ),
  );
  getIt.registerFactory(
    () => AccountSettingsCubit(
      changePasswordUseCase: getIt<ChangePasswordUseCase>(),
      changePersonalInfoUseCase: getIt<ChangePersonalInfoUseCase>(),
      changePhoneNumberUseCase: getIt<ChangePhoneNumberUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => DeleteAccountCubit(
      deleteMyCompanyAccountUseCase: getIt<DeleteMyCompanyAccountUseCase>(),
    ),
  );

  // ========== FORGOT PASSWORD ==========
  getIt.registerLazySingleton<ForgotPasswordRemoteDataSource>(
    () => ForgotPasswordRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ForgotPasswordRepository>(
    () => ForgotPasswordRepositoryImpl(getIt<ForgotPasswordRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => RequestPasswordResetOtpUseCase(getIt<ForgotPasswordRepository>()),
  );
  getIt.registerLazySingleton(
    () => VerifyPasswordResetCodeUseCase(getIt<ForgotPasswordRepository>()),
  );
  getIt.registerLazySingleton(
    () => ResetPasswordUseCase(getIt<ForgotPasswordRepository>()),
  );
  getIt.registerFactory(
    () => ForgotPasswordCubit(
      requestOtpUseCase: getIt<RequestPasswordResetOtpUseCase>(),
      verifyCodeUseCase: getIt<VerifyPasswordResetCodeUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
    ),
  );
  
  // ========== COMPANY ==========
  // Data Sources
  getIt.registerLazySingleton<CompanyRemoteDataSource>(
    () => CompanyRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<CompanyRepository>(
    () => CompanyRepositoryImpl(getIt<CompanyRemoteDataSource>()),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetMyCompanyUseCase(getIt<CompanyRepository>()));
  getIt.registerLazySingleton(() => CreateCompanyUseCase(getIt<CompanyRepository>()));
  getIt.registerLazySingleton(() => UpdateCompanyUseCase(getIt<CompanyRepository>()));
  getIt.registerLazySingleton(() => GetAllCitiesUseCase(getIt<CompanyRepository>()));
  getIt.registerLazySingleton(
    () => UploadCommercialRegisterUseCase(getIt<CompanyRepository>()),
  );

  getIt.registerLazySingleton(
    () => CompanyGuardCubit(getMyCompanyUseCase: getIt<GetMyCompanyUseCase>()),
  );

  // BLoCs
  getIt.registerFactory(
    () => CompanyBloc(
      getMyCompanyUseCase: getIt<GetMyCompanyUseCase>(),
      createCompanyUseCase: getIt<CreateCompanyUseCase>(),
      updateCompanyUseCase: getIt<UpdateCompanyUseCase>(),
      getAllCitiesUseCase: getIt<GetAllCitiesUseCase>(),
      uploadCommercialRegisterUseCase: getIt<UploadCommercialRegisterUseCase>(),
    ),
  );
  
  // ========== WORKERS ==========
  // Data Sources
  getIt.registerLazySingleton<WorkerRemoteDataSource>(
    () => WorkerRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<WorkerRepository>(
    () => WorkerRepositoryImpl(getIt<WorkerRemoteDataSource>()),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetWorkersUseCase(getIt<WorkerRepository>()));
  getIt.registerLazySingleton(() => CreateWorkerUseCase(getIt<WorkerRepository>()));
  getIt.registerLazySingleton(() => UpdateWorkerUseCase(getIt<WorkerRepository>()));
  getIt.registerLazySingleton(() => GetNationalitiesUseCase(getIt<WorkerRepository>()));
  getIt.registerLazySingleton(() => GetLanguagesUseCase(getIt<WorkerRepository>()));
  
  // BLoCs
  getIt.registerFactory(
    () => WorkerBloc(
      getWorkersUseCase: getIt<GetWorkersUseCase>(),
      createWorkerUseCase: getIt<CreateWorkerUseCase>(),
      getNationalitiesUseCase: getIt<GetNationalitiesUseCase>(),
      getLanguagesUseCase: getIt<GetLanguagesUseCase>(),
    ),
  );
  
  // ========== WORK TYPES ==========
  // Data Sources
  getIt.registerLazySingleton<WorkTypeRemoteDataSource>(
    () => WorkTypeRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<WorkTypeRepository>(
    () => WorkTypeRepositoryImpl(getIt<WorkTypeRemoteDataSource>()),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetWorkTypesUseCase(getIt<WorkTypeRepository>()));
  getIt.registerLazySingleton(() => CreateWorkTypeUseCase(getIt<WorkTypeRepository>()));
  getIt.registerLazySingleton(() => UpdateWorkTypeUseCase(getIt<WorkTypeRepository>()));
  getIt.registerLazySingleton(() => DeleteWorkTypeUseCase(getIt<WorkTypeRepository>()));
  getIt.registerLazySingleton(
    () => AssignWorkTypeToWorkerUseCase(getIt<WorkTypeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkerWorkTypesUseCase(getIt<WorkTypeRepository>()),
  );
  
  // BLoCs
  getIt.registerFactory(
    () => WorkTypeBloc(
      getWorkTypesUseCase: getIt<GetWorkTypesUseCase>(),
      createWorkTypeUseCase: getIt<CreateWorkTypeUseCase>(),
      updateWorkTypeUseCase: getIt<UpdateWorkTypeUseCase>(),
      deleteWorkTypeUseCase: getIt<DeleteWorkTypeUseCase>(),
    ),
  );
  
  // ========== BOOKINGS ==========
  // Data Sources
  getIt.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt<BookingRemoteDataSource>()),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetBookingsUseCase(getIt<BookingRepository>()));
  getIt.registerLazySingleton(() => GetBookingByIdUseCase(getIt<BookingRepository>()));
  getIt.registerLazySingleton(() => UpdateBookingStatusUseCase(getIt<BookingRepository>()));
  
  // BLoCs
  getIt.registerFactory(
    () => BookingBloc(
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      updateBookingStatusUseCase: getIt<UpdateBookingStatusUseCase>(),
    ),
  );
  
  // ========== DASHBOARD ==========
  getIt.registerFactory(
    () => DashboardBloc(
      getBookingsUseCase: getIt<GetBookingsUseCase>(),
      getWorkersUseCase: getIt<GetWorkersUseCase>(),
    ),
  );

  // ========== NOTIFICATIONS ==========
  getIt.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<NotificationSignalRDataSource>(
    () => NotificationSignalRDataSourceImpl(),
  );
  getIt.registerLazySingleton(
    () => NotificationRealtimeService(getIt<NotificationSignalRDataSource>()),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: getIt<NotificationRemoteDataSource>(),
      realtimeService: getIt<NotificationRealtimeService>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetNotificationsUseCase(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetUnreadCountUseCase(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => MarkNotificationReadUseCase(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => MarkAllNotificationsReadUseCase(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => SubscribeToNotificationsUseCase(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton(
    () => BookingRealtimeCubit(
      getBookingByIdUseCase: getIt<GetBookingByIdUseCase>(),
    ),
  );
  getIt.registerLazySingleton(
    () => NotificationsCubit(
      getNotificationsUseCase: getIt<GetNotificationsUseCase>(),
      getUnreadCountUseCase: getIt<GetUnreadCountUseCase>(),
      markNotificationReadUseCase: getIt<MarkNotificationReadUseCase>(),
      markAllNotificationsReadUseCase: getIt<MarkAllNotificationsReadUseCase>(),
      subscribeToNotificationsUseCase: getIt<SubscribeToNotificationsUseCase>(),
      bookingRealtimeCubit: getIt<BookingRealtimeCubit>(),
    ),
  );

  // ========== WORKER REVIEWS ==========
  getIt.registerLazySingleton<WorkerReviewsRemoteDataSource>(
    () => WorkerReviewsRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<WorkerReviewsRepository>(
    () => WorkerReviewsRepositoryImpl(getIt<WorkerReviewsRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetCompanyRatingSummaryUseCase(getIt<WorkerReviewsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCompanyWorkerSummariesUseCase(getIt<WorkerReviewsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkerRatingSummaryUseCase(getIt<WorkerReviewsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetWorkerReviewsUseCase(getIt<WorkerReviewsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetReviewByIdUseCase(getIt<WorkerReviewsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCompanyWorkersWithRatingsUseCase(
      reviewsRepository: getIt<WorkerReviewsRepository>(),
      workerRepository: getIt<WorkerRepository>(),
    ),
  );
  getIt.registerFactory(
    () => CompanyRatingsCubit(
      getCompanyWorkersWithRatingsUseCase:
          getIt<GetCompanyWorkersWithRatingsUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => WorkerReviewsCubit(
      getWorkerRatingSummaryUseCase: getIt<GetWorkerRatingSummaryUseCase>(),
      getWorkerReviewsUseCase: getIt<GetWorkerReviewsUseCase>(),
    ),
  );

  // ========== BOOKING REPORTS ==========
  getIt.registerLazySingleton<BookingReportRemoteDataSource>(
    () => BookingReportRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BookingReportRepository>(
    () => BookingReportRepositoryImpl(getIt<BookingReportRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetCompanyBookingReportsUseCase(getIt<BookingReportRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetBookingReportByIdUseCase(getIt<BookingReportRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateBookingReportStatusUseCase(getIt<BookingReportRepository>()),
  );
  getIt.registerFactory(
    () => CompanyBookingReportsCubit(
      getCompanyBookingReportsUseCase: getIt<GetCompanyBookingReportsUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => BookingReportDetailCubit(
      getBookingReportByIdUseCase: getIt<GetBookingReportByIdUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => UpdateBookingReportStatusCubit(
      updateBookingReportStatusUseCase:
          getIt<UpdateBookingReportStatusUseCase>(),
    ),
  );
}
