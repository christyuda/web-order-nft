import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webordernft/common/provider/general_provider.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/module/mom/service/model/pin_delete_notes.dart';
import 'package:webordernft/module/mom/service/model/pin_duedate_notes.dart';
import 'package:webordernft/module/mom/service/model/pin_listmom.dart';
import 'package:webordernft/module/mom/service/model/pin_notes_bymom.dart';
import 'package:webordernft/module/mom/service/model/pin_update_pic.dart';
import 'package:webordernft/module/mom/service/model/request_meeting.dart';
import 'package:webordernft/module/mom/service/model/response_delete_notes.dart';
import 'package:webordernft/module/mom/service/model/response_listmom.dart';
import 'package:webordernft/module/mom/service/mom_service.dart';
import 'package:webordernft/module/mom/service/model/pin_addAudiences.dart';

class ListPesertaProvider with ChangeNotifier {
  List<Map<String, dynamic>> _audiences = [];
  List<Map<String, dynamic>> get audiences => _audiences;

  List<Map<String, dynamic>> _finalizedList = [];
  List<Map<String, dynamic>> get finalizedList => _finalizedList;

  List<Map<String, dynamic>> _selectedAudiences = [];
  List<Map<String, dynamic>> get selectedAudiences => _selectedAudiences;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchUserAudiences(
      BuildContext context, int page, int size, String term) async {
    if (term.length < 3) {
      _audiences = [];
      notifyListeners();
      return;
    }

    final generalProv = Provider.of<GeneralProv>(context, listen: false);

    _isLoading = true;
    notifyListeners();

    try {

      UserAudienceRequest param = UserAudienceRequest(
        page: page,
        size: size,
        term: term,
      );

      // Panggil service API
      UserAudienceData result =
          await MomService.getMomServiceList(context, param);

      // Proses hasil response
      if (result.audiences.isNotEmpty) {
        _audiences = result.audiences
            .map((audience) => {
                  'id': audience.id.toString(),
                  'name': audience.name ?? '',
                  'position': audience.position ?? '',
                  'nik': audience.nik ?? '',
                  'stakeholder': audience.stakeholder ?? '',
                })
            .toList();
      } else {
        _audiences = [];
      }

      generalProv.dissmisLoading();
    } catch (e) {
      generalProv.dissmisLoading();
      _audiences = [];
      generalProv.instantSendMessage("Error fetching user audiences: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToSelected(BuildContext context, Map<String, dynamic> participant) {
  if (!_selectedAudiences.any((p) => p['id'] == participant['id'])) {
    _selectedAudiences.add({
      ...participant,
      'name': participant['name'] ?? 'Unknown',
      'representative_signer': 0,
      'isChecked': false, 
    });
    notifyListeners();

    SnackToastMessage(
      context,
      "Peserta berhasil ditambahkan ke daftar terpilih.",
      ToastType.success,
    );
  } else {
    SnackToastMessage(
      context,
      "Peserta sudah ada di daftar terpilih.",
      ToastType.warning,
    );
  }
}



  void removeFromSelected(Map<String, dynamic> participant) {
    _selectedAudiences.removeWhere((p) => p['id'] == participant['id']);
    notifyListeners();
  }
  void updateCheckboxStatus(String id, bool isChecked) {
  final index = _selectedAudiences.indexWhere((p) => p['id'] == id);
  if (index != -1) {
    _selectedAudiences[index]['representative_signer'] = isChecked ? 1 : 0;
    notifyListeners();
  }
}


  
    void clearSelectedAudiences() {
      _selectedAudiences = [];
      notifyListeners();
    }


    Future<void> createMeeting(
    BuildContext context, {
    required String author,
    required String date,
    required String time,
    required String place,
    required String agenda,
    required List<Map<String, dynamic>> notes,
    required String discussionMaterial,
  }) async {
  try {
    // Bangun objek MeetingRequest
    final meetingRequest = MeetingRequest(
      author: author,
      date: date,
      time: time,
      place: place,
      agenda: agenda,
      notes: notes.map((note) {
        return MeetingNote(
          note: note['catatan'] ?? '',
          pic: note['pic'] ?? '',
          dueDate: note['dueDate'] ?? '',
        );
      }).toList(),
      attendees: _selectedAudiences.map((audience) {
        return Attendee(
          name: audience['name'] ?? '',
          nik: audience['nik'] ?? '',
          signing: '',
          status: 0,
          isPresent: audience['isPresent'] ?? 0,
      representativeSigner: audience['representative_signer'] ?? 0,
        );
      }).toList(),
      materials: [
        MaterialDiscuss(material: discussionMaterial),
      ],
    );

    // Panggil API untuk membuat meeting
    final response =
        await MomService.createMeetings(context, meetingRequest.toJson());

    if (response.status) {
      SnackToastMessage(context, "Berhasil Buat Meeting", ToastType.success);
      clearSelectedAudiences(); // Kosongkan daftar peserta terpilih
    } else {
      SnackToastMessage(context, "Gagal Buat Meeting", ToastType.error);
    }
  } catch (e) {
    SnackToastMessage(context, "Gagal Buat Meeting: $e", ToastType.error);
  }
}
Future<void> addUserAudience(
  BuildContext context,
  String name,
  String nik,
  String position,
  String stakeholder,
  String signing,
  int status,
  String email,
) async {
  PinAddaudiences formData = PinAddaudiences(
    name: name,
    nik: nik,
    position: position,
    stakeholder: stakeholder,
    signing: signing,
    status: status,
    email: email,
  );

  try {
    // Panggil service untuk menambahkan peserta
    final UserAudienceData response =
        await MomService.addUserAudience(context, formData);

    if (response.status) {
      SnackToastMessage(
        context,
        response.message ?? "Peserta berhasil ditambahkan.",
        ToastType.success,
      );
      notifyListeners();
    } else {
      SnackToastMessage(
        context,
        response.message ?? "Gagal menambahkan peserta.",
        ToastType.error,
      );
    }
  } catch (e) {
    print('Error adding user audience: $e');
    SnackToastMessage(
      context,
      "Kesalahan saat menambahkan peserta: $e",
      ToastType.error,
    );
  }
}


// void deleteNote(BuildContext context, String idMom, String noteId) async {
//   try {
//     final DeleteNoteRequest request = DeleteNoteRequest(
//       idMom: idMom,
//       noteId: noteId,
//     );

//     DeleteNoteResponse response =
//         await MomService.deleteNoteById(context, request);

//     if (response.status) {
//       print("Note deleted successfully: ${response.message}");
//     } else {
//       print("Failed to delete note: ${response.message}");
//     }
//   } catch (e) {
//     print("Error: $e");
//   }
// }


// Future<void> updateDueDates(
//     BuildContext context, String idMom, String noteId, String dueDate) async {
//   try {
//     final request = UpdateDueDateRequest(
//       idMom: idMom,
//       noteId: noteId,
//       dueDate: dueDate,
//     );

//     final response = await MomService.updateDueDate(context, request);

//     // Cari index dari note di `_finalizedList` berdasarkan `noteId`
//     int index = _finalizedList.indexWhere((note) => note['id'].toString() == noteId);
//     if (index != -1) {
//       // Update due date pada UI
//       _finalizedList[index]['dueDate'] = dueDate;
//       notifyListeners(); // Memastikan UI diperbarui setelah perubahan
//     }

//     print("Success: ${response.message}");
//     SnackToastMessage(
//       context,
//       'Due date updated successfully',
//       ToastType.success,
//     );
//   } catch (e) {
//     print("Error: $e");
//     SnackToastMessage(
//       context,
//       'Failed to update due date: $e',
//       ToastType.error,
//     );
//   }
// }


// Future<void> updatedPIC(
//     BuildContext context, String idMom, String noteId, String pic) async {
//   try {
//     final request = UpdatePicRequest(
//       idMom: idMom,
//       noteId: noteId,
//       pic: pic,
//     );

//     final response = await MomService.updatePic(context, request);

//     // Update UI state (if applicable)
//     int index = _finalizedList.indexWhere((note) => note['id'].toString() == noteId);
//     if (index != -1) {
//       _finalizedList[index]['pic'] = pic;
//       notifyListeners();
//     }

//     print("Success: ${response.message}");
//     SnackToastMessage(
//       context,
//       'PIC updated successfully',
//       ToastType.success,
//     );
//   } catch (e) {
//     print("Error: $e");
//     SnackToastMessage(
//       context,
//       'Failed to update PIC: $e',
//       ToastType.error,
//     );
//   }
// }

// Future<void> addNote(
//       BuildContext context, String idMom, String note) async {
//     try {
//       final request = AddNoteRequest(
//         idMom: idMom,
//         note: note,
//         // pic: pic,
//         // dueDate: dueDate,
//       );

//       final response = await MomService.addNoteByIdMom(context, request);

//       print("Success: ${response.message}");

//       // Tambahkan note ke finalizedList
//       _finalizedList.add({
//       'id': response.noteId.toString(), // Gunakan ID dari backend
//       'catatan': note,
//       'pic': '',
//       'dueDate': '',
//     });

//       notifyListeners();

      
//     } catch (e) {
//       print("Error: $e");

     
//     }
//   }




}

