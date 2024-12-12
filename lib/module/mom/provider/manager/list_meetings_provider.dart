import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webordernft/module/login/provider/login_provider.dart';
import 'package:webordernft/module/mom/provider/manager/list_meeting_detail_provider.dart';
import 'package:webordernft/module/mom/service/model/list_audiences_request.dart';
import 'package:webordernft/module/mom/service/model/list_audiences_response.dart';
import 'package:webordernft/module/mom/service/model/pin_ticketing_absen.dart';
import 'package:webordernft/module/mom/service/model/pin_validate_ticketing.dart';
import 'package:webordernft/module/mom/service/model/response_ticketing_absen.dart';
import 'package:webordernft/module/mom/service/model/response_validate_ticketing.dart';
import 'package:webordernft/module/mom/service/model/send_mail_request.dart';
import 'package:webordernft/module/mom/service/model/send_mail_response.dart';
import 'package:webordernft/module/mom/service/model/sign_audiences_request.dart';
import 'package:webordernft/module/mom/service/mom_service.dart';

class ListMeetingsProvider with ChangeNotifier {
  // Private variables
  List<Audience> _audiences = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _ticketingId;
  String? _validationToken;
  int? _meetingId;
  int? _audienceId;
  String? _email;
  EmailResponse? get response => _response;
  EmailResponse? _response;
  // Public getters
  List<Audience> get audiences => _audiences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get ticketingId => _ticketingId;
  String? get validationToken => _validationToken;
  int? get meetingId => _meetingId;
  int? get audienceId => _audienceId;
  String? get email => _email;

  // Public setters
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  set email(String? email) {
    _email = email;
    notifyListeners();
  }

  void setTicketingId(String? id) {
    _ticketingId = id;
    notifyListeners();
  }

  void setValidationToken(String? token) {
    _validationToken = token;
    notifyListeners();
  }

  void setMeetingId(int? id) {
    _meetingId = id;
    notifyListeners();
  }

  void setAudienceId(int? id) {
    _audienceId = id;
    notifyListeners();
  }

  // Fetch audiences by meeting ID
  Future<void> fetchListAudiences(BuildContext context, int meetingId) async {
    setLoading(true);

    try {
      final request = ListAudiencesRequest(meetingId: meetingId);

      ListAudiencesResponse? response =
          await MomService.getAllAudiencesByMeetingId(
              context, request.toJson());

      if (response != null && response.status) {
        _audiences = response.data;
      } else {
        _audiences = [];
      }
    } catch (error) {
      setErrorMessage('Error fetching audiences: $error');
      _audiences = [];
    } finally {
      setLoading(false);
    }
  }

  // Update audience status
  void updateAudienceStatus(int audienceId, int status) {
    int index = _audiences.indexWhere((a) => a.audienceId == audienceId);

    if (index != -1) {
      _audiences[index].status = status;
      notifyListeners();
    }
  }

