class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String avatar;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatar,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      avatar: json['avatar'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatar': avatar,
      'is_verified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatar,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
