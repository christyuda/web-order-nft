import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webordernft/common/widget/btnwidget.dart';
import 'package:webordernft/config/palette.dart';
import 'package:webordernft/module/mom/provider/manager/moms_provider.dart';
import 'package:webordernft/module/mom/service/model/pin_listmeetings.dart';
import 'package:webordernft/module/mom/view/audience_sign.dart';
import 'package:webordernft/module/mom/view/detail_momV2.dart';
import 'package:webordernft/module/mom/view/meeting_calender.dart';
import 'package:webordernft/module/mom/view/mom_page.dart';

class ListMeetingsMom extends StatefulWidget {
  @override
  _ListMeetingsMomState createState() => _ListMeetingsMomState();
}

class _ListMeetingsMomState extends State<ListMeetingsMom> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Future<void> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _fetchMeetings();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMeetings({String term = ""}) async {
    await Provider.of<MomsProvider>(context, listen: false).fetchMeetings(
      context,
      ListMeetingRequest(page: 1, size: 10, term: term),
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _meetingsFuture = _fetchMeetings(term: _searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MomsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('List Meetings'),
        backgroundColor: Palette.bgcolor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Count Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CalendarCard(
                  meetingDates: provider.meetingDates,
                  meetingDetails: provider.meetingDetails,
                ),
                SizedBox(width: 16.0),
                _buildCountCard(
                    "Total Meetings", provider.totalMeetings, Colors.blue),
                SizedBox(width: 16.0),
              ],
            ),
            SizedBox(height: 16.0),

            // Search and Sort Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Find Task',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    items: [
                      DropdownMenuItem(
                          value: 'Sort by', child: Text('Sort by')),
                    ],
                    onChanged: (value) {},
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                SubmitButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MomPage(),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _meetingsFuture =
                            _fetchMeetings(); // Panggil ulang fungsi fetch
                      });
                    }
                  },
                  labelname: "Create Meeting",
                  icn: Icons.add, // Ikon tombol
                  clr: Palette.white, // Warna ikon
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Meeting List
            Expanded(
              child: FutureBuilder<void>(
                future: _meetingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Consumer<MomsProvider>(
                      builder: (context, provider, child) {
                        final meetingResponse = provider.meetingResponse;

                        if (provider.isLoading) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (meetingResponse == null ||
                            meetingResponse.data.meetings.isEmpty) {
                          return Center(child: Text("No meetings available"));
                        }

                        return ListView.builder(
                          itemCount: meetingResponse.data.meetings.length,
                          itemBuilder: (context, index) {
                            final meeting =
                                meetingResponse.data.meetings[index];
                            return _buildMeetingCard(context, meeting);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, dynamic meeting) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(DateTime.parse(meeting.date)),
                  style: TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
                Text(
                  DateFormat('dd').format(DateTime.parse(meeting.date)),
                  style: TextStyle(
                      fontSize: 28.0,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(meeting.time,
                          style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(meeting.place ?? 'Location not set',
                          style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    meeting.agenda ?? 'No Agenda',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'view_pdf') {
                  await Provider.of<MomsProvider>(context, listen: false)
                      .showPdfListPreview(context, meetingId: meeting.id);
                } else if (value == 'sign') {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(false),
                                child: Container(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: AudienceListPage(meetingId: meeting.id),
                            ),
                          ],
                        ),
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      opaque: false,
                    ),
                  );

                  if (result == true) {
                    setState(() {
                      _meetingsFuture =
                          _fetchMeetings(); // Memperbarui daftar rapat
                    });
                  }
                } else if (value == 'edit_material') {
                  Provider.of<MomsProvider>(context, listen: false)
                      .setIdMom(meeting.id);
                  final result = await Navigator.pushNamed(
                      context, 'MaterialAndCatatan',
                      arguments: meeting.id);
                  if (result == true) {
                    setState(() {
                      _meetingsFuture =
                          _fetchMeetings(); // Panggil ulang daftar rapat
                    });
                  }
                  // } else if (value == 'add_photo') {
                  //   // Navigator.pushNamed(context, 'AttachmentAndPhoto',
                  //   //     arguments: meeting.id);
                  //   final result = await Navigator.pushNamed(
                  //       context, 'AttachmentAndPhoto',
                  //       arguments: meeting.id);
                  //   if (result == true) {
                  //     setState(() {
                  //       _meetingsFuture =
                  //           _fetchMeetings(); // Panggil ulang daftar rapat
                  //     });
                  //   }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.grey),
                      SizedBox(width: 8.0),
                      Text('View PDF'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sign',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey),
                      SizedBox(width: 8.0),
                      Text('Sign'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit_material',
                  child: Row(
                    children: [
                      Icon(Icons.edit_document, color: Colors.grey),
                      SizedBox(width: 8.0),
                      Text('Isi Materi'),
                    ],
                  ),
                ),
                // PopupMenuItem(
                //   value: 'add_photo',
                //   child: Row(
                //     children: [
                //       Icon(Icons.add_a_photo, color: Colors.grey),
                //       SizedBox(width: 8.0),
                //       Text('Lampiran & Foto'),
                //     ],
                //   ),
                // ),
              ],
              icon: Icon(Icons.more_vert, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        height: 100.0,
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 24.0, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
