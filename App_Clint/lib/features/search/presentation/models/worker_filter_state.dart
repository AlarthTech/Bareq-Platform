/// Worker search filter values (presentation layer only).
class WorkerFilterState {
  const WorkerFilterState({
    this.bookingDate,
    this.selectedCity,
    this.minRating = 0,
    this.minExperience = 0,
    this.selectedNationalities = const {},
    this.selectedLanguages = const {},
  });

  final DateTime? bookingDate;
  final String? selectedCity;
  final double minRating;
  final int minExperience;
  final Set<String> selectedNationalities;
  final Set<String> selectedLanguages;

  bool get hasActiveFilters =>
      bookingDate != null ||
      (selectedCity != null && selectedCity!.isNotEmpty) ||
      minRating > 0 ||
      minExperience > 0 ||
      selectedNationalities.isNotEmpty ||
      selectedLanguages.isNotEmpty;

  WorkerFilterState copyWith({
    DateTime? bookingDate,
    bool clearBookingDate = false,
    String? selectedCity,
    bool clearCity = false,
    double? minRating,
    int? minExperience,
    Set<String>? selectedNationalities,
    Set<String>? selectedLanguages,
  }) {
    return WorkerFilterState(
      bookingDate: clearBookingDate ? null : (bookingDate ?? this.bookingDate),
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      minRating: minRating ?? this.minRating,
      minExperience: minExperience ?? this.minExperience,
      selectedNationalities:
          selectedNationalities ?? this.selectedNationalities,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
    );
  }
}
