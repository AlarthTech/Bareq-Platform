import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/usecases/get_cities_usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/domain/entities/booking_status_codes.dart';
import '../../../booking/domain/usecases/get_ongoing_bookings_usecase.dart';
import '../../domain/entities/maid.dart';
import '../../domain/usecases/get_available_maids_page_usecase.dart';
import '../../domain/usecases/get_top_rated_maids_page_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const _prefSelectedCityId = 'home_selected_city_id';
  static const int _prefAllCitiesId = -1;

  final GetAvailableMaidsPageUseCase getAvailableMaidsPageUseCase;
  final GetTopRatedMaidsPageUseCase getTopRatedMaidsPageUseCase;
  final GetCitiesUseCase getCitiesUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetOngoingBookingsUseCase getOngoingBookingsUseCase;
  final SharedPreferences sharedPreferences;

  HomeCubit({
    required this.getAvailableMaidsPageUseCase,
    required this.getTopRatedMaidsPageUseCase,
    required this.getCitiesUseCase,
    required this.getCurrentUserUseCase,
    required this.getOngoingBookingsUseCase,
    required this.sharedPreferences,
  }) : super(const HomeInitial());

  Future<void> loadHomeData({
    DateTime? selectedDate,
    bool reloadTopRated = true,
  }) async {
    if (isClosed) return;

    final current = state;
    final isSoftRefresh = current is HomeLoaded;

    if (isSoftRefresh) {
      emit(current.copyWith(isRefreshingWorkers: true));
    } else {
      emit(const HomeLoading());
    }

    try {
      final cities = isSoftRefresh ? current.cities : await _loadCities();
      final savedCity =
          isSoftRefresh ? current.selectedCity : _readSavedCity(cities);

      final availablePage = await getAvailableMaidsPageUseCase(
        selectedDate: selectedDate,
        page: 1,
      );

      final topRatedPage = reloadTopRated || !isSoftRefresh
          ? await getTopRatedMaidsPageUseCase(page: 1)
          : null;

      final ongoingBooking = await _loadPrimaryOngoingBooking();

      if (isClosed) return;
      emit(
        HomeLoaded(
          availableMaids: availablePage.items,
          availablePage: availablePage.page,
          availableHasNextPage: availablePage.hasNextPage,
          topRatedMaids: topRatedPage?.items ??
              (isSoftRefresh ? current.topRatedMaids : const []),
          topRatedPage: topRatedPage?.page ??
              (isSoftRefresh ? current.topRatedPage : 1),
          topRatedHasNextPage: topRatedPage?.hasNextPage ??
              (isSoftRefresh ? current.topRatedHasNextPage : false),
          cities: cities,
          selectedCity: savedCity,
          selectedBookingDate: selectedDate,
          lastUpdateTime: DateTime.now(),
          isRefreshingWorkers: false,
          ongoingBooking: ongoingBooking,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (isSoftRefresh) {
        emit(current.copyWith(isRefreshingWorkers: false));
      } else {
        emit(HomeError(e.toString()));
      }
    }
  }

  Future<void> loadMoreAvailableMaids() async {
    final current = state;
    if (current is! HomeLoaded) return;
    if (current.isLoadingMoreAvailable || !current.availableHasNextPage) {
      return;
    }

    emit(current.copyWith(isLoadingMoreAvailable: true));
    try {
      final nextPage = current.availablePage + 1;
      final paged = await getAvailableMaidsPageUseCase(
        selectedDate: current.selectedBookingDate,
        page: nextPage,
      );
      if (isClosed) return;

      final existingIds = current.availableMaids.map((m) => m.id).toSet();
      final merged = [
        ...current.availableMaids,
        ...paged.items.where((m) => existingIds.add(m.id)),
      ];

      emit(
        current.copyWith(
          availableMaids: merged,
          availablePage: paged.page,
          availableHasNextPage: paged.hasNextPage,
          isLoadingMoreAvailable: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(isLoadingMoreAvailable: false));
    }
  }

  Future<void> loadMoreTopRatedMaids() async {
    final current = state;
    if (current is! HomeLoaded) return;
    if (current.isLoadingMoreTopRated || !current.topRatedHasNextPage) return;

    emit(current.copyWith(isLoadingMoreTopRated: true));
    try {
      final nextPage = current.topRatedPage + 1;
      final paged = await getTopRatedMaidsPageUseCase(page: nextPage);
      if (isClosed) return;

      final existingIds = current.topRatedMaids.map((m) => m.id).toSet();
      final merged = [
        ...current.topRatedMaids,
        ...paged.items.where((m) => existingIds.add(m.id)),
      ];

      emit(
        current.copyWith(
          topRatedMaids: merged,
          topRatedPage: paged.page,
          topRatedHasNextPage: paged.hasNextPage,
          isLoadingMoreTopRated: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(isLoadingMoreTopRated: false));
    }
  }

  void applyBookingStatusUpdate({
    required int bookingId,
    required int statusCode,
  }) {
    final current = state;
    if (current is! HomeLoaded) return;

    final ongoing = current.ongoingBooking;
    if (ongoing == null || ongoing.id != bookingId) return;

    if (!BookingStatusCodes.isOngoing(statusCode)) {
      emit(current.copyWith(clearOngoingBooking: true));
      return;
    }

    emit(
      current.copyWith(
        ongoingBooking: ongoing.copyWith(status: statusCode),
      ),
    );
  }

  Future<Booking?> _loadPrimaryOngoingBooking() async {
    final userResult = await getCurrentUserUseCase();
    return userResult.fold(
      (_) => null,
      (user) async {
        if (user == null) return null;
        final userId = int.tryParse(user.id);
        if (userId == null) return null;

        final bookingsResult = await getOngoingBookingsUseCase(userId);
        return bookingsResult.fold(
          (_) => null,
          (bookings) => bookings.isEmpty ? null : bookings.first,
        );
      },
    );
  }

  Future<List<City>> _loadCities() async {
    final result = await getCitiesUseCase();
    return result.fold(
      (_) => <City>[],
      (cities) => cities.where((c) => c.isActive).toList(),
    );
  }

  City? _readSavedCity(List<City> cities) {
    if (!sharedPreferences.containsKey(_prefSelectedCityId)) {
      return HomeCityFilter.defaultCityFromList(cities);
    }
    final savedId = sharedPreferences.getInt(_prefSelectedCityId);
    if (savedId == null || savedId == _prefAllCitiesId) {
      return null;
    }
    for (final city in cities) {
      if (city.id == savedId) return city;
    }
    return HomeCityFilter.defaultCityFromList(cities);
  }

  Future<void> _persistSelectedCity(City? city) async {
    if (city == null) {
      await sharedPreferences.setInt(_prefSelectedCityId, _prefAllCitiesId);
    } else {
      await sharedPreferences.setInt(_prefSelectedCityId, city.id);
    }
  }

  Future<void> selectCity(City? city) async {
    await _persistSelectedCity(city);
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(selectedCity: city, clearSelectedCity: city == null));
    }
  }

  Future<void> selectAllCities() => selectCity(null);
}
