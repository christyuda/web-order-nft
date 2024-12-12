import 'dart:convert';

class EmailResponse {
  bool status;
  String message;
  String data;

  EmailResponse({
    required this.status,
    required this.message,
    this.data = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }

  factory EmailResponse.fromMap(Map<String, dynamic> map) {
    return EmailResponse(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: map['data'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory EmailResponse.fromJson(String source) =>
      EmailResponse.fromMap(json.decode(source));
}
