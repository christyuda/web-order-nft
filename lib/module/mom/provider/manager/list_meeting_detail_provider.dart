import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/module/mom/service/model/pin_attachments_and_photo.dart';
import 'package:webordernft/module/mom/service/model/pin_detailistmeeting.dart';
import 'package:webordernft/module/mom/service/model/pin_material_kesimpulan.dart';
import 'package:webordernft/module/mom/service/model/response_detaillistmeeting.dart';
import 'package:webordernft/module/mom/service/model/response_material_kesimpulan.dart';
import 'package:webordernft/module/mom/service/mom_service.dart';

class MeetingListDetailProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  MeetingData? _meetingData;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MeetingData? get meetingData => _meetingData;
  GlobalKey<FormBuilderState> get formKey => _formKey;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;

    notifyListeners();
  }

  Future<void> fetchMeetingById(BuildContext context, int meetingId) async {
    setLoading(true);
    try {
      GetMeetingByIdRequest request =
          GetMeetingByIdRequest(meetingId: meetingId);
      GetMeetingByIdResponse response =
          await MomService.getMeetingById(context, request);

      if (response.status) {
        _meetingData = response.data;
        _errorMessage = null;
      } else {
        _meetingData = null;
        setErrorMessage(response.message);
      }
    } catch (error) {
      setErrorMessage("An error occurred: ${error.toString()}");
    } finally {
      setLoading(false);
    }
  }

  Future<void> signAudienceOnlineWithQR(
  BuildContext context, {
  required int idMom,
  required int idAudiences,
  required int status,
  required int isPresent,
}) async {
  setLoading(true); // Tampilkan loader jika diperlukan
  try {
    // Persiapkan parameter untuk request
    final params = {
      "id_mom": idMom,
      "id_audiences": idAudiences,
      "status": 3,
      "is_present": isPresent,
    };

    // Panggil service API untuk tanda tangan QR
    final response = await MomService.signAudienceOnlineWithSignature(context, params);

    if (response.status) {
      SnackToastMessage(
        context,
        "Tanda Tangan QR Online berhasil.",
        ToastType.success,
      );
    } else {
      SnackToastMessage(
        context,
        response.message ?? "Gagal melakukan tanda tangan.",
        ToastType.error,
      );
    }
  } catch (error) {
    SnackToastMessage(
      context,
      "Terjadi kesalahan: ${error.toString()}",
      ToastType.error,
    );
  } finally {
    setLoading(false); // Sembunyikan loader
  }
}

}
