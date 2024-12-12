import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webordernft/config/networking.dart';
import 'package:webordernft/module/mom/service/model/list_audiences_request.dart';
import 'package:webordernft/module/mom/service/model/list_audiences_response.dart';
import 'package:webordernft/module/mom/service/model/pin_attachments_and_photo.dart';
import 'package:webordernft/module/mom/service/model/pin_delete_notes.dart';
import 'package:webordernft/module/mom/service/model/pin_detailistmeeting.dart';
import 'package:webordernft/module/mom/service/model/pin_duedate_notes.dart';
import 'package:webordernft/module/mom/service/model/pin_notes_bymom.dart';
import 'package:webordernft/module/mom/service/model/pin_ticketing_absen.dart';
import 'package:webordernft/module/mom/service/model/pin_update_pic.dart';
import 'package:webordernft/module/mom/service/model/pin_validate_ticketing.dart';
import 'package:webordernft/module/mom/service/model/response_attachments_and_photo.dart';
import 'package:webordernft/module/mom/service/model/response_delete_notes.dart';
import 'package:webordernft/module/mom/service/model/response_detaillistmeeting.dart';
import 'package:webordernft/module/mom/service/model/response_duedates_notes.dart';
import 'package:webordernft/module/mom/service/model/response_listmeetings.dart';
import 'package:webordernft/module/mom/service/model/response_listmom.dart';
import 'package:webordernft/module/mom/service/model/response_material_kesimpulan.dart';
import 'package:webordernft/module/mom/service/model/response_meeting.dart';
import 'package:webordernft/module/mom/service/model/response_notes_bymom.dart';
import 'package:webordernft/module/mom/service/model/response_ticketing_absen.dart';
import 'package:webordernft/module/mom/service/model/response_update_pic.dart';
import 'package:webordernft/module/mom/service/model/response_validate_ticketing.dart';
import 'package:webordernft/module/mom/service/model/send_mail_response.dart';
import 'package:webordernft/module/mom/service/model/sign_audiences_request.dart';
import 'package:webordernft/module/mom/service/model/sign_audiences_response.dart';

class MomService {
  static getMomServiceList(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/listUserAudiences';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    UserAudienceData result = UserAudienceData.fromJson(decodedData);

    return result;
  }

  static deleteNoteById(BuildContext context, DeleteNoteRequest params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    if (_token == null) {
      throw Exception("Token is not available. Please login again.");
    }

    String url = 'mom/deleteNoteById';
    String jsonInput = json.encode(params.toJson());

    print("Request JSON: $jsonInput");

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);

    DeleteNoteResponse result = DeleteNoteResponse.fromJson(decodedData);

