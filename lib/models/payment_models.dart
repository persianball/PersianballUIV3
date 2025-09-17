// lib/models/payment_models.dart
// Models for payments list API: /v1/payment/payments/

class PaymentsResponse {
  final int count;
  final String? next; // may be absolute URL or null
  final String? previous;
  final List<PaymentItem> results;

  PaymentsResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaymentsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List<dynamic>? ?? [])
        .map((e) => PaymentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaymentsResponse(
      count: json['count'] is int ? json['count'] as int : int.tryParse('${json['count']}') ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: list,
    );
  }
}

class PaymentItem {
  final int id;
  final int? user;
  final String trackingCode; // keep as string to avoid any overflow or formatting issues
  final String status; // e.g., pending | failed | success
  final int price; // in rials/toman based on backend

  PaymentItem({
    required this.id,
    required this.user,
    required this.trackingCode,
    required this.status,
    required this.price,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    // tracking_code in API may be int; convert to string
    final dynamic tc = json['tracking_code'];
    return PaymentItem(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      user: json['user'] == null ? null : (json['user'] is int ? json['user'] as int : int.tryParse('${json['user']}')),
      trackingCode: tc?.toString() ?? '-',
      status: (json['status'] ?? '').toString(),
      price: json['price'] is int
          ? json['price'] as int
          : (json['price'] is double
              ? (json['price'] as double).toInt()
              : int.tryParse('${json['price']}') ?? 0),
    );
  }
}