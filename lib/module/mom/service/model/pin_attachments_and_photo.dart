import 'dart:typed_data';

class AddEventPhotosRequest {
  final String idMom;
  final List<String> attachments;
  final List<Uint8List> eventPhotos;

  AddEventPhotosRequest({
    required this.idMom,
    required this.attachments,
    required this.eventPhotos,
  });

  Map<String, String> toFields() {
    return {
      'id_mom': idMom,
      ...attachments
          .asMap()
          .map((index, url) => MapEntry('attachments[$index]', url)),
    };
  }
}
