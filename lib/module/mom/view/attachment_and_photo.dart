import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:webordernft/common/widget/toast_message.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:webordernft/module/mom/service/model/pin_attachments_and_photo.dart';

class AddPhotoPage extends StatefulWidget {
  final int meetingId;

  const AddPhotoPage({Key? key, required this.meetingId}) : super(key: key);

  @override
  _AddPhotoPageState createState() => _AddPhotoPageState();
}

class _AddPhotoPageState extends State<AddPhotoPage> {
  final TextEditingController _attachmentController = TextEditingController();
  List<String> _attachmentLinks = [];
  List<Uint8List> _eventPhotos = [];

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _eventPhotos.addAll(result.files.map((file) => file.bytes!).toList());
      });
    }
  }

  void _addAttachmentLink() {
    final link = _attachmentController.text.trim();
    if (link.isNotEmpty) {
      setState(() {
        _attachmentLinks.add(link);
        _attachmentController.clear();
      });
    }
  }

  void _removeAttachmentLink(int index) {
    setState(() {
      _attachmentLinks.removeAt(index);
    });
  }

  void _removeEventPhoto(int index) {
    setState(() {
      _eventPhotos.removeAt(index);
    });
  }

  void _submitData(BuildContext context) async {
    if (_attachmentLinks.isEmpty && _eventPhotos.isEmpty) {
      SnackToastMessage(
        context,
        "Please add at least one attachment or photo.",
        ToastType.warning,
      );
      return;
    }

    // Create the request object
    final AddEventPhotosRequest request = AddEventPhotosRequest(
      idMom: widget.meetingId.toString(),
      attachments: _attachmentLinks,
      eventPhotos: _eventPhotos,
    );

    // Call the provider method
    final provider = Provider.of<MomsProvider>(context, listen: false);

    await provider.addEventPhotos(context, request);

    // Navigate back if successful
    if (!provider.isLoading) {
      Navigator.pop(context, true); // Return `true` to refresh parent page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Add Attachments & Photos",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Attachments
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Uploads",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _attachmentController,
                            decoration: InputDecoration(
                              hintText: "Enter attachment link",
                              fillColor: Colors.grey[200],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: _addAttachmentLink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _attachmentLinks.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading:
                                  const Icon(Icons.link, color: Colors.blue),
                              title: Text(
                                _attachmentLinks[index],
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeAttachmentLink(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Divider in the middle
              const VerticalDivider(width: 1, color: Colors.grey),
              const SizedBox(width: 16),
              // Right Column: Event Photos
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Event Photos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text("Pick Photos"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _eventPhotos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.memory(
                                  _eventPhotos[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeEventPhoto(index),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitData(context),
        label: const Text("Submit"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
