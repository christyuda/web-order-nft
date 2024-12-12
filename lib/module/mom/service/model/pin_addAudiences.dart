class PinAddaudiences {
  final String name;
  final String nik;
  final String position;
  final String stakeholder;
  final String signing;
  final int status;
  final String email;

  PinAddaudiences({
    required this.name,
    required this.nik,
    required this.position,
    required this.stakeholder,
    this.signing = '',
    required this.status,
    this.email = '',
  });

  factory PinAddaudiences.fromJson(Map<String, dynamic> json) {
    return PinAddaudiences(
      name: json['name'] ?? '',
      nik: json['nik'] ?? '',
      position: json['position'] ?? '',
      stakeholder: json['stakeholder'] ?? '',
      signing: json['signing'] ?? '',
      status: json['status'] ?? 0,
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nik': nik,
      'position': position,
      'stakeholder': stakeholder,
      'signing': signing,
      'status': status,
      'email': email,
    };
  }
}
