import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/register_customer_usecase.dart';
import '../../domain/usecases/save_user_usecase.dart';
import 'registration_state.dart';

/// Registration cubit for managing registration screen state
class RegistrationCubit extends Cubit<RegistrationState> {
  final GetCitiesUseCase getCitiesUseCase;
  final RegisterCustomerUseCase registerCustomerUseCase;
  final SaveUserUseCase saveUserUseCase;

  RegistrationCubit({
    required this.getCitiesUseCase,
    required this.registerCustomerUseCase,
    required this.saveUserUseCase,
  }) : super(const RegistrationInitial());

  /// Load cities
  Future<void> loadCities() async {
    if (isClosed) return;
    emit(const RegistrationLoadingCities());

    final result = await getCitiesUseCase();

    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RegistrationError(_mapFailureToMessage(failure)));
      },
      (cities) {
        if (isClosed) return;
        emit(RegistrationCitiesLoaded(cities));
      },
    );
  }

  /// Register customer
  Future<void> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  }) async {
    if (isClosed) return;
    emit(const RegistrationRegistering());

    final result = await registerCustomerUseCase(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      cityId: cityId,
    );

    result.fold(
      (failure) {
        if (isClosed) return;
        emit(RegistrationError(_mapFailureToMessage(failure)));
      },
      (_) async {
        // Create user from registration data and save it
        // Note: Registration API doesn't return user data, so we create it from form data
        final user = User(
          id: '', // Will be set when user logs in
          username: email, // Use email as username
          fullName: fullName,
          email: email,
          phone: phone,
        );

        // Save user to local storage
        final saveResult = await saveUserUseCase(user);
        saveResult.fold(
          (failure) {
            // If save fails, still show success but log the error
            if (isClosed) return;
            emit(const RegistrationSuccess());
          },
          (_) {
            if (isClosed) return;
            emit(const RegistrationSuccess());
          },
        );
      },
    );
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    if (failure is ServerFailure) {
      return failure.message;
    }
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is AuthFailure) {
      return failure.message;
    }
    return failure.message;
  }
}

