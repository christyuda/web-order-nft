class MaterialRequest {
  final String idMom;
  final String material;
  final List<Note> notes;

  MaterialRequest({
    required this.idMom,
    required this.material,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id_mom': idMom,
        'material': material,
        'notes': notes.map((note) => note.toJson()).toList(),
      };

  static MaterialRequest fromJson(Map<String, dynamic> json) {
    return MaterialRequest(
      idMom: json['id_mom'],
      material: json['material'],
      notes:
          (json['notes'] as List).map((note) => Note.fromJson(note)).toList(),
    );
  }
}

class Note {
  final String note;
  final String pic;
  final String dueDate;

  Note({
    required this.note,
    required this.pic,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'note': note,
        'pic': pic,
        'due_date': dueDate,
      };

  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      note: json['note'],
      pic: json['pic'],
      dueDate: json['due_date'],
    );
  }
}
