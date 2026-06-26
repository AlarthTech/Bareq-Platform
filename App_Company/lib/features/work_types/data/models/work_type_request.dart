class WorkTypeRequestBuilder {
  static Map<String, dynamic> toCreateJson({
    required int companyId,
    required String name,
    required bool isMonthly,
    required double price,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) {
    final body = <String, dynamic>{
      'name': name,
      'companyId': companyId,
      'isMonthly': isMonthly,
    };
    if (isMonthly) {
      body['price'] = price;
    } else {
      body['price'] = price;
      body['startTime'] = startTime;
      body['endTime'] = endTime;
      body['isOvernight'] = isOvernight;
    }
    return body;
  }

  static Map<String, dynamic> toUpdateJson({
    required String name,
    required bool isMonthly,
    required double price,
    required bool isActive,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) {
    final body = <String, dynamic>{
      'name': name,
      'isMonthly': isMonthly,
      'isActive': isActive,
    };
    if (isMonthly) {
      body['price'] = price;
      body['monthlyPrice'] = price;
    } else {
      body['price'] = price;
      body['startTime'] = startTime;
      body['endTime'] = endTime;
      body['isOvernight'] = isOvernight;
    }
    return body;
  }
}
