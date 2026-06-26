import '../../domain/entities/rating_summary.dart';

/// Session-scoped cache for rating summary endpoints.
class RatingCache {
  final Map<int, WorkerRatingSummary> _workerSummaries = {};
  final Map<int, CompanyRatingSummary> _companySummaries = {};
  final Map<int, List<WorkerRatingSummary>> _companyWorkerSummaries = {};
  final Map<int, DateTime> _workerFetchedAt = {};
  static const _workerTtl = Duration(minutes: 5);

  WorkerRatingSummary? getWorker(int workerId) {
    final cached = _workerSummaries[workerId];
    if (cached == null) return null;
    final fetchedAt = _workerFetchedAt[workerId];
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > _workerTtl) {
      _workerSummaries.remove(workerId);
      _workerFetchedAt.remove(workerId);
      return null;
    }
    return cached;
  }

  CompanyRatingSummary? getCompany(int companyId) =>
      _companySummaries[companyId];

  List<WorkerRatingSummary>? getCompanyWorkers(int companyId) =>
      _companyWorkerSummaries[companyId];

  void putWorker(WorkerRatingSummary summary) {
    _workerSummaries[summary.workerId] = summary;
    _workerFetchedAt[summary.workerId] = DateTime.now();
  }

  void putCompany(CompanyRatingSummary summary) {
    _companySummaries[summary.companyId] = summary;
  }

  void putCompanyWorkers(int companyId, List<WorkerRatingSummary> summaries) {
    _companyWorkerSummaries[companyId] = summaries;
  }

  void invalidateWorker(int workerId) {
    _workerSummaries.remove(workerId);
    _workerFetchedAt.remove(workerId);
  }

  void invalidateCompany(int companyId) {
    _companySummaries.remove(companyId);
    _companyWorkerSummaries.remove(companyId);
  }
}
