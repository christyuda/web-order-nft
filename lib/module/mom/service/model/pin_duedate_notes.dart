class UpdateDueDateRequest {
  final String idMom;
  final String noteId;
  final String dueDate;

  UpdateDueDateRequest({
    required this.idMom,
    required this.noteId,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_mom': idMom,
      'note_id': noteId,
      'due_date': dueDate,
    };
  }
}
