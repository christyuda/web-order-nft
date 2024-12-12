import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/pullquote_block_example.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/helper/customHtmlOperations.dart';
import 'package:webordernft/module/mom/provider/manager/list_meeting_detail_provider.dart';
import 'package:webordernft/module/mom/provider/manager/list_meetings_provider.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:webordernft/module/mom/service/model/pin_material_kesimpulan.dart';

class Materialpages extends StatefulWidget {
  @override
  _MaterialpagesState createState() => _MaterialpagesState();
}

class _MaterialpagesState extends State<Materialpages> {
  late QuillController _quillController;
  final TextEditingController _conclusionController = TextEditingController();
  late int idMom;
  @override
  void initState() {
    super.initState();

    final provider = Provider.of<MomsProvider>(context, listen: false);
    final listMeetingDetailProvider =
        Provider.of<MeetingListDetailProvider>(context, listen: false);
    final momsProvider = Provider.of<MomsProvider>(context, listen: false);
    _quillController =
        QuillController.basic(configurations: QuillControllerConfigurations());
    idMom = momsProvider.idMom!;
    _fetchAndSetMaterial(context, idMom, _quillController);

    idMom = provider.idMom!;
  }

  Future<void> _fetchAndSetMaterial(BuildContext context, int meetingId,
      QuillController quillController) async {
    final provider =
        Provider.of<MeetingListDetailProvider>(context, listen: false);
    await provider.fetchMeetingById(context, meetingId);

    final materialHtml = provider.meetingData?.material ?? "";
    final notes = provider.meetingData?.notes ?? [];
    if (notes.isNotEmpty) {
      final formattedNotes = notes.map((note) {
        return {
          'catatan': note.notes ?? '',
          'pic': note.pic ?? '',
          'dueDate': note.dueDate ?? '',
        };
      }).toList();

      final momsProvider = Provider.of<MomsProvider>(context, listen: false);
      momsProvider.setNotesFinalList(formattedNotes); // Gunakan fungsi baru
    }
    print("Fetched HTML Material: $materialHtml");

    if (materialHtml.isNotEmpty) {
      try {
        // Menggunakan HtmlOperations untuk mengonversi HTML ke Delta
        final delta = HtmlToDeltaConverter.htmlToDelta(materialHtml);

        print("Converted Delta: ${delta.toJson()}"); // Debugging log

        setState(() {
          quillController.document = Document.fromDelta(delta);
        });
      } catch (e) {
        print("Error converting HTML to Delta: $e");
      }
    } else {
      print("No material content found!");
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _conclusionController.dispose();
    super.dispose();
  }

  void _saveDiscussionMaterial(String htmlContent) {
    final provider = Provider.of<MomsProvider>(context, listen: false);
    provider.discussionMaterial = htmlContent;
  }

  void _addConclusion() {
    final provider = Provider.of<MomsProvider>(context, listen: false);
    final newConclusion = {
      'catatan': _conclusionController.text,
      'pic': '',
      'dueDate': '',
    };
    provider.addCatatanToFinalized(newConclusion);
    _conclusionController.clear();
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Masukkan $title"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _showDatePickerDialog({
    required BuildContext context,
    required String initialDate,
    required Function(String) onSave,
  }) async {
    // Parse the initial date string to DateTime or use the current date
    final initialDateParsed =
        initialDate.isNotEmpty ? DateTime.parse(initialDate) : DateTime.now();

    // Show the date picker dialog
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateParsed,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Save the selected date in the desired format
    if (selectedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      onSave(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catatanProvider = Provider.of<MomsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Materi & Kesimpulan"),
        backgroundColor: Palette.bgcolor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Kirim `true` sebagai hasil
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiscussionSection(
                quillController: _quillController,
                saveDiscussionMaterial: _saveDiscussionMaterial,
              ),
              const SizedBox(height: 24),
              _buildConclusionSection(catatanProvider),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    final provider =
                        Provider.of<MomsProvider>(context, listen: false);

                    // Ambil discussionMaterial
                    final discussionMaterial = provider.discussionMaterial;

                    // Ambil finalizedList untuk diubah menjadi `notes`
                    final notes = provider.finalizedList.map((finalizedNote) {
                      return Note(
                        note: finalizedNote['catatan'] ?? '',
                        pic: finalizedNote['pic'] ?? '',
                        dueDate: finalizedNote['dueDate'] ?? '',
                      );
                    }).toList();

                    // Buat objek MaterialRequest
                    final materialRequest = MaterialRequest(
                      idMom: idMom.toString(),
                      material: discussionMaterial,
                      notes: notes,
                    );

                    final requestBody = materialRequest.toJson();
                    print(requestBody);

                    // Simpan ke API
                    try {
                      await provider.addMaterialsAndNotes(
                          context, materialRequest);
                      SnackToastMessage(
                          context,
                          'Berhasil Menyimpan Materi dan Kesimpulan ',
                          ToastType.success);
                    } catch (e) {
                      SnackToastMessage(
                        context,
                        "Gagal menyimpan data: ${e.toString()}",
                        ToastType.error,
                      );
                    }
                  },
                  child: Text(
                    "Simpan",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConclusionSection(MomsProvider catatanProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for "Kesimpulan" section
          Text(
            "Kesimpulan *",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Input Field for Adding Kesimpulan
          TextField(
            controller: catatanProvider.catatanController,
            decoration: InputDecoration(
              labelText: "Tambah Kesimpulan",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: "Tuliskan Kesimpulan di sini...",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),

          // Button to Add Catatan
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                final newCatatan = {
                  'catatan': catatanProvider.catatanController.text,
                  'pic': '', // Default PIC value
                  'dueDate': '', // Default Due Date value
                };
                catatanProvider.addCatatanToFinalized(newCatatan);
                catatanProvider.catatanController
                    .clear(); // Clear the text field after adding
              },
              child: Text(
                "Tambahkan Catatan",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Table for Displaying Kesimpulan
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: DataTable(
                columnSpacing: 12, // Reduce the spacing between columns
                columns: [
                  DataColumn(label: SizedBox(width: 30, child: Text('No'))),
                  DataColumn(label: Text('Catatan')),
                  DataColumn(label: SizedBox(width: 100, child: Text('PIC'))),
                  DataColumn(
                      label: SizedBox(width: 100, child: Text('Due Date'))),
                  DataColumn(
                      label: SizedBox(width: 60, child: Text('Actions'))),
                ],
                rows: List<DataRow>.generate(
                  catatanProvider.finalizedList.length,
                  (index) {
                    final catatan = catatanProvider.finalizedList[index];
                    return DataRow(
                      cells: [
                        DataCell(
                            SizedBox(width: 30, child: Text('${index + 1}'))),
                        DataCell(Text(catatan['catatan'] ?? '')),
                        DataCell(
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  catatan['pic'].isNotEmpty
                                      ? catatan['pic']
                                      : 'Edit PIC',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditDialog(
                                    context: context,
                                    title: "Edit PIC",
                                    initialValue: catatan['pic'],
                                    onSave: (value) =>
                                        catatanProvider.updatePIC(
                                      index,
                                      value,
                                      isFinalized: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  catatan['dueDate'].isNotEmpty
                                      ? catatan['dueDate']
                                      : 'Select Date',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showDatePickerDialog(
                                    context: context,
                                    initialDate: catatan['dueDate'],
                                    onSave: (value) =>
                                        catatanProvider.updateDueDate(
                                      index,
                                      value,
                                      isFinalized: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 30,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                catatanProvider.removeFromFinalized(index);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionSection extends StatelessWidget {
  final QuillController quillController;
  final Function(String) saveDiscussionMaterial;

  const _DiscussionSection({
    Key? key,
    required this.quillController,
    required this.saveDiscussionMaterial,
  }) : super(key: key);

  // Fungsi konversi Delta ke HTML
  String _convertDeltaToHtml(QuillController controller) {
    final deltaJson = controller.document.toDelta().toJson();
    return QuillDeltaToHtmlConverter(
      List.castFrom(deltaJson),
      ConverterOptions(
          multiLineParagraph: false,
          multiLineCustomBlock: true,
          multiLineBlockquote: true,
          multiLineCodeblock: true,
          multiLineHeader: true,
          orderedListTag: 'ol', // Tag untuk list terurut
          bulletListTag: 'ul', // Tag untuk list bullet
          converterOptions: OpConverterOptions(
            customTag: (format, op) {
              if (format == 'mention') {
                return 'span'; // Gunakan tag <span> untuk mention
              }
              return null;
            },
            classPrefix: 'ql',
            linkRel: 'noopener noreferrer',
            linkTarget: '_blank',
            inlineStylesFlag: true,
            encodeHtml: true,
            paragraphTag: 'p',
            listItemTag: 'li',
            customCssStyles: (op) {
              if (op.attributes != null && op.attributes!.bold != null) {
                return ['font-weight: bold'];
              }
              if (op.attributes!.list == 'bullet') {
                return ['list-style-type: disc; margin-left: 20px;'];
              }
              return null;
            },
            customTagAttributes: (op) {
              if (op.attributes != null && op.attributes!.link != null) {
                return {
                  'href': op.attributes!.link!,
                  'target': '_blank',
                  'rel': 'noopener noreferrer',
                };
              }

              return null;
            },
            inlineStyles: InlineStyles({
              'font': InlineStyleType(
                  fn: (value, _) =>
                      defaultInlineFonts[value] ?? 'font-family:$value'),
              'size': InlineStyleType(map: {
                'small': 'font-size: 0.75em',
                'large': 'font-size: 1.5em',
                'huge': 'font-size: 2.5em',
              }),
              'indent': InlineStyleType(fn: (value, op) {
                final indentSize = (double.tryParse(value) ?? double.nan) * 3;
                final side =
                    op.attributes['direction'] == 'rtl' ? 'right' : 'left';
                return 'padding-$side:${indentSize}em';
              }),
              'direction': InlineStyleType(fn: (value, op) {
                if (value == 'rtl') {
                  return 'direction:rtl';
                } else {
                  return null;
                }
              }),
              'list': InlineStyleType(map: {
                'checked': "list-style-type:'\\2611';padding-left: 0.5em;",
                'unchecked': "list-style-type:'\\2610';padding-left: 0.5em;",
              }),
            }),
          )),
    ).convert();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Materi Pembahasan *",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        QuillToolbar.simple(
            controller: quillController,
            configurations:
                QuillSimpleToolbarConfigurations(showListBullets: true)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Text(
                "Tambahkan materi pembahasan MOM di sini",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              Divider(),
              SizedBox(
                height: 300,
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(),
                  scrollController: ScrollController(),
                  focusNode: FocusNode(),
                  controller: quillController,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final htmlOutput = _convertDeltaToHtml(quillController);
            saveDiscussionMaterial(htmlOutput); // Simpan hasil HTML
          },
          child: Text(
            "Simpan Materi",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
