
class DeleteNoteRequest {
  final String idMom;
  final String noteId;

  DeleteNoteRequest({
    required this.idMom,
    required this.noteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_mom': idMom,
      'note_id': noteId,
    };
  }
}
