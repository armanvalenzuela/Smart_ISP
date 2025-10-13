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
    final Map<String, String> status = {};
    final Map<String, String> collector = {};
    final Map<String, dynamic> payments = {};

    json.forEach((key, value) {
      if (key.startsWith("Status_")) status[key] = value ?? '';
      if (key.startsWith("Collector_")) collector[key] = value ?? '';
      if (key.startsWith("AmountPaid_")) payments[key] = value;
    });

    return ClientModel(
      name: json["Name"],
      phone: json["Phone"].toString(),
      wifiId: json["WiFi_ID"],
      town: json["Town"],
      latitude: double.tryParse(json["Latitude"].toString()) ?? 0,
      longitude: double.tryParse(json["Longitude"].toString()) ?? 0,
      note: json["Note"],
      planSpeed: json["Plan_Speed"],
      planAmount: int.tryParse(json["Plan_Amount"].toString()) ?? 0,
      promoDiscount: int.tryParse(json["Promo_Discount"].toString()) ?? 0,
      promoRemarks: json["Promo_Remarks"],
      startYear: int.tryParse(json["Start_Year"].toString()) ?? 0,
      startMonth: int.tryParse(json["Start_Month"].toString()) ?? 0,
      connectionStatus: json["Connection_Status"],
      isActive: json["Active"] == "Yes",
      monthlyStatus: status,
      collectors: collector,
      payments: payments,
    );
  }
  
}
