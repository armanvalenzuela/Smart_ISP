// 📄 PART 1: client_model.dart

class ClientModel {
  final String name;
  final String phone;
  final String wifiId;
  final String town;
  final double latitude;
  final double longitude;
  final String note;
  final String planSpeed;
  final int planAmount;
  final int promoDiscount;
  final String promoRemarks;
  final int startYear;
  final int startMonth;
  final String connectionStatus;
  final bool isActive;
  final Map<String, String> monthlyStatus;
  final Map<String, String> collectors;
  final Map<String, dynamic> payments;

  ClientModel({
    required this.name,
    required this.phone,
    required this.wifiId,
    required this.town,
    required this.latitude,
    required this.longitude,
    required this.note,
    required this.planSpeed,
    required this.planAmount,
    required this.promoDiscount,
    required this.promoRemarks,
    required this.startYear,
    required this.startMonth,
    required this.connectionStatus,
    required this.isActive,
    required this.monthlyStatus,
    required this.collectors,
    required this.payments,
  });

  /// 🔑 Key for current month (used for status/payment/collector lookup)
  static String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  /// 🟦 Computed: Status for current month (e.g. Paid / Unpaid)
  String get statusThisMonth {
    return monthlyStatus['Status_$_currentMonthKey'] ?? 'Unpaid';
  }

  /// 🟪 Computed: Collector name for current month
  String get collectorThisMonth {
    return collectors['Collector_$_currentMonthKey'] ?? '';
  }

  /// 💰 Computed: Amount Paid this month
  String get amountPaidThisMonth {
    return payments['AmountPaid_$_currentMonthKey']?.toString() ?? '0';
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    // Normalize keys to lowercase for consistency
    final lower = {
      for (var entry in json.entries) entry.key.toLowerCase(): entry.value,
    };

    final Map<String, String> status = {};
    final Map<String, String> collector = {};
    final Map<String, dynamic> payments = {};

    lower.forEach((key, value) {
      if (key.startsWith("status_")) status[key] = value?.toString() ?? '';
      if (key.startsWith("collector_"))
        collector[key] = value?.toString() ?? '';
      if (key.startsWith("amountpaid_")) payments[key] = value;
    });

    return ClientModel(
      name: lower["name"]?.toString() ?? '',
      phone: lower["phone"]?.toString() ?? '',
      wifiId: lower["wifi_id"]?.toString() ?? '',
      town: lower["town"]?.toString() ?? '',
      latitude: double.tryParse(lower["latitude"]?.toString() ?? '') ?? 0,
      longitude: double.tryParse(lower["longitude"]?.toString() ?? '') ?? 0,
      note: lower["note"]?.toString() ?? '',
      planSpeed: lower["plan_speed"]?.toString() ?? '',
      planAmount: int.tryParse(lower["plan_amount"]?.toString() ?? '') ?? 0,
      promoDiscount:
          int.tryParse(lower["promo_discount"]?.toString() ?? '') ?? 0,
      promoRemarks: lower["promo_remarks"]?.toString() ?? '',
      startYear: int.tryParse(lower["start_year"]?.toString() ?? '') ?? 0,
      startMonth: int.tryParse(lower["start_month"]?.toString() ?? '') ?? 0,
      connectionStatus: lower["connection_status"]?.toString() ?? '',
      isActive: lower["active"]?.toString().toLowerCase() == 'yes',
      monthlyStatus: status,
      collectors: collector,
      payments: payments,
    );
  }
}
