import 'package:flutter/foundation.dart';

/// Notifies rating widgets to reload after cache invalidation.
class RatingRefreshNotifier extends ChangeNotifier {
  int? _workerId;
  int? _companyId;

  int? get workerId => _workerId;
  int? get companyId => _companyId;

  void notifyWorkerInvalidated(int workerId, {int? companyId}) {
    _workerId = workerId;
    _companyId = companyId;
    notifyListeners();
  }

  void notifyCompanyInvalidated(int companyId) {
    _companyId = companyId;
    _workerId = null;
    notifyListeners();
  }
}
