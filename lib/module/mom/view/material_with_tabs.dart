import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/parser/html_to_delta.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/helper/customHtmlOperations.dart';
import 'package:webordernft/module/mom/provider/manager/list_meeting_detail_provider.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:webordernft/module/mom/service/model/pin_material_kesimpulan.dart';
import 'package:webordernft/module/mom/view/conclusion_section.dart';

class MaterialPagesWithTabs extends StatefulWidget {
  @override
  _MaterialPagesWithTabsState createState() => _MaterialPagesWithTabsState();
}

class _MaterialPagesWithTabsState extends State<MaterialPagesWithTabs>
    with SingleTickerProviderStateMixin {
  late QuillController _quillController;
  final TextEditingController _conclusionController = TextEditingController();
  late TabController _tabController;
  late int idMom;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    final momsProvider = Provider.of<MomsProvider>(context, listen: false);
    _quillController =
        QuillController.basic(configurations: QuillControllerConfigurations());
    idMom = momsProvider.idMom!;
    _fetchAndSetMaterial(context, idMom, _quillController);
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
          'id': note.id ?? '',
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
    _tabController.dispose();
    _quillController.dispose();
    _conclusionController.dispose();
    super.dispose();
  }

  void _saveDiscussionMaterial(String htmlContent) {
    final provider = Provider.of<MomsProvider>(context, listen: false);
    provider.discussionMaterial = htmlContent;
  }

  // void _addConclusion() {
  //   final provider = Provider.of<MomsProvider>(context, listen: false);
  //   final newConclusion = {
  //     'catatan': _conclusionController.text,
  //     'pic': '',
  //     'dueDate': '',
  //   };
  //   provider.addCatatanToFinalized(newConclusion);
    
  //   _conclusionController.clear();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Materi & Tindak Lanjut"),
        backgroundColor: Palette.bgcolor,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Materi"),
            Tab(text: "Tindak Lanjut"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscussionTab(),
          _buildConclusionTab(),
        ],
      ),
    );
  }

  Widget _buildDiscussionTab() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: _DiscussionSection(
      quillController: _quillController,
      saveDiscussionMaterial: (htmlContent) {
        _saveDiscussionMaterial(htmlContent);
        SnackToastMessage(
          context,
          "Materi berhasil disimpan",
          ToastType.success,
        );
      }, idMom: idMom,
    ),
  );
}


  Widget _buildConclusionTab() {
  return ConclusionSection(
    conclusionController: _conclusionController,
    idMom: idMom,
  );
}}


class _DiscussionSection extends StatelessWidget {
  final QuillController quillController;
  final Function(String) saveDiscussionMaterial;
  final int idMom;

  const _DiscussionSection({
    Key? key,
    required this.quillController,
    required this.saveDiscussionMaterial,
    required this.idMom,
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
          onPressed: ()async {
            final htmlOutput = _convertDeltaToHtml(quillController);
            saveDiscussionMaterial(htmlOutput); // Simpan hasil HTML

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
                          'Berhasil Menyimpan Materi Pembahasan ',
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