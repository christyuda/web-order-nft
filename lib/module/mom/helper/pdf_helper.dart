import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:webordernft/module/mom/service/model/list_audiences_response.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

class PDFHelper {
  static Future<pw.Document> generateDynamicPDFWithSignature({
    required String title,
    required Map<String, String> meetingDetails,
    required List<Map<String, String>> notes,
    required List<Map<String, dynamic>> attendanceData,
    String? logoPath,
    String? materiPembahasan,
    List<Map<String, dynamic>>? attachments = const [],
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load("assets/fonts/arial.ttf");
    final ttf = pw.Font.ttf(fontData);
    // Load logo if path is provided
    pw.ImageProvider? logoImage;
    if (logoPath != null) {
      final logoBytes = await rootBundle.load(logoPath);
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    }

    final absentees = attendanceData
        .where((attendee) =>
            attendee['status'] == 0 && attendee['is_present'] == 0)
        .toList();

    // Parse materiPembahasan if provided
    final List<pw.Widget> parsedMaterials = [];
    if (materiPembahasan != null && materiPembahasan.isNotEmpty) {
      final cleanedMaterial =
          materiPembahasan.replaceAll(RegExp(r'["\\]'), '').trim();
      try {
        final widgets = await HTMLToPdf().convert(materiPembahasan);

        if (widgets.isNotEmpty) {
          parsedMaterials.addAll(widgets);
        } else {
          parsedMaterials.add(
            pw.Text(
              "",
              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          );
        }
      } catch (e) {
        print('Error parsing materiPembahasan: $e');
        parsedMaterials.add(
          pw.Text(
            "Error parsing materi pembahasan.",
            style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.red),
          ),
        );
      }
    } else {
      parsedMaterials.add(
        pw.Text(
          "",
          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
        ),
      );
    }
    
    final List<Map<String, dynamic>> processedAttachments = [];
    for (final attachment in attachments!) {
      final String? attachmentUrl = attachment['attachmentUrl'];
      final String? eventPhotoUrl = attachment['eventPhotoUrl'];
      final String? createdAt = attachment['createdAt'];

      Uint8List? attachmentImage;
      Uint8List? eventPhotoImage;

      // Fetch images asynchronously
      if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
        attachmentImage = await fetchImageFromUrl(attachmentUrl);
      }

      if (eventPhotoUrl != null && eventPhotoUrl.isNotEmpty) {
        eventPhotoImage = await fetchImageFromUrl(eventPhotoUrl);
      }

      // Store the processed data
      processedAttachments.add({
        'attachmentUrl': attachmentUrl,
        'attachmentImage': attachmentImage,
        'eventPhotoUrl': eventPhotoUrl,
        'eventPhotoImage': eventPhotoImage,
        'createdAt': createdAt,
      });
    }
   final representativeSigners = attendanceData
    .where((attendee) =>
        attendee['representative_signer'] == 1) // Hanya nilai 1 yang dimunculkan
    .toList();


print("Representative Signers Filtered: $representativeSigners");

    print("Filtered Absentees: $absentees");
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoImage != null)
                pw.Container(
                  child: pw.Image(logoImage, width: 60, height: 60),
                ),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Meeting Details
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              // Row for Author and Nested Table for Date, Time, Place
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("Author: ${meetingDetails['Author'] ?? ''}"),
                  ),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              "Hari / Tanggal",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              meetingDetails['Date'] != null
                                  ? DateFormat("EEEE, dd MMMM yyyy", "id_ID")
                                      .format(DateTime.parse(
                                          meetingDetails['Date']!))
                                  : '',
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              "Waktu",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(meetingDetails['Time'] ?? ''),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              "Tempat",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(meetingDetails['Place'] ?? ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Materi Pembahasan Section

              // Row for Agenda
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      "Agenda",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(meetingDetails['Agenda'] ?? ''),
                  ),
                ],
              ),
              // Row for Participants
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      "Peserta Rapat",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: attendanceData.map((attendee) {
                        return pw.Text(attendee['name'] ?? 'N/A');
                      }).toList(),
                    ),
                  ),
                ],
              ),
              // Row for Absentees

              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      "Berhalangan Hadir",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: attendanceData
                          .where((attendee) =>
                              attendee['status'] == 0 &&
                              attendee['is_present'] == 0)
                          .map((absentee) {
                        return pw.Text(absentee['name'] ?? 'N/A');
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          if (materiPembahasan != null && materiPembahasan.isNotEmpty) ...[
          pw.Text(
            "Materi Pembahasan",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),

          // Materi Pembahasan Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: parsedMaterials.isNotEmpty
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: parsedMaterials,
                  )
                : pw.Text(
                    "",
                    style: pw.TextStyle(fontSize: 12),
                  ),
          ),
          pw.SizedBox(height: 16),
        ],

                  // Notes Section
                if (notes.isNotEmpty) ...[
          pw.Text(
            "Tindak Lanjut",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),

          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FixedColumnWidth(40),
              1: pw.FlexColumnWidth(),
              2: pw.FixedColumnWidth(50),
              3: pw.FixedColumnWidth(70),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'No',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Catatan',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'PIC',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Due Date',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Data rows
              ...notes.asMap().entries.map((entry) {
                int index = entry.key + 1;
                final note = entry.value;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(index.toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(note['note'] ?? ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(note['pic'] ?? ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(note['dueDate'] ?? ''),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 16),
        ],


        if (representativeSigners.isNotEmpty) ...[
          pw.Text(
            "Diperiksa Oleh",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: representativeSigners.map((attendee) {
              return pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      "Diperiksa Oleh,",
                      style: pw.TextStyle(
                          fontSize: 10, fontStyle: pw.FontStyle.italic),
                    ),
                    pw.Text(
                      attendee['position'] ?? 'Posisi Tidak Diketahui',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      attendee['name'] ?? 'Nama Tidak Diketahui',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      "NIK: ${attendee['nik'] ?? 'Tidak Diketahui'}",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 16),
        ] else ...[
          pw.Text(
            "",
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey,
            ),
          ),
        ]
      ],
      ),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Daftar Hadir Peserta",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10), // Tambahkan jarak
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FixedColumnWidth(40),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(100),
                3: pw.FlexColumnWidth(),
                4: pw.FixedColumnWidth(80),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("No",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Nama",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("NIK",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("Stakeholder",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text("TTD",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Data rows
                ...attendanceData.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  final attendee = entry.value;

                  final int? status = attendee['status'];
                  final signing = attendee['signing'];

                  // Generate QR Data
                  final String currentDate =
                      DateFormat('dd-MM-yyyy', 'id_ID').format(DateTime.now());
                  final String qrData = """
                --- Tanda Tangan QR ---
                Nama       : ${attendee['name']}
                NIK        : ${attendee['nik']}
                Posisi     : ${attendee['position']}
                Stakeholder: ${attendee['stakeholder']}
                Agenda     : ${meetingDetails['Agenda']} 
                Tertandatangani    : $currentDate
                """;

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(index.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(attendee['name'] ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(attendee['nik'] ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(attendee['stakeholder'] ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: status == 1 && signing != null
                            ? pw.Center(
                                child: pw.Image(
                                  pw.MemoryImage(signing),
                                  width: 50,
                                  height: 50,
                                ),
                              )
                            : (status == 2 || status == 3)
                                ? pw.Center(
                                    child: pw.BarcodeWidget(
                                      barcode: Barcode.qrCode(),
                                      data: qrData,
                                      width: 50,
                                      height: 50,
                                    ),
                                  )
                                : pw.Text(
                                    'Tidak Ada',
                                    style: pw.TextStyle(
                                      fontStyle: pw.FontStyle.italic,
                                      fontSize: 10,
                                      color: PdfColors.grey,
                                    ),
                                  ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
    if (processedAttachments.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf),
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              "Attachments",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            ...processedAttachments.map((attachment) {
              final String? attachmentUrl = attachment['attachmentUrl'];
              final Uint8List? attachmentImage = attachment['attachmentImage'];
              final String? eventPhotoUrl = attachment['eventPhotoUrl'];
              final Uint8List? eventPhotoImage = attachment['eventPhotoImage'];
              final String? createdAt = attachment['createdAt'];

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          "Attachment Link: ",
                          style: pw.TextStyle(fontSize: 12),
                        ),
                        pw.UrlLink(
                          destination: attachmentUrl,
                          child: pw.Text(
                            attachmentUrl,
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.blue,
                              decoration: pw.TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (attachmentImage != null)
                      pw.Container(
                        height: 150,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey),
                        ),
                        child: pw.Image(pw.MemoryImage(attachmentImage)),
                      )
                    else
                      pw.Text(
                        "Preview not available for the attachment.",
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600),
                      ),
                  ],
                  if (eventPhotoUrl != null && eventPhotoUrl.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "Event Photo:",
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    if (eventPhotoImage != null)
                      pw.Container(
                        height: 150,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey),
                        ),
                        child: pw.Image(pw.MemoryImage(eventPhotoImage)),
                      )
                    else
                      pw.Text(
                        "Preview not available for the event photo.",
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600),
                      ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "Created At: $createdAt",
                    style: pw.TextStyle(
                        fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Text(
              "",
              style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return pdf;
  }
}

Future<Uint8List?> fetchImageFromUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print('Failed to load image, status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching image from URL: $e');
    return null;
  }
}
