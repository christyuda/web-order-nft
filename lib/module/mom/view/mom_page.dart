import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/provider/manager/list_audiences_provider.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';

class MomPage extends StatefulWidget {
  @override
  _MomPageState createState() => _MomPageState();
  }
Widget _buildTambahPesertaDialog(BuildContext context, ListPesertaProvider listPesertaProvider) {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  return Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width * 0.9, // Lebar 90% dari layar
      constraints: BoxConstraints(
        maxWidth: 500, // Maksimal lebar 500px
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Tambah Peserta",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'Nama *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: "Nama wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'nik',
                  decoration: InputDecoration(
                    labelText: 'NIK *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: "NIK wajib diisi"),
                    FormBuilderValidators.numeric(errorText: "NIK harus berupa angka"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'position',
                  decoration: InputDecoration(
                    labelText: 'Jabatan *',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: "Jabatan wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'stakeholder',
                  decoration: InputDecoration(
                    labelText: 'Stakeholder *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: "Stakeholder wajib diisi"),
                  ]),
                ),
                SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'email',
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: "Email wajib diisi"),
                    FormBuilderValidators.email(errorText: "Format email tidak valid"),
                  ]),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.saveAndValidate()) {
                    final formData = _formKey.currentState!.value;

                    await listPesertaProvider.addUserAudience(
                      context,
                      formData['name'],
                      formData['nik'],
                      formData['position'],
                      formData['stakeholder'],
                      '',
                      1,
                      formData['email'],
                    );

                    Navigator.of(context).pop(); // Tutup form setelah sukses
                  }
                },
                child: Text(
                  "Tambah",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


class _MomPageState extends State<MomPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _debounce;
  late Future<void> _employeeFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _employeeFuture = _fetchEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchEmployees({String term = ""}) async {
    await Provider.of<MomsProvider>(context, listen: false)
        .fetchUserAudiences(context, 1, 10, term);
  }
 void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final term = _searchController.text.trim();
      if (term.length >= 3) {
        Provider.of<ListPesertaProvider>(context, listen: false)
            .fetchUserAudiences(context, 1, 10, term);
      } else {
        Provider.of<ListPesertaProvider>(context, listen: false)
            .fetchUserAudiences(context, 1, 10, ""); // Kosongkan data jika < 3
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
 _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buat MOM"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<ListPesertaProvider>(context, listen: false)
            .clearSelectedAudiences();
            Navigator.pop(context, true); // Kirim `true` sebagai hasil
          },
        ),
        backgroundColor: Palette.bgcolor,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Peserta Daftar Hadir"),
            Tab(text: "MOM"),
            // Tab(text: "Tambah Peserta"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListPesertaTab(),
          _buildBuatMomTab(),
          _buildTambahPesertaTab(),
        ],
      ),
    );
  }

Widget _buildBuatMomTab() {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Meeting",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: "Penulis",
                      decoration: InputDecoration(
                        labelText: "Penulis *",
                        hintText: "Masukkan nama penulis",
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: "Hari / Tanggal",
                      decoration: InputDecoration(
                        labelText: "Hari / Tanggal *",
                        hintText: "Pilih hari / tanggal",
                        border: OutlineInputBorder(),
                      ),
                      format: DateFormat('yyyy-MM-dd'),
                      inputType: InputType.date,
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: "Waktu",
                      decoration: InputDecoration(
                        labelText: "Waktu *",
                        hintText: "Masukkan waktu",
                        border: OutlineInputBorder(),
                      ),
                      format: DateFormat('HH:mm'),
                      inputType: InputType.time,
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderTextField(
                      name: "Tempat Rapat",
                      decoration: InputDecoration(
                        labelText: "Tempat Rapat *",
                        hintText: "Masukkan tempat rapat",
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              FormBuilderTextField(
                name: "Agenda",
                decoration: InputDecoration(
                  labelText: "Agenda *",
                  hintText: "Masukkan agenda rapat",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: FormBuilderValidators.required(),
              ),
            ],
          ),
        ),
        Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<ListPesertaProvider>(context, listen: false);

              // Validasi form sebelum membuat meeting
              if (_formKey.currentState?.saveAndValidate() ?? false) {
                final author = _formKey.currentState?.fields['Penulis']?.value ?? '';
                final date = DateFormat('yyyy-MM-dd').format(
                    _formKey.currentState?.fields['Hari / Tanggal']?.value ?? DateTime.now());
                final time = DateFormat('HH:mm').format(
                    _formKey.currentState?.fields['Waktu']?.value ?? DateTime.now());
                final place = _formKey.currentState?.fields['Tempat Rapat']?.value ?? '';
                final agenda = _formKey.currentState?.fields['Agenda']?.value ?? '';
                final discussionMaterial = ""; // Contoh data materi
                final List<Map<String, dynamic>> notes = [];

                await provider.createMeeting(
                  context,
                  author: author,
                  date: date,
                  time: time,
                  place: place,
                  agenda: agenda,
                  notes: notes,
                  discussionMaterial: discussionMaterial,
                );
              } else {
                SnackToastMessage(
                  context,
                  "Form tidak valid, periksa kembali isian Anda.",
                  ToastType.warning,
                );
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
          ),
        ),
      ],
    ),
  );
}

