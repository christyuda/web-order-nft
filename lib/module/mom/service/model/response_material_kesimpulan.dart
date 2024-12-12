class MaterialResponse {
  final bool status;
  final String message;
  final dynamic data;

  MaterialResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory MaterialResponse.fromJson(Map<String, dynamic> json) {
    return MaterialResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'], // This is null based on the response
    );
  }
}
