class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role; // 'customer' or 'driver'
  final String? profilePhoto;
  final bool isKycVerified;
  final String vehicleType; // for drivers (e.g., 'EV Scooter', 'Bike')
  final String vehicleNumber;
  final double rating;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.profilePhoto,
    this.isKycVerified = true,
    this.vehicleType = 'EV Scooter',
    this.vehicleNumber = 'KA-05-PZ-9988',
    this.rating = 4.9,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ??
          json['customerId']?.toString() ??
          json['userId']?.toString() ??
          json['driverId']?.toString() ??
          '',
      name: json['name']?.toString() ??
          json['fullName']?.toString() ??
          json['userName']?.toString() ??
          json['customerName']?.toString() ??
          'Customer',
      phone: json['phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['mobile']?.toString() ??
          '',
      email: json['email']?.toString() ??
          json['emailAddress']?.toString() ??
          'customer@pingzo.com',
      role: json['role']?.toString().toLowerCase() ?? 'customer',
      profilePhoto: json['profilePhoto']?.toString() ?? json['avatar']?.toString() ?? json['image']?.toString(),
      isKycVerified: json['isKycVerified'] == true || json['kycVerified'] == true || json['verified'] == true,
      vehicleType: json['vehicleType']?.toString() ?? 'EV Scooter',
      vehicleNumber: json['vehicleNumber']?.toString() ?? json['vehicleNo']?.toString() ?? 'KA-05-PZ-9988',
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'profilePhoto': profilePhoto,
      'isKycVerified': isKycVerified,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
    };
  }
}
