// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';
// import 'package:provider/provider.dart';
// import 'package:webordernft/common/widget/btnwidget.dart';
// import 'package:webordernft/config/palette.dart';
// import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';

// class SlidingPanelEmployees extends StatefulWidget {
//   @override
//   _SlidingPanelEmployeesState createState() => _SlidingPanelEmployeesState();
// }

// class _SlidingPanelEmployeesState extends State<SlidingPanelEmployees> {
//   final TextEditingController _textEditingController = TextEditingController();
//   Timer? _debounce;
//   late Future<void> _employeeFuture;

//   @override
//   void initState() {
//     super.initState();
//     _employeeFuture = _fetchEmployees();
//     _textEditingController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _textEditingController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _fetchEmployees({String term = ""}) async {
//     await Provider.of<MomsProvider>(context, listen: false)
//         .fetchUserAudiences(context, 1, 10, term);
//   }

//   void _onSearchChanged() {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         _employeeFuture = _fetchEmployees(term: _textEditingController.text);
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final employeeProvider = Provider.of<MomsProvider>(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: GestureDetector(
//         onTap: () => Navigator.pop(context),
//         child: Stack(
//           children: [
//             Align(
//               alignment: Alignment.centerRight,
//               child: Material(
//                 color: Colors.transparent,
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.5,
//                   padding: EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: const Color.fromARGB(255, 254, 255, 255),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Pilih Peserta Rapat",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Palette.momsecondary,
//                           ),
//                         ),
//                         SizedBox(height: 20),
//                         _buildSearchBar(context),
//                         SizedBox(height: 16),
//                         FutureBuilder<void>(
//                           future: _employeeFuture,
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState ==
//                                 ConnectionState.waiting) {
//                               return Center(child: CircularProgressIndicator());
//                             }
//                             if (snapshot.hasError) {
//                               return Center(
//                                   child: Text('Error: ${snapshot.error}'));
//                             }
//                             if (employeeProvider.suggestions.isEmpty) {
//                               return Center(
//                                   child:
//                                       Text("Masukkan nama atau nik peserta"));
//                             }
//                             return ListView.builder(
//                               shrinkWrap: true,
//                               itemCount: employeeProvider.suggestions.length,
//                               itemBuilder: (context, index) {
//                                 final suggestion =
//                                     employeeProvider.suggestions[index];
//                                 return _buildSuggestionItem(
//                                     suggestion, employeeProvider);
//                               },
//                             );
//                           },
//                         ),
//                         SizedBox(height: 16),
//                         _buildSelectedParticipantList(context),
//                         SizedBox(height: 16),
//                         _buildSaveButton(context, employeeProvider),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: _textEditingController,
//             decoration: InputDecoration(
//               hintText: "Cari nama, nik, jabatan, stakeholder",
//               prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
//               filled: true,
//               fillColor: Colors.white,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.black),
//               ),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//             ),
//           ),
//         ),
//         SizedBox(width: 8),
//         ElevatedButton.icon(
//           onPressed: () {
//             final provider =
//                 Provider.of<MomsProvider>(context, listen: false);
//             _showAddEmployeeDialog(context, provider);
//           },
//           icon: Icon(Icons.add, color: Colors.white),
//           label: Text("Tambah Peserta", style: TextStyle(color: Colors.white)),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Palette.primary,
//             padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSuggestionItem(
//       Map<String, dynamic> suggestion, MomsProvider provider) {
//     final id = suggestion['id'] ?? "";
//     final name = suggestion['name'] ?? '';
//     final position = suggestion['position'] ?? '';
//     final nik = suggestion['nik'] ?? '';
//     final stakeholder = suggestion['stakeholder'] ?? '';

//     return InkWell(
//       onTap: () {
//         _textEditingController.clear();
//         provider.addEmployeeById(
//             int.parse(id), name, position, nik, stakeholder);
//         provider.clearSuggestions();
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//         child: Row(
//           children: [
//             Icon(Icons.person, color: Colors.grey.shade600),
//             SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black87),
//                 ),
//                 Text(
//                   position,
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSelectedParticipantList(BuildContext context) {
//     return Consumer<MomsProvider>(
//       builder: (context, employeeProvider, child) {
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: employeeProvider.selectedEmployees.length,
//             itemBuilder: (context, index) {
//               final selectedEmployee =
//                   employeeProvider.selectedEmployees[index];
//               return ListTile(
//                 title: Text(selectedEmployee.name ?? 'Peserta ${index + 1}'),
//                 subtitle:
//                     Text(selectedEmployee.position ?? 'Position ${index + 1}'),
//                 trailing: IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   onPressed: () {
//                     employeeProvider
//                         .removeEmployeeById(selectedEmployee.id);
//                   },
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSaveButton(BuildContext context, MomsProvider provider) {
//     return Align(
//       alignment: Alignment.bottomRight,
//       child: ElevatedButton(
//         onPressed: () {
//           provider.submitSelectedEmployees(provider.selectedEmployees);
//           Navigator.pop(context);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Palette.primary,
//           padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         child: Text("Simpan", style: TextStyle(color: Colors.white)),
//       ),
//     );
//   }


// void _showAddEmployeeDialog(BuildContext context, MomsProvider provider) {
//   final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
//   int _representativeSigner = 0;
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       title: Row(
//         children: [
//           Icon(
//             Icons.person_add,
//             color: Theme.of(context).primaryColor,
//           ),
//           SizedBox(width: 8),
//           Text(
//             'Tambah Peserta Rapat Baru',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//           ),
//         ],
//       ),
//       content: Container(
//         width: 700,
//         child: SingleChildScrollView(
//           child: FormBuilder(
//             key: _formKey,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 FormBuilderTextField(
//                   name: 'name',
//                   decoration: InputDecoration(
//                     labelText: 'Name',
//                     prefixIcon: Icon(Icons.person),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   validator: FormBuilderValidators.compose([
//                     FormBuilderValidators.required(
//                         errorText: "Nama wajib diisi"),
//                   ]),
//                 ),
//                 SizedBox(height: 10),
//                 FormBuilderTextField(
//                   name: 'nik',
//                   decoration: InputDecoration(
//                     labelText: 'NIK',
//                     prefixIcon: Icon(Icons.badge),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   keyboardType: TextInputType.number,
//                   validator: FormBuilderValidators.compose([
//                     FormBuilderValidators.required(
//                         errorText: "NIK wajib diisi"),
//                     FormBuilderValidators.numeric(
//                         errorText: "NIK harus berupa angka"),
//                   ]),
//                 ),
//                 SizedBox(height: 10),
//                 FormBuilderTextField(
//                   name: 'position',
//                   decoration: InputDecoration(
//                     labelText: 'Position',
//                     prefixIcon: Icon(Icons.work),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   validator: FormBuilderValidators.compose([
//                     FormBuilderValidators.required(
//                         errorText: "Position wajib diisi"),
//                   ]),
//                 ),
//                 SizedBox(height: 10),
//                 FormBuilderTextField(
//                   name: 'stakeholder',
//                   decoration: InputDecoration(
//                     labelText: 'Stakeholder',
//                     prefixIcon: Icon(Icons.work),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   validator: FormBuilderValidators.compose([
//                     FormBuilderValidators.required(
//                         errorText: "Stakeholder wajib diisi"),
//                   ]),
//                 ),
//                 SizedBox(height: 10),
//                 FormBuilderTextField(
//                   name: 'email',
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     prefixIcon: Icon(Icons.work),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   validator: FormBuilderValidators.compose([
//                     FormBuilderValidators.required(
//                         errorText: "Email wajib diisi"),
//                   ]),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       actions: <Widget>[
//         ElevatedButton.icon(
//           onPressed: () async {
//             if (_formKey.currentState!.saveAndValidate()) {
//               final formData = _formKey.currentState!.value;

//               // Add user audience and wait for completion
//               await provider.addUserAudience(
//                 context,
//                 formData['name'],
//                 formData['nik'],
//                 formData['position'],
//                 formData['stakeholder'],
//                 formData['signing'] ?? '',
//                 0,
//                 formData['email'] ?? '',
//               );

//               await Provider.of<MomsProvider>(context, listen: false)
//                   .fetchUserAudiences(context, 1, 10, '');

//               Navigator.of(context).pop();
//             }
//           },
//           icon: Icon(Icons.add, color: Palette.primary),
//           label: const Text('Tambah'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Palette.white,
//           ),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: Text('Kembali', style: TextStyle(color: Palette.primary)),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Palette.white, // Change to desired color
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }