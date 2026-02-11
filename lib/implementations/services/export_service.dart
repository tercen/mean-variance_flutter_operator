import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:js_interop';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

/// Service for exporting chart content as PNG or PDF.
/// Uses RepaintBoundary capture + browser download via package:web.
class ExportService {
  /// Capture a RepaintBoundary as PNG bytes at the given export width.
  /// Height scales proportionally to preserve aspect ratio.
  static Future<Uint8List?> capturePng(
    RenderRepaintBoundary boundary,
    int exportWidth,
  ) async {
    final pixelRatio = exportWidth / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return byteData.buffer.asUint8List();
  }

  /// Export as PNG: capture boundary and trigger browser download.
  static Future<void> exportPng(
    RenderRepaintBoundary boundary,
    int exportWidth,
  ) async {
    final pngBytes = await capturePng(boundary, exportWidth);
    if (pngBytes == null) return;
    _triggerDownload(pngBytes, 'mean_variance_chart.png', 'image/png');
  }

  /// Export as PDF: capture boundary as PNG, embed in a PDF page, download.
  static Future<void> exportPdf(
    RenderRepaintBoundary boundary,
    int exportWidth,
  ) async {
    final pngBytes = await capturePng(boundary, exportWidth);
    if (pngBytes == null) return;

    // Calculate dimensions preserving aspect ratio
    final aspectRatio = boundary.size.height / boundary.size.width;
    final pdfWidth = exportWidth.toDouble();
    final pdfHeight = pdfWidth * aspectRatio;

    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat(pdfWidth, pdfHeight),
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Image(image, fit: pw.BoxFit.contain),
    ));

    final pdfBytes = await pdf.save();
    _triggerDownload(
      Uint8List.fromList(pdfBytes),
      'mean_variance_chart.pdf',
      'application/pdf',
    );
  }

  /// Trigger a file download in the browser using package:web.
  static void _triggerDownload(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) {
    final jsArray = bytes.toJS;
    final blob = web.Blob(
      [jsArray].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
