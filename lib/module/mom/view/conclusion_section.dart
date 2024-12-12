import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/provider/manager/list_audiences_provider.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:webordernft/module/mom/service/model/pin_material_kesimpulan.dart';

class ConclusionSection extends StatelessWidget {
  final TextEditingController conclusionController;
  final int idMom;

  const ConclusionSection({
    Key? key,
    required this.conclusionController,
    required this.idMom,
  }) : super(key: key);

  
  void _showEditDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required Function(String) onSave,
}) {
  final TextEditingController controller = TextEditingController(text: initialValue);

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
void _addNoteToProvider(BuildContext context) async {
    final provider = Provider.of<MomsProvider>(context, listen: false);
    final noteText = conclusionController.text;

    if (noteText.isEmpty) {
      // Tampilkan pesan jika input kosong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tindak lanjut tidak boleh kosong."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await provider.addNote(
        context,
        idMom.toString(), // ID MOM
        noteText,
        
        
      );

      conclusionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tindak lanjut berhasil ditambahkan."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Tampilkan pesan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambahkan tindak lanjut: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MomsProvider>(context);

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
          Text(
            "Tindak Lanjut *",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: conclusionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: "Silahkan Tuliskan Disini",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
              _addNoteToProvider(context);
              },
              child: Text(
                "Tambah Tindak Lanjut",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: DataTable(
                columnSpacing: 12,
                columns: [
                  DataColumn(label: SizedBox(width: 30, child: Text('No'))),
                  DataColumn(label: Text('Tindak Lanjut')),
                  DataColumn(label: SizedBox(width: 100, child: Text('PIC'))),
                  DataColumn(label: SizedBox(width: 100, child: Text('Due Date'))),
                  DataColumn(label: SizedBox(width: 60, child: Text('Actions'))),
                ],
                rows: List<DataRow>.generate(
                  provider.finalizedList.length,
                  (index) {
                    final catatan = provider.finalizedList[index];
                    return DataRow(
                      cells: [
                        DataCell(
                            SizedBox(width: 30, child: Text('${index + 1}'))),
                        DataCell(Text(catatan['catatan'] ?? '')),
                        DataCell(
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _showEditDialog(
                            context: context,
                            title: "Edit PIC",
                            initialValue: catatan['pic'] ?? '',
                            onSave: (value) {
                              // Memanggil fungsi dari provider
                              Provider.of<MomsProvider>(context, listen: false)
                                  .updatedPIC(
                                context,
                                provider.idMom.toString(), // ID MOM dari provider
                                catatan['id'].toString(), // ID dari catatan
                                value,
                              );
                            },
                          );
                        },
                        child: Text(
                          catatan['pic']?.isNotEmpty ?? false ? catatan['pic'] : 'Edit PIC',
                          style: TextStyle(color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditDialog(
                          context: context,
                          title: "Edit PIC",
                          initialValue: catatan['pic'] ?? '',
                          onSave: (value) {
                            
                            Provider.of<MomsProvider>(context, listen: false)
                                .updatedPIC(
                              context,
                              provider.idMom.toString(), // ID MOM dari provider
                              catatan['id'].toString(), // ID dari catatan
                              value,
                            );
                          },
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
                      child: InkWell(
                        onTap: () {
                          _showDatePickerDialog(
                            context: context,
                            initialDate: catatan['dueDate'] ?? '',
                            onSave: (selectedDate) {
                            
                              Provider.of<MomsProvider>(context, listen: false)
                                  .updateDueDates(
                                context,
                                provider.idMom.toString(), // Pastikan idMom tersedia di provider
                                catatan['id'].toString(), // ID dari catatan
                                selectedDate,
                              );
                            },
                          );
                        },
                        child: Text(
                          catatan['dueDate']?.isNotEmpty ?? false
                              ? catatan['dueDate']
                              : 'Select Date',
                          style: TextStyle(color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: Colors.blue),
                      onPressed: () {
                        _showDatePickerDialog(
                          context: context,
                          initialDate: catatan['dueDate'] ?? '',
                          onSave: (selectedDate) {
                                                   
                                  Provider.of<MomsProvider>(context, listen: false)
                                .updateDueDates(
                              context,
                              provider.idMom.toString(), // Pastikan idMom tersedia di provider
                              catatan['id'].toString(), // ID dari catatan
                              selectedDate,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),


                        DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final provider = Provider.of<MomsProvider>(context, listen: false);

                            // Ambil ID notes dari finalizedList
                            final noteId = provider.finalizedList[index]['id'];
                            if (noteId == null) {
                              SnackToastMessage(
                                context,
                                "ID catatan tidak ditemukan.",
                                ToastType.error,
                              );
                              return;
                            }

                            try {
                               provider.deleteNote(
                                context,
                                provider.idMom.toString(), // ID MOM dari provider
                                noteId.toString(), // ID notes
                              );

                              // Hapus dari finalizedList setelah berhasil
                              provider.removeFromFinalized(index);

                              SnackToastMessage(
                                context,
                                "Catatan berhasil dihapus.",
                                ToastType.success,
                              );
                            } catch (e) {
                              SnackToastMessage(
                                context,
                                "Gagal menghapus catatan: $e",
                                ToastType.error,
                              );
                            }
                          },
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
