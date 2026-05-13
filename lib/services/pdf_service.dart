import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts text content from PDF files
class PdfService {
  /// Extract all text from a PDF file
  static Future<String> extractTextFromPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Ficheiro PDF não encontrado: $filePath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final StringBuffer fullText = StringBuffer();

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final text = PdfTextExtractor(document).extractText(startPageIndex: i);
        if (text.isNotEmpty) {
          fullText.writeln('--- Página ${i + 1} ---');
          fullText.writeln(text);
          fullText.writeln();
        }
      }

      document.dispose();

      final result = fullText.toString().trim();
      debugPrint('PDF extracted: ${result.length} characters from ${document.pages.count} pages');

      if (result.isEmpty) {
        throw Exception(
          'Não foi possível extrair texto do PDF. '
          'O ficheiro pode ser uma imagem escaneada.',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      rethrow;
    }
  }
}
