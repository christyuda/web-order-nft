class UpdatePicResponse {
  final String message;

  UpdatePicResponse({
    required this.message,
  });

  factory UpdatePicResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePicResponse(
      message: json['message'] ?? '',
    );
  }
}
