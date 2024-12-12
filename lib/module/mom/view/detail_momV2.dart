import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:webordernft/module/mom/view/discussion_material.dart';
import 'package:webordernft/module/mom/view/search_karyawan.dart';
import 'package:webordernft/module/mom/view/sliding_panel_employee.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class DetailMom extends StatefulWidget {
  @override
  _DetailMomState createState() => _DetailMomState();
}

class _DetailMomState extends State<DetailMom> with TickerProviderStateMixin {
  late QuillController _quillController;

  Timer? _debounce;

  final _formKey = GlobalKey<FormBuilderState>();
  bool isRightColumnVisible = false;
  bool isEditable = false;

  Future<Uint8List>? pdfFuture;
  late AnimationController _animationController;
  void _saveDiscussionMaterial(String htmlContent) async {
    final provider = Provider.of<MomsProvider>(context, listen: false);
    provider.discussionMaterial = htmlContent;
  }

  @override
  void initState() {
    super.initState();
    _quillController =
        QuillController.basic(configurations: QuillControllerConfigurations());

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && isRightColumnVisible) {
        final provider = Provider.of<MomsProvider>(context, listen: false);
        provider.author = _formKey.currentState?.fields['author']?.value;
        final DateTime? selectedDate =
            _formKey.currentState?.fields['tanggal']?.value;
        provider.meetingDate = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate)
            : null;
        final DateTime? selectedDateTime =
            _formKey.currentState?.fields['Waktu']?.value;
        provider.time = selectedDateTime != null
            ? DateFormat('hh:mm a').format(selectedDateTime)
            : null;
        provider.place = _formKey.currentState?.fields['Tempat']?.value;
        provider.agenda = _formKey.currentState?.fields['Agenda']?.value;
        final String discussionMaterial = provider.discussionMaterial ?? '';
        if (discussionMaterial.isNotEmpty) {
          print("Discussion Material: $discussionMaterial");
        }

        String convertDeltaToHtml(QuillController quillController) {
          final deltaJson = quillController.document.toDelta().toJson();

          // Inisialisasi konverter dengan Delta JSON
          final converter = QuillDeltaToHtmlConverter(
            List.castFrom(deltaJson), // Ubah JSON Delta ke format List
            ConverterOptions(
              converterOptions: OpConverterOptions(
                inlineStylesFlag: true, // Untuk mengaktifkan inline styles
                inlineStyles: InlineStyles({
                  ...defaultInlineStyles.attrs,
                  'size': InlineStyleType(
                    fn: (value, _) =>
                        'font-size: ${value}px', // Contoh untuk ukuran font
                  ),
                }),
              ),
            ),
          );

          // Konversi ke HTML
          return converter.convert();
        }

        pdfFuture = provider.generatePreview(context).then((pdf) => pdf.save());
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quillController.dispose();

