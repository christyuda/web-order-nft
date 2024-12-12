class DeleteNoteResponse {
  final bool status;
  final String message;

  DeleteNoteResponse({
    required this.status,
    required this.message,
  });

  factory DeleteNoteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteNoteResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}
