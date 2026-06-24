import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

class ConvocationPdfService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> fetchExport(int convocationId) async {
    final response = await _dio.get('/convocations/$convocationId/export');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> previewPdf(int convocationId) async {
    final data = await fetchExport(convocationId);
    final doc = _buildDocument(data);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> sharePdf(int convocationId) async {
    final data = await fetchExport(convocationId);
    final doc = _buildDocument(data);
    final bytes = await doc.save();
    final conv = Map<String, dynamic>.from(data['convocation'] as Map);
    final rawTitle = conv['title']?.toString() ?? 'convocatoria';
    final safeName = rawTitle
        .replaceAll(RegExp(r'[^\w\s-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${safeName.isEmpty ? 'convocatoria' : safeName}.pdf',
    );
  }

  pw.Document _buildDocument(Map<String, dynamic> data) {
    final conv = Map<String, dynamic>.from(data['convocation'] as Map);
    final squad = (data['squad'] as List<dynamic>? ?? []);
    final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
    final date = conv['eventDate'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(conv['eventDate'].toString()))
        : '—';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              conv['title']?.toString() ?? 'Convocatoria',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Equipo: ${conv['teamName'] ?? ''}'),
          pw.Text('Rival: ${conv['opponentName'] ?? 'Por definir'}'),
          pw.Text('Fecha: $date'),
          if (conv['location'] != null) pw.Text('Lugar: ${conv['location']}'),
          if (conv['courtNumber'] != null)
            pw.Text('Cancha: ${conv['courtNumber']}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Resumen: ${stats['confirmed'] ?? 0} confirmados · '
            '${stats['declined'] ?? 0} rechazados · '
            '${stats['pending'] ?? 0} pendientes',
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Plantel convocado',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Jugador', 'Estado', 'Elegibilidad'],
            data: squad.map((p) {
              final row = Map<String, dynamic>.from(p as Map);
              return [
                row['name']?.toString() ?? '',
                _statusLabel(row['status']?.toString()),
                row['eligibilityDetail']?.toString() ??
                    row['eligibilityStatus']?.toString() ??
                    '',
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return doc;
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmó';
      case 'declined':
        return 'Rechazó';
      case 'no_response':
        return 'Sin respuesta';
      default:
        return 'Pendiente';
    }
  }
}
