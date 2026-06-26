import 'package:equatable/equatable.dart';
import '../../domain/entities/city.dart';

/// Registration screen states
abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RegistrationInitial extends RegistrationState {
  const RegistrationInitial();
}

/// Loading cities state
class RegistrationLoadingCities extends RegistrationState {
  const RegistrationLoadingCities();
}

/// Cities loaded state
class RegistrationCitiesLoaded extends RegistrationState {
  final List<City> cities;

  const RegistrationCitiesLoaded(this.cities);

  @override
  List<Object?> get props => [cities];
}

/// Registering state
class RegistrationRegistering extends RegistrationState {
  const RegistrationRegistering();
}

/// Registration success state
class RegistrationSuccess extends RegistrationState {
  const RegistrationSuccess();
}

/// Error state
class RegistrationError extends RegistrationState {
  final String message;

  const RegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

