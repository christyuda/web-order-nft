class AddNoteRequest {
  final String idMom;
  final String note;
 

  AddNoteRequest({
    required this.idMom,
    required this.note,
   
  });

  Map<String, dynamic> toJson() {
    return {
      'id_mom': idMom,
      'note': note,
     
    };
  }
}
