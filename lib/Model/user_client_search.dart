class UserClientResponse {
  final List<UserClient> data;

  UserClientResponse({
    required this.data,
  });

  factory UserClientResponse.fromJson(List<dynamic> json) {
    return UserClientResponse(
      data: json.map((item) => UserClient.fromJson(item)).toList(),
    );
  }

  UserClientResponse copyWith({
    List<UserClient>? data,
  }) {
    return UserClientResponse(
      data: data ?? this.data,
    );
  }
}

class UserClient {
  final String? customerIdErp;
  final String? username;

  UserClient({
    this.customerIdErp,
    this.username,
  });

  factory UserClient.fromJson(Map<String, dynamic> json) {
    return UserClient(
      customerIdErp: json['customer_id_erp'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id_erp': customerIdErp,
      'username': username,
    };
  }

  UserClient copyWith({
    String? customerIdErp,
    String? username,
  }) {
    return UserClient(
      customerIdErp: customerIdErp ?? this.customerIdErp,
      username: username ?? this.username,
    );
  }
}
