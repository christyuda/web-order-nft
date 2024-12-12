import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/provider/manager/list_meeting_detail_provider.dart';
import 'package:webordernft/module/mom/provider/manager/list_meetings_provider.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';

class ValidateOnlineSignaturePage extends StatefulWidget {
  @override
  _ValidateOnlineSignaturePageState createState() =>
      _ValidateOnlineSignaturePageState();
}

class _ValidateOnlineSignaturePageState
    extends State<ValidateOnlineSignaturePage> {
  final TextEditingController _ticketController = TextEditingController();
  Uint8List? _pdfBytes; // Holds the generated PDF bytes for preview
  void _validateTicket() async {
    final String ticket = _ticketController.text.trim();

    if (ticket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan Token yang valid')),
      );
      return;
    }

    final provider = Provider.of<ListMeetingsProvider>(context, listen: false);
    final momsProvider = Provider.of<MomsProvider>(context, listen: false);

    try {
      await provider.validateTicket(context, ticket);

      if (provider.meetingId != null) {
        final int meetingId = provider.meetingId!;
        final int audienceId = provider.audienceId!;
        final String token = provider.validationToken!;
        if (provider.audiences.isEmpty ||
            !provider.audiences.any((aud) => aud.audienceId == audienceId)) {
          // Fetch daftar audiens dari backend
          await provider.fetchListAudiences(context, meetingId);
        }
        print("Debug: Meeting ID -> $meetingId");

        var meetingData = momsProvider.getMeetingData(meetingId);

        if (meetingData == null) {
          print("Debug: Meeting data not found in MomsProvider, fetching...");
          final meetingDetailsProvider =
              Provider.of<MeetingListDetailProvider>(context, listen: false);

          await meetingDetailsProvider.fetchMeetingById(context, meetingId);

          if (meetingDetailsProvider.meetingData != null) {
            meetingData = meetingDetailsProvider.meetingData!;
            momsProvider.setMeetingData(meetingData);
            print("Debug: Meeting data fetched and stored in MomsProvider");
          } else {
            print("Debug: Meeting data not found from API.");
            throw Exception('Meeting tidak ditemukan.');
          }
        }

        final pdf = await momsProvider.generatePDF(context, meetingId);
        final pdfBytes = await pdf.save();

        setState(() {
          _pdfBytes = pdfBytes;
        });
      } else {
        print("Debug: provider.meetingId is null");
        throw Exception(provider.errorMessage ?? 'Token tidak valid.');
      }
    } catch (e, stackTrace) {
      print("Debug: Error occurred -> $e");
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _signInWithQR() async {
    try {
      final provider =
          Provider.of<ListMeetingsProvider>(context, listen: false);
      final meetingDetailsProvider =
          Provider.of<MeetingListDetailProvider>(context, listen: false);

      final String? token = provider.validationToken;

      if (token == null) {
        throw Exception(
            "Authentication token is missing. Please log in again.");
      }
      // Validasi meetingId dan audienceId
      if (provider.meetingId == null || provider.audienceId == null) {
        throw Exception(
            "Meeting ID atau Audience ID tidak ditemukan. Validasi Token terlebih dahulu.");
      }

      provider.validationToken!;
      // Ambil data audience berdasarkan audienceId dari listMeetingDetails
      final audience = meetingDetailsProvider.meetingData?.audiences.firstWhere(
        (aud) => aud.id == provider.audienceId,
        orElse: () => throw Exception(
            "Audience dengan ID ${provider.audienceId} tidak ditemukan."),
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
        await provider.signAudienceOnline(
          context: context,
          meetingId: provider.meetingId!,
          audienceId: provider.audienceId!,
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <
        600; // Cek apakah perangkat adalah mobile

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Container(
          width: isMobile
              ? MediaQuery.of(context).size.width * 0.95 // Ukuran untuk mobile
              : MediaQuery.of(context).size.width * 0.6, // Ukuran untuk desktop
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.symmetric(
                horizontal:
                    isMobile ? 8 : 16), // Margin untuk mobile dan lainnya
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Selamat Datang Di MOM Absensi!',
                      style: TextStyle(
                        fontSize:
                            isMobile ? 18 : 22, // Ukuran font yang responsif
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A4DA0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Silahkan masukkan Token Absen Anda untuk melihat informasi meeting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile
                            ? 14
                            : 16, // Ukuran font untuk perangkat kecil
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ticketController,
                    decoration: InputDecoration(
                      labelText: 'Token (contoh: d29f5123b8ca)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Consumer<ListMeetingsProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton.icon(
                          onPressed:
                              provider.isLoading ? null : _validateTicket,
                          icon: provider.isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: Colors.white,
                                ),
                          label: Text(
                            'Lihat Meeting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  isMobile ? 14 : 16, // Responsif font size
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A4DA0),
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 14,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_pdfBytes != null) ...[
                    Divider(color: Colors.grey),
                    Text(
                      'PDF Preview:',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16, // Responsif font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: isMobile ? 300 : 400, // Tinggi responsif
                      width: isMobile ? 300 : 600, // Lebar responsif
                      child: PdfPreview(
                        build: (format) => _pdfBytes!,
                        allowPrinting: true,
                        allowSharing: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                      onPressed: () async {
                        final provider = Provider.of<MeetingListDetailProvider>(context, listen: false);
                        final audienceId = Provider.of<ListMeetingsProvider>(context, listen: false);
                        if (provider.meetingData != null && provider.meetingData!.id != null) {
                          final idMom = provider.meetingData!.id!;
                          final idAudiences = audienceId.audienceId!; // ID Audience, sesuaikan dengan data Anda
                          final status = 3; // Status QR Online
                          final isPresent = 1; // Kehadiran

                          await provider.signAudienceOnlineWithQR(
                            context,
                            idMom: idMom,
                            idAudiences: idAudiences,
                            status: status,
                            isPresent: isPresent,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Meeting data tidak ditemukan.")),
                          );
                        }
                      },

                        icon: Icon(
                          Icons.qr_code,
                          size: 20,
                          color: Palette.white,
                        ),
                        label: Text(
                          'Tanda Tangan QR Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16, // Font responsif
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A4DA0),
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 10 : 14, // Padding responsif
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
