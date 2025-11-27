class User {
  final String id;
  String name;
  String? mobile;
  String? profileImagePath;
  String? address;

  User({
    required this.id,
    required this.name,
    this.mobile = '',
    this.profileImagePath,
    this.address = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile ?? '',
      'profileImagePath': profileImagePath,
      'address': address,      // ⭐ NEW
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'] ?? '',
      profileImagePath: json['profileImagePath'],
      address: json['address'] ?? '',    // ⭐ NEW
    );
  }
}