  // Generate ticket for an audience
  Future<void> generateTicket({
    required BuildContext context,
    required int meetingId,
    required int audienceId,
  }) async {
    setLoading(true);

    try {
      PinTicketingAbsenRequest request = PinTicketingAbsenRequest(
        meetingId: meetingId,
        audienceId: audienceId,
      );

      PinTicketingAbsenResponse response =
          await MomService.generateTicket(context, request);

      if (response.status) {
        setTicketingId(response.data.ticketing);
        setErrorMessage(null);
      } else {
        setErrorMessage(response.message);
      }
    } catch (e) {
      setErrorMessage("An error occurred: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

  // Validate ticket
  Future<void> validateTicket(BuildContext context, String ticketing) async {
    setLoading(true);

    try {
      PinValidateTicketingRequest request =
          PinValidateTicketingRequest(ticketing: ticketing);

      ResponseValidateTicketing response =
          await MomService.validateTicket(context, request);

      if (response.status) {
        setMeetingId(response.data.meetingId);
        setAudienceId(response.data.audienceId ?? 0);
        setValidationToken(response.data.token);
        setErrorMessage(null);
      } else {
        setErrorMessage(response.message);
      }
    } catch (e) {
      setErrorMessage("An error occurred: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

  Future<void> signAudience({
    required BuildContext context,
    required int meetingId,
    required int audienceId,
    required int status,
    required Uint8List signatureData,
    required int isPresent,
  }) async {
    setLoading(true);

    SignAudienceRequest request = SignAudienceRequest(
      meetingId: meetingId,
      audienceId: audienceId,
      status: status,
      signatureData: signatureData,
      isPresent: isPresent,
    );

    try {
      var signAudienceResponse =
          await MomService.signAudience(context, request);

      if (signAudienceResponse == null) {
        setErrorMessage("Failed to sign audience.");
      } else {
        setErrorMessage(null);
        updateAudienceStatus(audienceId, status);
      }
    } catch (e) {
      setErrorMessage("An error occurred: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

   signAudienceOnline({
    required BuildContext context,
    required int meetingId,
    required int audienceId,
    required int status,
    // required Uint8List signatureData,
    required int isPresent,
  }) async {
    setLoading(true);
    print('signAudienceOnline');
    SignAudienceRequest request = SignAudienceRequest(
      meetingId: meetingId,
      audienceId: audienceId,
      status: status,
      // signatureData: signatureData,
      isPresent: isPresent,
    );

    try {
      print('signAudienceOnline sedang mengirim ke service');
      var signAudienceResponse =
          await MomService.signAudienceOnlineWithSignature(context, request);
      print(signAudienceResponse); 
      if (signAudienceResponse == null) {
          print('signAudienceOnline gagal');
        setErrorMessage("Failed to sign audience.");
      } else {
        setErrorMessage(null);
        updateAudienceStatus(audienceId, status);
      }
    } catch (e) {
      setErrorMessage("An error occurred: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

  Future<void> sendMail(BuildContext context, EmailRequest request) async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      _response = await MomService.sendMail(context, request);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Sign audience online
  // Future<void> signAudienceOnline({
  //   required BuildContext context,
  //   required int meetingId,
  //   required int audienceId,
  //   required int status,
  //   required Uint8List signatureData,
  //   required int isPresent,
  // }) async {
  //   setLoading(true);

  //   try {
  //     // final loginProvider = Provider.of<LoginProvider>(context, listen: false);

  //     // if (loginProvider.token == null || loginProvider.token!.isEmpty) {
  //     //   await loginProvider.loginWithPresetCredentials(context);
  //     // }
  //     setValidationToken('token');

  //     final token = validationToken!;

  //     if (token == null || token.isEmpty) {
  //       throw Exception(
  //           "Authentication token is missing. Please log in again.");
  //     }
  //     SignAudienceRequest request = SignAudienceRequest(
  //       meetingId: meetingId,
  //       audienceId: audienceId,
  //       status: status,
  //       signatureData: signatureData,
  //       isPresent: isPresent,
  //     );

  //     // Pass the token to the MomService
  //     var signAudienceResponse =
  //         await MomService.signAudienceOnline(context, request, token!);

  //     if (signAudienceResponse == null) {
  //       setErrorMessage("Failed to sign audience.");
  //     } else {
  //       setErrorMessage(null);
  //       updateAudienceStatus(audienceId, status);
  //     }
  //   } catch (e) {
  //     setErrorMessage("An error occurred: ${e.toString()}");
  //   } finally {
  //     setLoading(false);
  //   }
  // }


  Future<void> signInWithQR(
    BuildContext context, {
    required MeetingListDetailProvider meetingDetailsProvider,
  }) async {
    try {
      if (validationToken == null) {
        throw Exception("Authentication token is missing. Please log in again.");
      }

      if (meetingId == null || audienceId == null) {
        throw Exception(
            "Meeting ID atau Audience ID tidak ditemukan. Validasi Token terlebih dahulu.");
      }

      // Ambil data audience berdasarkan audienceId dari listMeetingDetails
      final audience = meetingDetailsProvider.meetingData?.audiences.firstWhere(
        (aud) => aud.id == audienceId,
        orElse: () => throw Exception(
            "Audience dengan ID $audienceId tidak ditemukan."),
      );

      if (audience == null) {
        throw Exception("Data audience tidak ditemukan.");
      }

      print("Debug: Data Audience -> $audience");

      // Generate QR Code dengan data audience
      Uint8List? qrImage = await _generateQrImage(
        name: audience.name ?? "Unknown",
        nik: audience.nik ?? "N/A",
        position: audience.position ?? "N/A",
        stakeholder: audience.stakeholder ?? "N/A",
      );

      print("Debug: QR Image -> $qrImage");

      if (qrImage != null) {
        print("Debug: Sending QR Signature...");
        await signAudienceOnline(
          context: context,
          meetingId: meetingId!,
          audienceId: audienceId!,
          status: 3, // Status untuk tanda tangan QR Online
          // signatureData: qrImage,
          isPresent: 1,
        );

        print("Debug: QR Signature sent successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Tanda Tangan berhasil dikirim!')),
        );
      } else {
        throw Exception("Gagal menghasilkan QR Code.");
      }
    } catch (e) {
      print("Debug: Error occurred -> $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helper untuk generate QR image
  Future<Uint8List?> _generateQrImage({
    required String name,
    required String nik,
    required String position,
    required String stakeholder,
  }) async {
    String currentDate =
        DateFormat('dd-MM-yyyy', 'id_ID').format(DateTime.now());
    String qrData = """
      --- Tanda Tangan QR ---
      Nama       : $name
      NIK        : $nik
      Posisi     : $position
      Stakeholder: $stakeholder
      Status     : Tertandatangani
      Tanggal    : $currentDate
      """;

    final qrCodePainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
      color: const Color(0xFF000000),
    );

    final ui.Image image = await qrCodePainter.toImage(300);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
