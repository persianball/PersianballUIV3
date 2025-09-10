// lib/models/address_model.dart
class AddressModel {
  final int? id;
  final String postalCode;
  final String address;
  final String? receiverHomePhone;
  final String receiverMobilePhone;
  final String? email;
  final String? addressName;
  final String? city;
  final String? province;
  final bool? defaultAddress;

  AddressModel({
    this.id,
    required this.postalCode,
    required this.address,
    this.receiverHomePhone,
    required this.receiverMobilePhone,
    this.email,
    this.addressName,
    this.city,
    this.province,
    this.defaultAddress,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      postalCode: json['postal_code'] ?? '',
      address: json['address'] ?? '',
      receiverHomePhone: json['receiver_home_phone'],
      receiverMobilePhone: json['receiver_mobile_phone'] ?? '',
      email: json['email'],
      addressName: json['address_name'],
      city: json['city'],
      province: json['province'],
      defaultAddress: json['default_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postal_code': postalCode,
      'address': address,
      'receiver_home_phone': receiverHomePhone,
      'receiver_mobile_phone': receiverMobilePhone,
      'email': email,
      'address_name': addressName,
      'city': city,
      'province': province,
      'default_address': defaultAddress,
    }..removeWhere((key, value) => value == null);
  }
}