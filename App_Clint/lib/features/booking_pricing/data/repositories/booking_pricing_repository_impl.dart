import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/booking_price_breakdown.dart';
import '../../domain/entities/booking_price_preview_params.dart';
import '../../domain/repositories/booking_pricing_repository.dart';
import '../datasources/booking_pricing_remote_datasource.dart';
import '../models/booking_price_preview_request_model.dart';

class BookingPricingRepositoryImpl implements BookingPricingRepository {
  BookingPricingRepositoryImpl(this._remote);

  final BookingPricingRemoteDataSource _remote;

  @override
  Future<Either<Failure, BookingPriceBreakdown>> previewPrice(
    BookingPricePreviewParams params,
  ) async {
    try {
      final model = await _remote.previewPrice(
        BookingPricePreviewRequestModel(
          companyId: params.companyId,
          workerId: params.workerId,
          workTypeId: params.workTypeId,
          bookingDate: params.bookingDate,
          startDate: params.startDate,
          endDate: params.endDate,
          isMonthly: params.isMonthly,
        ),
      );
      return Right(model.toEntity());
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
