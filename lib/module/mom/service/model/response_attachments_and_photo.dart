class AddEventPhotosResponse {
  final String message;

  AddEventPhotosResponse({required this.message});

  factory AddEventPhotosResponse.fromJson(Map<String, dynamic> json) {
    return AddEventPhotosResponse(
      message: json['message'],
    );
  }
}
