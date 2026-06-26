class RateWorkerArgs {
  const RateWorkerArgs({
    required this.bookingId,
    required this.workerId,
    required this.workerName,
    required this.companyId,
    this.companyName,
  });

  final int bookingId;
  final int workerId;
  final String workerName;
  final int companyId;
  final String? companyName;
}
