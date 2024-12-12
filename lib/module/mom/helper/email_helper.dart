class EmailContentHelper {
  static String getRecipientType() {
    return "audiences";
  }

  static String getEmailSubject() {
    return "Test Email - Online Signature Verification";
  }

  // Updated to accept ticketing information
  static String getEmailContent(String ticketId) {
    return """
    <b>Thank you for participating in the event.</b><br>
    Your ticket ID is: <strong>$ticketId</strong>.<br>
    Please keep this ticket ID as it will be required for entry verification.
    """;
  }
}
