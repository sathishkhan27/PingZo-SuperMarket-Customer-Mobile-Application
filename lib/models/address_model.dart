class AddressModel {
  final String id;
  final String customerId;
  final String type;
  final String distance;
  final String addressDetails;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.distance,
    required this.addressDetails,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '1',
      type: json['type'] ?? 'Home',
      distance: json['distance'] ?? '0 m',
      addressDetails: json['addressDetails'] ?? '',
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'customerId': customerId,
      'type': type,
      'distance': distance,
      'addressDetails': addressDetails,
      'isDefault': isDefault,
    };
  }
}
