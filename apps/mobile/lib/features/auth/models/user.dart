class AppUser {
  final String id;
  final String phone;
  final String name;
  final String? avatarUrl;
  final String? city;
  final String role;
  final int completedDealCount;
  final double responseRate;

  const AppUser({
    required this.id,
    required this.phone,
    required this.name,
    this.avatarUrl,
    this.city,
    required this.role,
    required this.completedDealCount,
    required this.responseRate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        city: json['city'] as String?,
        role: json['role'] as String,
        completedDealCount: json['completedDealCount'] as int? ?? 0,
        responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'avatarUrl': avatarUrl,
        'city': city,
        'role': role,
        'completedDealCount': completedDealCount,
        'responseRate': responseRate,
      };
}
