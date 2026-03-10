class LoginResponse {
  const LoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final LoginData data;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: LoginData.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class LoginData {
  const LoginData({required this.token, required this.user});

  final String token;
  final LoginUser user;

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: (json['token'] ?? '').toString(),
      user: LoginUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class LoginUser {
  const LoginUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.departmentId,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? departmentId;

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      departmentId: json['department_id']?.toString(),
    );
  }
}
