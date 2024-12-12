import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/constant.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/login/provider/login_provider.dart';
import 'package:webordernft/module/mom/provider/manager/list_meeting_detail_provider.dart';
import 'package:webordernft/module/mom/provider/manager/list_meetings_provider.dart';
import 'package:signature/signature.dart';
import 'package:webordernft/module/mom/service/model/send_mail_request.dart';
import 'package:webordernft/module/mom/view/online_signature.dart';

class AudienceListPage extends StatelessWidget {
  final int meetingId;

  AudienceListPage({required this.meetingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audience List'),
      ),
      body: FutureBuilder(
        future: Provider.of<ListMeetingsProvider>(context, listen: false)
            .fetchListAudiences(context, meetingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading audiences: ${snapshot.error}'),
            );
          } else {
            return Consumer<ListMeetingsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (provider.audiences.isEmpty) {
                  return Center(child: Text('No audiences available.'));
                }
                final meetingDetailProvider = Provider.of<MeetingListDetailProvider>(context, listen: false);
                final String agenda =
                  meetingDetailProvider.meetingData?.agenda ?? 'Tidak Ada Agenda';
                return ListView.builder(
                  itemCount: provider.audiences.length,
                  itemBuilder: (context, index) {
                    final audience = provider.audiences[index];
                    String signingStatus;
                    if (audience.status == 1) {
                      signingStatus = 'Tertandatangan';
                    } else if (audience.status == 2) {
                      signingStatus = 'Tertandatangan QR';
                    } else if (audience.status == 3) {
                      signingStatus = 'Tertandatangan QR Online';
                    } else {
                      signingStatus = 'Belum Tandatangan';
                    }
                    String qrData = "";
                    if (audience.status == 2 || audience.status == 3) {
                      String currentDate =
                          DateFormat('dd-MM-yyyy').format(DateTime.now());
                      qrData = """
                        --- Tanda Tangan QR ---
                        Nama       : ${audience.name ?? 'Unknown'}
                        NIK        : ${audience.nik ?? 'N/A'}
                        Posisi     : ${audience.position ?? 'N/A'}
                        Stakeholder: ${audience.stakeholder ?? 'N/A'}
                        Agenda     : $agenda
                        Tertandatangani    : $currentDate
                        """;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Audience information
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audience.name ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text('NIK: ${audience.nik ?? 'N/A'}'),
                                Text('Position: ${audience.position ?? 'N/A'}'),
                                Text(
                                    'Stakeholder: ${audience.stakeholder ?? 'N/A'}'),
                              ],
                            ),
                          ),

                          // Right side: Buttons
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if ((audience.status == 2 ||
                                        audience.status == 3) &&
                                    qrData.isNotEmpty)
                                  BarcodeWidget(
                                    barcode: Barcode.qrCode(),
                                    data: qrData,
                                    width: 150,
                                    height: 150,
                                    color: Colors.black,
                                  ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: audience.status == 0
                                      ? () => _showSigningOptionsDialog(
                                          context,
                                          provider,
                                          meetingId,
                                          audience.audienceId,
                                          audience.name ?? 'Unknown',
                                          audience.nik ?? 'N/A',
                                          audience.position ?? 'N/A',
                                          audience.stakeholder ?? 'N/A')
                                      : null,
                                  child: Text(
                                    signingStatus,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: audience.status == 0
                                        ? Palette.primary
                                        : Colors.green.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
void _showSigningOptionsDialog(
  BuildContext context,
  ListMeetingsProvider provider,
  int meetingId,
  int audienceId,
  String name,
  String nik,
  String position,
  String stakeholder,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Pilih Metode Tanda Tangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Tanda Tangan Manual"),
              onTap: () {
                Navigator.pop(context, true);
                _showSignatureDialog(context, provider, meetingId, audienceId);
              },
            ),
            ListTile(
              title: Text("Tanda Tangan QR Code"),
              onTap: () async {
                final meetingDetailProvider =
                    Provider.of<MeetingListDetailProvider>(context,
                        listen: false);
                final String agenda = meetingDetailProvider.meetingData?.agenda ?? 'Tidak Ada Agenda';

                Uint8List? qrImage = await _generateQrImage(
                  name: name,
                  nik: nik,
                  position: position,
                  stakeholder: stakeholder,
                  agenda: agenda,
                );

                if (qrImage != null) {
                  await provider.signAudience(
                    context: context,
                    meetingId: meetingId,
                    audienceId: audienceId,
                    status: 2,
                    signatureData: qrImage,
                    isPresent: 1,
                  );
                }
                Navigator.pop(context, true);
              },
            ),
            ListTile(
              title: Text("Tanda Tangan Online"),
              onTap: () async {
                final listMeetingsProvider =
                    Provider.of<ListMeetingsProvider>(context, listen: false);
                final meetingDetailProvider =
                    Provider.of<MeetingListDetailProvider>(context,
                        listen: false);
                await meetingDetailProvider.fetchMeetingById(context, meetingId);

                try {
                  // Ambil daftar audiens dengan email yang valid dan status 0
                  final audiencesWithEmailAndStatusZero =
                      listMeetingsProvider.audiences
                          .where((audience) =>
                              (audience.email ?? "").isNotEmpty &&
                              audience.status == 0) // Hanya status 0
                          .toList();

                  if (audiencesWithEmailAndStatusZero.isEmpty) {
                    SnackToastMessage(
                      context,
                      "Tidak ada audiens dengan status 'Belum Tandatangan' yang tersedia untuk pengiriman.",
                      ToastType.warning,
                    );
                    return;
                  }

                  // Iterasi setiap audiens dan kirim email dengan token unik
                  for (var audience in audiencesWithEmailAndStatusZero) {
                    // Step 1: Generate token untuk audiens saat ini
                    await listMeetingsProvider.generateTicket(
                      context: context,
                      meetingId: meetingId,
                      audienceId: audience.audienceId,
                    );

                    // Periksa apakah token berhasil dibuat
                    if (listMeetingsProvider.ticketingId == null) {
                      throw Exception(
                          "Gagal menghasilkan Token tanda tangan untuk ${audience.name}.");
                    }

                    // Step 2: Buat konten email dengan token audiens saat ini
                    final emailContent = """
                            <p>Yth. Peserta Rapat,</p>

                            <p>Terima kasih telah menghadiri rapat yang telah kami selenggarakan. Berikut kami sampaikan detail Token untuk proses tanda tangan digital pada Minutes of Meeting (MoM) yang telah disepakati:</p>

                            <table style="border-collapse: collapse; width: 100%; margin: 10px 0;">
                              <tr>
                                <td style="padding: 8px; border: 1px solid #dddddd; font-weight: bold;">Token</td>
                                <td style="padding: 8px; border: 1px solid #dddddd;">${listMeetingsProvider.ticketingId}</td>
                              </tr>
                              <tr>
                                <td style="padding: 8px; border: 1px solid #dddddd; font-weight: bold;">Topik Rapat</td>
                                <td style="padding: 8px; border: 1px solid #dddddd;">${meetingDetailProvider?.meetingData?.agenda ?? '-'}</td>
                              </tr>
                              <tr>
                                <td style="padding: 8px; border: 1px solid #dddddd; font-weight: bold;">Tanggal</td>
                                <td style="padding: 8px; border: 1px solid #dddddd;">${meetingDetailProvider?.meetingData?.date != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(meetingDetailProvider?.meetingData?.date ?? '')) : '-'}</td>
                              </tr>
                              <tr>
                                <td style="padding: 8px; border: 1px solid #dddddd; font-weight: bold;">Lokasi</td>
                                <td style="padding: 8px; border: 1px solid #dddddd;">${meetingDetailProvider?.meetingData?.place ?? '-'}</td>
                              </tr>
                            </table>

                            <p>Untuk melanjutkan proses tanda tangan digital pada dokumen MoM, silakan mengikuti langkah-langkah berikut:</p>

                            <ol>
                              <li>Kunjungi halaman <a href="https://nft.posfin.id/OnlineSignature" target="_blank">https://nft.posfin.id/OnlineSignature</a>.</li>
                              <li>Masukkan token yang telah kami berikan: <b>${listMeetingsProvider.ticketingId}</b>.</li>
                              <li>Buka dokumen MoM yang tersedia untuk ditinjau.</li>
                              <li>Klik tombol <b>Tanda Tangan Online</b> untuk menyelesaikan proses tanda tangan digital.</li>
                            </ol>

                            <p>Mohon pastikan untuk menyelesaikan proses tanda tangan sebelum batas waktu yang telah ditentukan.</p>

                            <p>Untuk informasi lebih lanjut atau bantuan teknis, silakan menghubungi tim penyelenggara melalui kontak yang tersedia.</p>

                            <p>Terima kasih atas perhatian dan kerjasamanya.</p>

                            <p>Salam,</p>
                            <p><b>Tim Minutes of Meeting</b></p>
                            """;


                    // Step 3: Buat permintaan email untuk audiens saat ini
                    final emailRequest = EmailRequest(
                      emails: [audience.email!],
                      to: "audiences",
                      subject: "Detail Tiket Tanda Tangan Online",
                      content: emailContent,
                    );

                    // Step 4: Kirim email
                    await listMeetingsProvider.sendMail(context, emailRequest);
                  }

                  // Tampilkan toast sukses
                  SnackToastMessage(
                    context,
                    "Semua email berhasil dikirim.",
                    ToastType.success,
                  );
                } catch (e) {
                  // Tangani error
                  SnackToastMessage(
                    context,
                    "Gagal mengirim email: $e",
                    ToastType.error,
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showSignatureDialog(
  BuildContext context,
  ListMeetingsProvider provider,
  int meetingId,
  int audienceId,
) {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Center(
          child: Text(
            "Tanda Tangan Manual",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Expanded(
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _signatureController.clear();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Row(
                      children: [
                        Icon(Icons.clear, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Clear", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_signatureController.isEmpty) {
                        final Uint8List? signatureData =
                            await _signatureController.toPngBytes();
                        if (signatureData != null) {
                          // Kirim tanda tangan ke backend
                          await provider.signAudience(
                            context: context,
                            meetingId: meetingId,
                            audienceId: audienceId,
                            status: 1,
                            signatureData: signatureData,
                            isPresent: 1,
                          );
                          Navigator.pop(context, true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Save", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  // Helper function to generate QR code image and convert it to Uint8List
  Future<Uint8List?> _generateQrImage({
    required String name,
    required String nik,
    required String position,
    required String stakeholder,
    required String agenda,
 }) async {
    String currentDate =
        DateFormat('dd-MM-yyyy', 'id_ID').format(DateTime.now());
    String qrData = """
      --- Tanda Tangan QR ---
      Nama       : $name
      NIK        : $nik
      Posisi     : $position
      Stakeholder: $stakeholder
      Agenda     : $agenda
      Tertandatangani  : $currentDate

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
