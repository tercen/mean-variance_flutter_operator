import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:js_interop';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

/// Service for exporting chart content as PNG or PDF.
/// Uses RepaintBoundary capture + browser download via package:web.
///
/// Export dimensions are per-pane: a 600×400 setting with a 2×3 grid
/// produces an image approximately 1200px wide × scaled height,
/// where each chart pane is ~600px wide in the output.
class ExportService {
  /// Capture a RepaintBoundary as PNG bytes, scaled so each chart pane
  /// is [perPaneWidth] pixels wide in the output image.
  static Future<Uint8List?> capturePng(
    RenderRepaintBoundary boundary, {
    required int perPaneWidth,
    required int nColumns,
  }) async {
    // Scale so that each pane column is perPaneWidth pixels in the output.
    // The boundary renders the full grid, so total target width ≈ nColumns * perPaneWidth.
    final pixelRatio = (nColumns * perPaneWidth) / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return byteData.buffer.asUint8List();
  }

  /// Export as PNG: capture boundary and trigger browser download.
  static Future<void> exportPng(
    RenderRepaintBoundary boundary, {
    required int perPaneWidth,
    required int nColumns,
  }) async {
    final pngBytes = await capturePng(
      boundary,
      perPaneWidth: perPaneWidth,
      nColumns: nColumns,
    );
    if (pngBytes == null) return;
    _triggerDownload(pngBytes, 'mean_variance_chart.png', 'image/png');
  }

  /// Export as PDF: capture boundary as PNG, embed in a PDF page, download.
  static Future<void> exportPdf(
    RenderRepaintBoundary boundary, {
    required int perPaneWidth,
    required int nColumns,
  }) async {
    final pngBytes = await capturePng(
      boundary,
      perPaneWidth: perPaneWidth,
      nColumns: nColumns,
    );
    if (pngBytes == null) return;

    // Calculate PDF page dimensions preserving aspect ratio
    final aspectRatio = boundary.size.height / boundary.size.width;
    final pdfWidth = (nColumns * perPaneWidth).toDouble();
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
