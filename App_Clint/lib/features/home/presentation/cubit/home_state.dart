import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/city.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../domain/entities/maid.dart';

/// Home screen states
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<Maid> availableMaids;
  final List<Maid> topRatedMaids;
  final List<City> cities;
  final City? selectedCity;
  final DateTime? selectedBookingDate;
  final DateTime lastUpdateTime;
  final bool isRefreshingWorkers;
  final bool isLoadingMoreAvailable;
  final bool availableHasNextPage;
  final int availablePage;
  final bool isLoadingMoreTopRated;
  final bool topRatedHasNextPage;
  final int topRatedPage;
  final Booking? ongoingBooking;

  const HomeLoaded({
    required this.availableMaids,
    required this.topRatedMaids,
    required this.cities,
    required this.selectedCity,
    this.selectedBookingDate,
    required this.lastUpdateTime,
    this.isRefreshingWorkers = false,
    this.isLoadingMoreAvailable = false,
    this.availableHasNextPage = false,
    this.availablePage = 1,
    this.isLoadingMoreTopRated = false,
    this.topRatedHasNextPage = false,
    this.topRatedPage = 1,
    this.ongoingBooking,
  });

  List<Maid> get filteredAvailableMaids =>
      HomeCityFilter.filterMaids(availableMaids, selectedCity);

  List<Maid> get filteredTopRatedMaids =>
      HomeCityFilter.filterMaids(topRatedMaids, selectedCity);

  String get selectedCityLabel =>
      selectedCity?.name ?? HomeCityFilter.allCitiesLabel;

  HomeLoaded copyWith({
    List<Maid>? availableMaids,
    List<Maid>? topRatedMaids,
    List<City>? cities,
    City? selectedCity,
    bool clearSelectedCity = false,
    DateTime? selectedBookingDate,
    bool clearSelectedBookingDate = false,
    DateTime? lastUpdateTime,
    bool? isRefreshingWorkers,
    bool? isLoadingMoreAvailable,
    bool? availableHasNextPage,
    int? availablePage,
    bool? isLoadingMoreTopRated,
    bool? topRatedHasNextPage,
    int? topRatedPage,
    Booking? ongoingBooking,
    bool clearOngoingBooking = false,
  }) {
    return HomeLoaded(
      availableMaids: availableMaids ?? this.availableMaids,
      topRatedMaids: topRatedMaids ?? this.topRatedMaids,
      cities: cities ?? this.cities,
      selectedCity:
          clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      selectedBookingDate: clearSelectedBookingDate
          ? null
          : (selectedBookingDate ?? this.selectedBookingDate),
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isRefreshingWorkers: isRefreshingWorkers ?? this.isRefreshingWorkers,
      isLoadingMoreAvailable:
          isLoadingMoreAvailable ?? this.isLoadingMoreAvailable,
      availableHasNextPage:
          availableHasNextPage ?? this.availableHasNextPage,
      availablePage: availablePage ?? this.availablePage,
      isLoadingMoreTopRated:
          isLoadingMoreTopRated ?? this.isLoadingMoreTopRated,
      topRatedHasNextPage: topRatedHasNextPage ?? this.topRatedHasNextPage,
      topRatedPage: topRatedPage ?? this.topRatedPage,
      ongoingBooking:
          clearOngoingBooking
              ? null
              : (ongoingBooking ?? this.ongoingBooking),
    );
  }

  @override
  List<Object?> get props => [
        availableMaids,
        topRatedMaids,
        cities,
        selectedCity,
        selectedBookingDate,
        lastUpdateTime,
        isRefreshingWorkers,
        isLoadingMoreAvailable,
        availableHasNextPage,
        availablePage,
        isLoadingMoreTopRated,
        topRatedHasNextPage,
        topRatedPage,
        ongoingBooking,
      ];
}

class HomeCityFilter {
  HomeCityFilter._();

  static const String allCitiesLabel = 'All cities';

  static List<Maid> filterMaids(List<Maid> maids, City? city) {
    if (city == null) return maids;
    final cityName = city.name.trim().toLowerCase();
    if (cityName.isEmpty) return maids;

    return maids.where((maid) {
      final location = (maid.companyLocation ?? '').trim().toLowerCase();
      if (location.isEmpty) return false;
      return location == cityName || location.contains(cityName);
    }).toList();
  }

  static City? defaultCityFromList(List<City> cities) {
    if (cities.isEmpty) return null;
    const preferredNames = ['tripoli', 'طرابلس'];
    for (final preferred in preferredNames) {
      for (final city in cities) {
        if (city.name.trim().toLowerCase() == preferred) {
          return city;
        }
      }
    }
    return cities.first;
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
