class UpdateDueDateResponse {
  final String message;

  UpdateDueDateResponse({required this.message});

  factory UpdateDueDateResponse.fromJson(Map<String, dynamic> json) {
    return UpdateDueDateResponse(
      message: json['message'] ?? 'No message provided',
    );
  }
}