    super.dispose();
  }

  void _toggleRightColumn() {
    setState(() {
      isRightColumnVisible = !isRightColumnVisible;
    });

    // Mulai animasi setelah mengubah status kolom kanan
    if (isRightColumnVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      pdfFuture = null; // Kosongkan PDF saat kolom ditutup
    }
  }

  void _toggleEditable() {
    setState(() {
      isEditable = !isEditable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catatanProvider = Provider.of<MomsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Buat MOM"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Kirim `true` sebagai hasil
          },
        ),
      ),
      backgroundColor: Palette.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Column
            Expanded(
              flex: isRightColumnVisible ? 3 : 5,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildTabItem("Meeting"),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.list_alt),
                              color: Palette.momsecondary,
                              onPressed: () {
                                _openSlidingPanelEmployee(context);
                              },
                            ),
                            // IconButton(
                            //   icon: Icon(Icons.remove_red_eye),
                            //   color: Palette.momsecondary,
                            //   onPressed: () {
                            //     _toggleRightColumn();
                            //   },
                            // ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // FormBuilder Form in Left Column
                        Expanded(
                          child: FormBuilder(
                            key: _formKey,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: _buildLabeledField(
                                          "Penulis *",
                                          _buildCustomTextField(
                                            name: 'author',
                                            hintText: 'Masukkan nama penulis',
                                            suffixIcon: Icons.info_outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: _buildLabeledField(
                                          "Hari / Tanggal *",
                                          _buildCustomTextField(
                                            name: 'tanggal',
                                            hintText: 'Pilih hari / tanggal',
                                            suffixIcon: Icons.calendar_today,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: _buildLabeledField(
                                          "Waktu *",
                                          _buildCustomTextField(
                                            name: 'Waktu',
                                            hintText: 'Masukkan jam',
                                            suffixIcon: Icons.access_time,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: _buildLabeledField(
                                          "Tempat Rapat *",
                                          _buildCustomTextField(
                                            name: 'Tempat',
                                            hintText: 'Masukkan tempat rapat',
                                            suffixIcon: Icons.location_on,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: _buildLabeledField(
                                          "Agenda *",
                                          _buildCustomTextField(
                                            name: 'Agenda',
                                            hintText: 'Masukkan agenda rapat',
                                            suffixIcon: Icons.event_note,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Expanded(
                                    //   child: Padding(
                                    //     padding:
                                    //         const EdgeInsets.only(left: 8.0),
                                    //     child: _buildLabeledField(
                                    //       "Peserta Rapat *",
                                    //       _buildParticipantField(),
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                SizedBox(width: 16),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),
            // Right Column with smooth transition
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: isRightColumnVisible
                  ? MediaQuery.of(context).size.width * 0.3
                  : 0,
              child: isRightColumnVisible
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Preview",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.more_vert),
                                  color: Colors.grey,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Outer Container with Inner Container for padding
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Palette.bgcolor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Palette.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FutureBuilder<Uint8List>(
                                future: pdfFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                        child: Text("Error generating PDF"));
                                  } else {
                                    return PdfPreview(
                                      build: (format) => snapshot.data!,
                                      allowPrinting: true,
                                      allowSharing: true,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build labeled fields
  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildParticipantField() {
    return FormBuilderTextField(
      name: "Peserta Rapat",
      readOnly: true,
      decoration: InputDecoration(
        hintText: "Masukkan peserta rapat",
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(width: 1, color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: Icon(Icons.person_search, color: Colors.blue),
                onPressed: () => _openSlidingPanelEmployee(context))
          ],
        ),
      ),
    );
  }

  // Widget _buildCatatanField() {}

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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<MomsProvider>(context, listen: false);

            if (_formKey.currentState?.saveAndValidate() ?? false) {
              provider.author = _formKey.currentState?.fields['author']?.value;
              final DateTime? selectedDate =
                  _formKey.currentState?.fields['tanggal']?.value;
              provider.meetingDate = selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate)
                  : null;

              // Format TimeOfDay for the time
              final DateTime? selectedDateTime =
                  _formKey.currentState?.fields['Waktu']?.value;
              provider.time = selectedDateTime != null
                  ? DateFormat('hh:mm a').format(selectedDateTime)
                  : null;
              provider.place = _formKey.currentState?.fields['Tempat']?.value;
              provider.agenda = _formKey.currentState?.fields['Agenda']?.value;

              final int representativeSigner = provider.representativeSigner;
              final String discussionMaterial =
                  provider.discussionMaterial ?? '';
              if (discussionMaterial.isNotEmpty) {
                print("Discussion Material: $discussionMaterial");
              }

              await provider.createMeeting(context, representativeSigner);
              if (provider.isSubmitting == false) {
                _formKey.currentState?.reset();

                provider.resetFormData();
              } else {
                SnackToastMessage(context,
                    "Gagal membuat MOM. Silakan coba lagi.", ToastType.error);
              }
            }
          },
          child: Text(
            'Simpan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.primary,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildIconOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

void _openSlidingPanelEmployee(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final employeeProvider =
          Provider.of<MomsProvider>(context, listen: false);
      employeeProvider.fetchUserAudiences(
          context, 1, 10, ''); // Fetch initial data

      final TextEditingController _searchController = TextEditingController();
      _searchController.addListener(() {
        final term = _searchController.text;
        if (term.isNotEmpty) {
          employeeProvider.fetchUserAudiences(context, 1, 10, term);
        } else {
          employeeProvider.clearSuggestions();
        }
      });

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: EdgeInsets.all(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Peserta Rapat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Palette.momsecondary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Search Bar and Add Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Cari nama, nik, jabatan, stakeholder",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAddEmployeeDialog(context, employeeProvider);
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          "Tambah Peserta",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primary,
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Search Results or Empty Message
                  Expanded(
                    child: Consumer<MomsProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (provider.suggestions.isEmpty) {
                          return Center(
                              child: Text("Tidak ada hasil ditemukan"));
                        }
                        return ListView.builder(
                          itemCount: provider.suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = provider.suggestions[index];
                            return ListTile(
                              title: Text(suggestion['name'] ?? ''),
                              subtitle: Text(suggestion['position'] ?? ''),
                              trailing: Icon(Icons.add, color: Palette.primary),
                              onTap: () {
                                provider.addEmployeeById(
                                  context: context,
                                  id: int.parse(suggestion['id']!),
                                  name: suggestion['name'] ?? '',
                                  position: suggestion['position'] ?? '',
                                  nik: suggestion['nik'] ?? '',
                                  stakeholder: suggestion['stakeholder'] ?? '',
                                );
                                _searchController.clear();
                                provider.clearSuggestions();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 16),

                  // Selected Participants List
                  Text(
                    "Daftar Peserta yang Dipilih",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Palette.momsecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Consumer<MomsProvider>(
                      builder: (context, employeeProvider, child) {
                        if (employeeProvider.selectedEmployees.isEmpty) {
                          return Center(
                              child: Text("Tidak ada peserta yang dipilih"));
                        }
                        return ListView.builder(
                          itemCount: employeeProvider.selectedEmployees.length,
                          itemBuilder: (context, index) {
                            final selectedEmployee =
                                employeeProvider.selectedEmployees[index];
                            return ListTile(
                              title: Text(selectedEmployee.name ?? ''),
                              subtitle: Text(selectedEmployee.position ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: selectedEmployee
                                            .representative_signer ==
                                        1,
                                    onChanged: (bool? value) {
                                      employeeProvider
                                          .updateRepresentativeSigner(
                                              selectedEmployee.id,
                                              value == true ? 1 : 0);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      employeeProvider.removeEmployeeById(
                                          selectedEmployee.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Save Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedEmployees =
                            employeeProvider.selectedEmployees;
                        employeeProvider
                            .submitSelectedEmployees(selectedEmployees);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showAddEmployeeDialog(BuildContext context, MomsProvider provider) {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  int _representativeSigner = 0;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 8),
          Text(
            'Tambah Peserta Rapat Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: Container(
        width: 700,
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Nama wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'nik',
                  decoration: InputDecoration(
                    labelText: 'NIK',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "NIK wajib diisi"),
                    FormBuilderValidators.numeric(
                        errorText: "NIK harus berupa angka"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'position',
                  decoration: InputDecoration(
                    labelText: 'Position',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Position wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'stakeholder',
                  decoration: InputDecoration(
                    labelText: 'Stakeholder',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Stakeholder wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: "Email wajib diisi"),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: () async {
            if (_formKey.currentState!.saveAndValidate()) {
              final formData = _formKey.currentState!.value;

              // Add user audience and wait for completion
              await provider.addUserAudience(
                context,
                formData['name'],
                formData['nik'],
                formData['position'],
                formData['stakeholder'],
                formData['signing'] ?? '',
                0,
                formData['email'] ?? '',
              );

              await Provider.of<MomsProvider>(context, listen: false)
                  .fetchUserAudiences(context, 1, 10, '');

              Navigator.of(context).pop();
            }
          },
          icon: Icon(Icons.add, color: Palette.primary),
          label: const Text('Tambah'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.white,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Kembali', style: TextStyle(color: Palette.primary)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.white, // Change to desired color
          ),
        ),
      ],
    ),
  );
}

void _showSelectedEmployeesDrawer(BuildContext context) {
  final employeeProvider = Provider.of<MomsProvider>(context, listen: false);

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Peserta Rapat Terpilih",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                employeeProvider.selectedEmployees.length,
                            itemBuilder: (context, index) {
                              final employee =
                                  employeeProvider.selectedEmployees[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          Colors.grey.shade300, // Warna border
                                      width: 1, // Ketebalan border
                                    ),
                                  ),
                                  elevation: 0, // Menghilangkan shadow
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Nama Peserta",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                            "Nama", employee.name ?? 'N/A'),
                                        _buildInfoRow(
                                            "NIK", employee.nik ?? 'N/A'),
                                        _buildInfoRow("Position",
                                            employee.position ?? 'N/A'),
                                        _buildInfoRow("Stakeholder",
                                            employee.stakeholder ?? 'N/A'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Tutup",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Muncul dari kanan
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
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
  final initialDateParsed =
      initialDate.isNotEmpty ? DateTime.parse(initialDate) : DateTime.now();

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDateParsed,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (selectedDate != null) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    onSave(formattedDate);
  }
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCustomTextField({
  required String name,
  required String hintText,
  IconData? prefixIcon,
  IconData? suffixIcon,
}) {
  // Check if the field should be a date, time, or textarea type based on name
  if (name == 'tanggal') {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.date,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[300]!, size: 20)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[300]!, size: 20)
            : null,
      ),
      validator: FormBuilderValidators.required(),
    );
  } else if (name == 'Waktu') {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.time,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[300]!, size: 20)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[300]!, size: 20)
            : null,
      ),
      validator: FormBuilderValidators.required(),
    );
  } else if (name == 'Agenda') {
    return FormBuilderTextField(
      name: name,
      maxLines: 5, // Makes the input field a text area
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[300]!, size: 20)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[300]!, size: 20)
            : null,
      ),
      validator: FormBuilderValidators.required(),
    );
  } else {
    // Default text field if not date, time, or textarea
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey[300]!, size: 20)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[300]!, size: 20)
            : null,
      ),
      validator: FormBuilderValidators.required(),
    );
  }
}

Widget _buildTabItem(String label, {bool isActive = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 26.0),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Palette.momsecondary : Colors.black54,
          ),
        ),
        if (isActive)
          Container(
            margin: EdgeInsets.only(top: 4),
            height: 2,
            width: 80,
            color: Palette.momsecondary,
          ),
      ],
    ),
  );
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
      ConverterOptions
          .forEmail(), // Pilihan opsional, sesuaikan dengan kebutuhan
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
        QuillToolbar.simple(controller: quillController),
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
            // Konversi Delta menjadi HTML
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
