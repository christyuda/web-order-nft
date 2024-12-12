import 'dart:convert';

class EmailRequest {
  final List<String> emails;
  final String to;
  final String subject;
  final String content;

  EmailRequest({
    required this.emails,
    required this.to,
    required this.subject,
    required this.content,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'emails': emails,
      'to': to,
      'subject': subject,
      'content': content,
    };
  }

  // Convert from JSON
  factory EmailRequest.fromJson(Map<String, dynamic> json) {
    return EmailRequest(
      emails: List<String>.from(json['emails']),
      to: json['to'],
      subject: json['subject'],
      content: json['content'],
    );
  }

  // Convert to JSON string
  String toJsonString() => jsonEncode(toJson());
}
