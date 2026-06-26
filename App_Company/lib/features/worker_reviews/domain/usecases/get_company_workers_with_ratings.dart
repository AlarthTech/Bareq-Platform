import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../workers/domain/entities/worker_entity.dart';
import '../../../workers/domain/repositories/worker_repository.dart';
import '../entities/company_rating_summary.dart';
import '../entities/worker_rating_row.dart';
import '../entities/worker_rating_summary.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CompanyWorkersWithRatings extends Equatable {
  const CompanyWorkersWithRatings({
    required this.companySummary,
    required this.rows,
  });

  final CompanyRatingSummary companySummary;
  final List<WorkerRatingRow> rows;

  @override
  List<Object?> get props => [companySummary, rows];
}

class GetCompanyWorkersWithRatingsUseCase {
  GetCompanyWorkersWithRatingsUseCase({
    required WorkerReviewsRepository reviewsRepository,
    required WorkerRepository workerRepository,
  })  : _reviewsRepository = reviewsRepository,
        _workerRepository = workerRepository;

  final WorkerReviewsRepository _reviewsRepository;
  final WorkerRepository _workerRepository;

  Future<Either<Failure, CompanyWorkersWithRatings>> call(int companyId) async {
    final results = await Future.wait([
      _reviewsRepository.getCompanyRatingSummary(companyId),
      _reviewsRepository.getCompanyWorkerSummaries(companyId),
      _workerRepository.getWorkersByCompany(
        companyId,
        pagination: const PaginationParams(page: 1, pageSize: 100),
      ),
    ]);

    final summaryResult = results[0] as Either<Failure, CompanyRatingSummary>;
    final summariesResult =
        results[1] as Either<Failure, List<WorkerRatingSummary>>;
    final workersResult =
        results[2] as Either<Failure, PagedResult<WorkerEntity>>;

    return summaryResult.fold(
      Left.new,
      (summary) => summariesResult.fold(
        Left.new,
        (summaries) => workersResult.fold(
          Left.new,
          (workersPage) {
            final summariesByWorker = {
              for (final s in summaries) s.workerId: s,
            };

            final rows = workersPage.items
                .map(
                  (worker) => WorkerRatingRow(
                    worker: worker,
                    summary: summariesByWorker[worker.id],
                  ),
                )
                .toList();

            rows.sort((a, b) {
              final aRated = a.hasReviews;
              final bRated = b.hasReviews;
              if (aRated && !bRated) return -1;
              if (!aRated && bRated) return 1;
              if (aRated && bRated) {
                return b.summary!.averageRating
                    .compareTo(a.summary!.averageRating);
              }
              return a.worker.fullName.compareTo(b.worker.fullName);
            });

            return Right(
              CompanyWorkersWithRatings(
                companySummary: summary,
                rows: rows,
              ),
            );
          },
        ),
      ),
    );
  }
}
