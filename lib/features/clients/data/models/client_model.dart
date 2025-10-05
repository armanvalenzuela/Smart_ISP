class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String status; // Paid / Unpaid
  final int distance;
  final String? plan;
  final String? remarks;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.distance,
    this.plan,
    this.remarks,
  });
}