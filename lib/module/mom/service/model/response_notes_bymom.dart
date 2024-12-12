class AddNoteResponse {
  final String message;
  final String noteId;

  AddNoteResponse({required this.message, required this.noteId});

  factory AddNoteResponse.fromJson(Map<String, dynamic> json) {
    return AddNoteResponse(
      message: json['message'],
 noteId: json['note_id'].toString(),    
    );
  }
}
