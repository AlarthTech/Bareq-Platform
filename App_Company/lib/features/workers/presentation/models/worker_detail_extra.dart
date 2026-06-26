import '../../../workers/domain/entities/worker_entity.dart';

class WorkerDetailExtra {
  const WorkerDetailExtra({
    required this.worker,
    this.focusHealthCertificate = false,
  });

  final WorkerEntity worker;
  final bool focusHealthCertificate;
}