    return result;
  }

  static Future<UpdateDueDateResponse> updateDueDate(
      BuildContext context, UpdateDueDateRequest params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    if (_token == null) {
      throw Exception("Token is not available. Please login again.");
    }

    String url = 'mom/updateDueDate'; // Endpoint sesuai dengan backend
    String jsonInput = json.encode(params.toJson());

    print("Request JSON: $jsonInput");

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);

    if (response.statusCode == 200) {
      UpdateDueDateResponse result = UpdateDueDateResponse.fromJson(decodedData);
      return result;
    } else {
      throw Exception(decodedData['error'] ?? 'Failed to update due date');
    }
  }

  static Future<AddNoteResponse> addNoteByIdMom(
      BuildContext context, AddNoteRequest params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    if (_token == null) {
      throw Exception("Token is not available. Please login again.");
    }

    String url = 'mom/addNoteByIdMom'; // Endpoint sesuai dengan backend
    String jsonInput = json.encode(params.toJson());

    print("Request JSON: $jsonInput");

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);

    if (response.statusCode == 201) {
      AddNoteResponse result = AddNoteResponse.fromJson(decodedData);
      return result;
    } else {
      throw Exception(decodedData['error'] ?? 'Failed to add note');
    }
  }

  static updatePIC(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/updatePIC';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    UpdatePicResponse result = UpdatePicResponse.fromJson(decodedData);
    return result;
  }


  static addUserAudience(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/addUserAudience';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    UserAudienceData result = UserAudienceData.fromJson(decodedData);
    return result;
  }

  static createMeetings(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/createMeeting';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    MeetingResponse result = MeetingResponse.fromJson(decodedData);
    return result;
  }

  static addMaterialsAndNotes(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/addMaterialAndNotes';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    MaterialResponse result = MaterialResponse.fromJson(decodedData);
    return result;
  }

  static listmeetings(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/listMeetings';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    ListMeetingResponse result = ListMeetingResponse.fromJson(decodedData);
    return result;
  }

   

   static signAudienceOnlineWithSignature(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = 'mom/signAudienceOnlineWithSignature';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, "");

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    ListMeetingResponse result = ListMeetingResponse.fromJson(decodedData);
    return result;
  }

  static sendMail(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/mail';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    EmailResponse result = EmailResponse.fromJson(decodedData);
    return result;
  }

  static Future<SignAudienceResponse?> signAudience(
      context, SignAudienceRequest request) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    String url = 'mom/signAudience';
    Map<String, String> fields = request.toFields();

    NetworkHelper networkHelper = NetworkHelper(url, '', token!);

    // Modify postRequestSignMultipart to accept Uint8List for signatureData
    Response response = await networkHelper.postRequestSign(
      context,
      fields,
      fileData: request.signatureData, // Use Uint8List data
      fileFieldName: 'signature',
    );

    if (response.statusCode == 200) {
      var decodedData =
          SignAudienceResponse.fromJson(json.decode(response.body));
      return decodedData;
    } else {
      print('Failed to sign audience: ${response.statusCode}');
      return null;
    }
  }

  // static Future<SignAudienceResponse?> signAudienceOnlineWithSignature(
  //     context, SignAudienceRequest request) async {
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final String? token = prefs.getString('token');
  //   print('signAudienceOnline token: $token');
  //   print('signAudienceOnline request: $request');
  //   String url = 'mom/signAudienceOnlineWithSignature';
  //   Map<String, String> fields = request.toFields();
  //   print('signAudienceOnline fields: $fields');
  //   NetworkHelper networkHelper = NetworkHelper(url, '{}', token!);
  //   Response response = await networkHelper.postRequestMultipart(
  //     context,
  //     // fields,
  //     // fileData: request.signatureData, // Use Uint8List data
  //     // fileFieldName: 'signature',
  //   );

  //   print(response);

  //   if (response.statusCode == 200) {
  //     var decodedData =
  //         SignAudienceResponse.fromJson(json.decode(response.body));
  //     return decodedData;
  //   } else {
  //     print('Failed to sign audience: ${response.statusCode}');
  //     return null;
  //   }
  // }

  static getAllAudiencesByMeetingId(context, params) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/getAllAudiencesByMeetingId';
    String jsonInput = json.encode(params);

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    ListAudiencesResponse result = ListAudiencesResponse.fromJson(decodedData);
    return result;
  }

  static generateTicket(context, PinTicketingAbsenRequest request) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _token = prefs.getString('token');

    String url = 'mom/generateTicket'; // Relative URL
    String jsonInput = json.encode(request.toJson());

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, _token!);

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    PinTicketingAbsenResponse result =
        PinTicketingAbsenResponse.fromJson(decodedData);

    return result;
  }

  static validateTicket(context, PinValidateTicketingRequest request) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = 'mom/validateTicket'; // Relative URL
    String jsonInput = json.encode(request.toJson());

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, '');

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    ResponseValidateTicketing result =
        ResponseValidateTicketing.fromJson(decodedData);

    return result;
  }

  static Future<GetMeetingByIdResponse> getMeetingById(
    context,
    GetMeetingByIdRequest request,
  ) async {
    String url = 'mom/getMeetingById'; // Relative URL
    String jsonInput = json.encode(request.toJson());

    print(jsonInput);

    NetworkHelper networkHelper = NetworkHelper(url, jsonInput, '');

    Response response = await networkHelper.postRequestHttp(context);

    var decodedData = json.decode(response.body);
    GetMeetingByIdResponse result =
        GetMeetingByIdResponse.fromJson(decodedData);

    return result;
  }

  static Future<AddEventPhotosResponse?> addEventPhotos(
      BuildContext context, AddEventPhotosRequest request) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    String url = 'mom/addEventPhotos';

    Map<String, String> fields = request.toFields();

    NetworkHelper networkHelper =
        NetworkHelper(url, json.encode(fields), token!);

    List<Uint8List> eventPhotos = request.eventPhotos;

    final response = await networkHelper.postRequestSignMultipart(
      context,
      fields,
      fileData: eventPhotos.isNotEmpty ? eventPhotos[0] : null,
      fileFieldName: 'event_photos[]',
    );

    if (response.statusCode == 201) {
      var decodedData =
          AddEventPhotosResponse.fromJson(json.decode(response.body));
      return decodedData;
    } else {
      print('Failed to add event photos: ${response.statusCode}');
      return null;
    }
  }
}
