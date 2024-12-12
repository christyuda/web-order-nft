
class UpdatePicRequest {
  final String idMom;
  final String noteId;
  final String pic;

  UpdatePicRequest({
    required this.idMom,
    required this.noteId,
    required this.pic,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_mom': idMom,
      'note_id': noteId,
      'pic': pic,
    };
  }
}
