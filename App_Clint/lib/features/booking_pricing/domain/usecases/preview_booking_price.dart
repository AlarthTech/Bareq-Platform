import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking_price_breakdown.dart';
import '../entities/booking_price_preview_params.dart';
import '../repositories/booking_pricing_repository.dart';

class PreviewBookingPrice {
  PreviewBookingPrice(this._repository);

  final BookingPricingRepository _repository;

  Future<Either<Failure, BookingPriceBreakdown>> call(
    BookingPricePreviewParams params,
  ) =>
      _repository.previewPrice(params);
}
