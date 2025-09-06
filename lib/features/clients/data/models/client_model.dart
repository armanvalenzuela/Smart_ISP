class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String status; // Paid / Unpaid
  final String amountdue;
  final String isPaid;
  final String lastPaymentDate;
  final int signalStrength;
  final String isOnline;
  final int rebootCount;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.status,
    required this.amountdue,
    required this.isPaid,
    required this.lastPaymentDate,
    required this.signalStrength,
    required this.isOnline,
    required this.rebootCount,
  });
}