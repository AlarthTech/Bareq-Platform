import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/booking_price_breakdown.dart';
import '../entities/booking_price_preview_params.dart';

abstract class BookingPricingRepository {
  Future<Either<Failure, BookingPriceBreakdown>> previewPrice(
    BookingPricePreviewParams params,
  );
}