Widget _buildListPesertaTab() {
  final TextEditingController _searchController = TextEditingController();

  return Consumer<ListPesertaProvider>(
    builder: (context, listPesertaProvider, child) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.length < 3) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      listPesertaProvider.fetchUserAudiences(
                        context,
                        1,
                        10,
                        textEditingValue.text,
                      );

                      return listPesertaProvider.audiences.where((audience) {
                        return !listPesertaProvider.selectedAudiences.any(
                            (selected) => selected['id'] == audience['id']);
                      });
                    },
                    displayStringForOption: (Map<String, dynamic> option) =>
                        option['name'] ?? 'Nama Tidak Ditemukan',
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8, // Sesuaikan dengan TextField
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.3, // Maksimal tinggi list
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final suggestion = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    suggestion['name'] ?? 'Nama Tidak Tersedia',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    suggestion['position'] ??
                                        'Jabatan Tidak Tersedia',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add, color: Colors.blue),
                                    onPressed: () {
                                      listPesertaProvider.addToSelected(
                                          context, suggestion);
                                      onSelected(suggestion); // Hapus opsi setelah dipilih
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText:
                              "Cari berdasarkan NIK, nama, atau posisi...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: Icon(Icons.search),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _buildTambahPesertaDialog(
                            context, listPesertaProvider);
                      },
                    );
                  },
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Tambah Peserta", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Daftar Peserta Terpilih",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: listPesertaProvider.selectedAudiences.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada peserta yang dipilih.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          listPesertaProvider.selectedAudiences.length,
                      itemBuilder: (context, index) {
                        final selected =
                            listPesertaProvider.selectedAudiences[index];
                        return ListTile(
                          title: Text(selected['name'] ?? 'Nama Tidak Tersedia'),
                          subtitle:
                              Text(selected['position'] ?? 'Jabatan Tidak Tersedia'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: selected['representative_signer'] == 1,
                                onChanged: (bool? value) {
                                  listPesertaProvider.updateCheckboxStatus(
                                    selected['id'],
                                    value ?? false,
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: () {
                                  listPesertaProvider
                                      .removeFromSelected(selected);
                                  SnackToastMessage(
                                    context,
                                    "Peserta berhasil dihapus dari daftar terpilih.",
                                    ToastType.info,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  if (listPesertaProvider.selectedAudiences.isNotEmpty) {
                    SnackToastMessage(
                      context,
                      "Daftar peserta terpilih berhasil disimpan.",
                      ToastType.success,
                    );
                  } else {
                    SnackToastMessage(
                      context,
                      "Tidak ada peserta yang dipilih.",
                      ToastType.warning,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primary,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  "Simpan Daftar Peserta",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  







 Widget _buildSuggestionItem(
    Map<String, dynamic> suggestion, MomsProvider provider) {
  return ListTile(
    title: Text(suggestion['name'] ?? 'Nama Tidak Tersedia'),
    subtitle: Text(suggestion['position'] ?? 'Jabatan Tidak Tersedia'),
    trailing: IconButton(
      icon: Icon(Icons.add, color: Colors.blue),
      onPressed: () {
        // Memastikan context yang benar digunakan untuk fungsi addEmployeeById
        provider.addEmployeeById(
          context: context, // Pastikan context diberikan
          id: int.tryParse(suggestion['id'] ?? '0') ?? 0,
          name: suggestion['name'] ?? '',
          position: suggestion['position'] ?? '',
          nik: suggestion['nik'] ?? '',
          stakeholder: suggestion['stakeholder'] ?? '',
        );
        provider.clearSuggestions();
      },
    ),
  );
}

  Widget _buildTambahPesertaTab() {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tambah Peserta",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(
                  labelText: 'Nama *',
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
                  labelText: 'NIK *',
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
                  labelText: 'Jabatan *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                      errorText: "Jabatan wajib diisi"),
                ]),
              ),
              SizedBox(height: 10),
              FormBuilderTextField(
                name: 'stakeholder',
                decoration: InputDecoration(
                  labelText: 'Stakeholder *',
                  prefixIcon: Icon(Icons.business),
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
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                      errorText: "Email wajib diisi"),
                  FormBuilderValidators.email(
                      errorText: "Format email tidak valid"),
                ]),
              ),
            ],
          ),
        ),
        Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton.icon(
  onPressed: () async {
    if (_formKey.currentState!.saveAndValidate()) {
      final formData = _formKey.currentState!.value;

      final provider = Provider.of<ListPesertaProvider>(context, listen: false);
      await provider.addUserAudience(
        context,
        formData['name'],
        formData['nik'],
        formData['position'],
        formData['stakeholder'],
        '', 
        0,
        formData['email'],
      );

      Navigator.of(context).pop(); // Tutup form setelah sukses
    }
  },
  icon: Icon(Icons.add, color: Colors.white),
  label: Text(
    'Tambah',
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Palette.primary,
    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),

        ),
      ],
    ),
  );
}


  Widget _buildLabeledField(String label, String hint,
      {bool isDate = false, bool isTime = false, bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        isDate
            ? TextField(
                decoration: InputDecoration(
                  hintText: hint,
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                },
              )
            : isTime
                ? TextField(
                    decoration: InputDecoration(
                      hintText: hint,
                      suffixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () {
                      showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                    },
                  )
                : TextField(
                    maxLines: isLarge ? 5 : 1,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(),
                    ),
                  ),
      ],
    );
  }
  
}


