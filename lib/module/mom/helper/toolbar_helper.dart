import 'dart:convert';
import 'dart:typed_data';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/dom.dart' as dom;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Main function to parse HTML into PDF widgets
List<pw.Widget> parseHtmlToPdfWidgets(dom.Element? element) {
  if (element == null) return [];

  final unescape = HtmlUnescape(); // For decoding HTML entities
  List<pw.Widget> widgets = [];

  for (var node in element.nodes) {
    if (node is dom.Text) {
      // Clean text from special characters and HTML entities
      String cleanedText = _cleanText(unescape.convert(node.text));
      if (cleanedText.isNotEmpty) {
        widgets.add(
          pw.Text(
            cleanedText,
            style: pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }
    } else if (node is dom.Element) {
      switch (node.localName) {
        case 'p':
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                _cleanText(unescape.convert(node.text)),
                style: _getTextStyle(node),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          );
          break;
        case 'br': // Handle <br>
          widgets.add(pw.SizedBox(height: 4));
          break;
        case 'b':
        case 'strong':
          widgets.add(
            pw.Text(
              _cleanText(unescape.convert(node.text)),
              style:
                  _getTextStyle(node).copyWith(fontWeight: pw.FontWeight.bold),
            ),
          );
          break;
        case 'i':
        case 'em':
          widgets.add(
            pw.Text(
              _cleanText(unescape.convert(node.text)),
              style:
                  _getTextStyle(node).copyWith(fontStyle: pw.FontStyle.italic),
            ),
          );
          break;
        case 'u':
          widgets.add(
            pw.Text(
              _cleanText(unescape.convert(node.text)),
              style: _getTextStyle(node)
                  .copyWith(decoration: pw.TextDecoration.underline),
            ),
          );
          break;
        case 'strike':
        case 'del':
          widgets.add(
            pw.Text(
              _cleanText(unescape.convert(node.text)),
              style: _getTextStyle(node)
                  .copyWith(decoration: pw.TextDecoration.lineThrough),
            ),
          );
          break;
        case 'ul':
          widgets
              .addAll(_handleList(node, isOrdered: false, unescape: unescape));
          break;
        case 'ol':
          widgets
              .addAll(_handleList(node, isOrdered: true, unescape: unescape));
          break;
        case 'blockquote':
          widgets.add(
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey, width: 4)),
                color: PdfColors.grey200,
              ),
              child: pw.Text(
                _cleanText(unescape.convert(node.text)),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          );
          break;
        case 'code': // Handle <code> for code blocks
          widgets.add(
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _cleanText(unescape.convert(node.text)),
                style: pw.TextStyle(fontSize: 12, font: pw.Font.courier()),
              ),
            ),
          );
          break;
        case 'img': // Handle <img> for inserting images
          if (node.attributes['src'] != null) {
            widgets.add(
              pw.Image(
                pw.MemoryImage(Uint8List.fromList(
                    _decodeBase64Image(node.attributes['src']!))),
                fit: pw.BoxFit.contain,
                height: 150,
                width: 150,
              ),
            );
          }
          break;
        case 'a': // Handle <a> for links
          widgets.add(
            pw.UrlLink(
              destination: node.attributes['href'] ?? '',
              child: pw.Text(
                _cleanText(unescape.convert(node.text)),
                style: _getTextStyle(node).copyWith(
                  decoration: pw.TextDecoration.underline,
                  color: PdfColors.blue,
                ),
              ),
            ),
          );
          break;
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6': // Handle headers
          widgets.add(
            pw.Text(
              _cleanText(unescape.convert(node.text)),
              style: _getTextStyle(node).copyWith(
                fontSize: _getFontSize(node.localName),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          break;
        default:
          widgets.addAll(parseHtmlToPdfWidgets(node)); // Recursive parsing
      }
    }
  }

  return widgets;
}

/// Clean text from special characters, spaces, and HTML entities
String _cleanText(String text) {
  return text
      .replaceAll(RegExp(r'\s+'), ' ') // Remove excessive spaces
      .replaceAll('\u00A0', ' ') // Remove non-breaking spaces
      .trim(); // Remove leading and trailing spaces
}

/// Handle list elements (ul and ol)
List<pw.Widget> _handleList(dom.Element node,
    {required bool isOrdered, required HtmlUnescape unescape}) {
  List<pw.Widget> widgets = [];
  int index = 1;

  for (var child in node.children) {
    String cleanedText = _cleanText(unescape.convert(child.text));
    if (cleanedText.isNotEmpty) {
      if (isOrdered) {
        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("$index. ", style: pw.TextStyle(fontSize: 12)),
              pw.Expanded(
                child: pw.Text(
                  cleanedText,
                  style: pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          ),
        );
        index++;
      } else {
        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("• ",
                  style: pw.TextStyle(
                      font: pw.Font.symbol(), fontSize: 12)), // Bullet symbol
              pw.Expanded(
                child: pw.Text(
                  cleanedText,
                  style: pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  return widgets;
}

/// Get text style
/// Get text style with inline styles
pw.TextStyle _getTextStyle(dom.Element node) {
  // Extracting custom styles from attributes
  final fontSize = double.tryParse(node.attributes['font-size'] ?? '12') ?? 12;
  final fontWeight = node.attributes['font-weight'] == 'bold'
      ? pw.FontWeight.bold
      : pw.FontWeight.normal;
  final fontStyle = node.attributes['font-style'] == 'italic'
      ? pw.FontStyle.italic
      : pw.FontStyle.normal;
  final textDecoration = node.attributes['text-decoration'] == 'underline'
      ? pw.TextDecoration.underline
      : node.attributes['text-decoration'] == 'line-through'
          ? pw.TextDecoration.lineThrough
          : pw.TextDecoration.none;

  // Handling additional inline styles (e.g., indent, direction, and list styles)
  final indent = double.tryParse(node.attributes['indent'] ?? '0') ?? 0;
  final isRtl = node.attributes['direction'] == 'rtl';
  final paddingSide = isRtl ? 'padding-right' : 'padding-left';
  final listStyle = node.attributes['list'] == 'checked'
      ? "• "
      : node.attributes['list'] == 'unchecked'
          ? "◦ "
          : null;

  // Set up padding or margin for indentation
  final padding = indent > 0 ? '$paddingSide:${indent * 3}px;' : '';

  // Inline style attribute handling
  String? colorHex = node.attributes['color'];
  PdfColor color = PdfColors.black; // Default color
  if (colorHex != null && colorHex.startsWith('#')) {
    color = PdfColor.fromInt(
      int.tryParse(colorHex.replaceFirst('#', '0xFF') ?? '0xFF000000') ??
          0xFF000000,
    );
  }

  return pw.TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    decoration: textDecoration,
    color: color,
  );
}

/// Get font size based on heading tag
double _getFontSize(String? tag) {
  switch (tag) {
    case 'h1':
      return 24;
    case 'h2':
      return 22;
    case 'h3':
      return 20;
    case 'h4':
      return 18;
    case 'h5':
      return 16;
    case 'h6':
      return 14;
    default:
      return 12;
  }
}

/// Decode Base64 images
List<int> _decodeBase64Image(String base64String) {
  if (base64String.startsWith('data:image')) {
    return UriData.parse(base64String).contentAsBytes();
  }
  return base64.decode(base64String);
}
