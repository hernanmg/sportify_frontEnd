import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportify_amateur/models/finance.dart';

/// Exportación local (CSV / PDF) de finanzas para tesorería.
class FinanceExportHelper {
  FinanceExportHelper._();

  static String _escapeCsv(String value) {
    final v = value.replaceAll('"', '""');
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"$v"';
    }
    return v;
  }

  static Future<void> shareChargesCsv({
    required List<FeeCharge> charges,
    String title = 'cuotas',
  }) async {
    final buf = StringBuffer('Jugador,Concepto,Periodo,Estado,Monto,Pagado,Pendiente\n');
    for (final c in charges) {
      buf.writeln([
        _escapeCsv(c.userName ?? '#${c.userId}'),
        _escapeCsv(c.concept),
        _escapeCsv(c.periodLabel ?? ''),
        _escapeCsv(feeChargeStatusLabel(c.status)),
        c.amount.toStringAsFixed(2),
        c.paidAmount.toStringAsFixed(2),
        c.pendingAmount.toStringAsFixed(2),
      ].join(','));
    }
    await Share.share(
      buf.toString(),
      subject: title,
    );
  }

  static Future<void> shareBalancesCsv({
    required List<PlayerBalance> balances,
    String title = 'saldos',
  }) async {
    final buf = StringBuffer('Jugador,Dorsal,Cargado,Pagado,Saldo\n');
    for (final b in balances) {
      buf.writeln([
        _escapeCsv(b.userName),
        b.jerseyNumber?.toString() ?? '',
        b.totalCharged.toStringAsFixed(2),
        b.totalPaid.toStringAsFixed(2),
        b.balance.toStringAsFixed(2),
      ].join(','));
    }
    await Share.share(buf.toString(), subject: title);
  }

  static Future<void> shareLedgerCsv({
    required List<LedgerEntry> entries,
    String title = 'movimientos',
  }) async {
    final buf = StringBuffer('Fecha,Tipo,Ambito,Categoria,Descripcion,Monto\n');
    for (final e in entries) {
      buf.writeln([
        _escapeCsv(e.createdAt ?? ''),
        e.isIncome ? 'Ingreso' : 'Egreso',
        e.isEventRelated ? 'Evento' : 'Equipo',
        _escapeCsv(e.category),
        _escapeCsv(e.description),
        e.amount.toStringAsFixed(2),
      ].join(','));
    }
    await Share.share(buf.toString(), subject: title);
  }

  static Future<void> shareChargesPdf({
    required List<FeeCharge> charges,
    required String teamLabel,
    String? season,
  }) async {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(
            'Cuotas · $teamLabel',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (season != null) pw.Text('Temporada: $season'),
          pw.Text('Generado: ${fmt.format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Jugador',
              'Concepto',
              'Período',
              'Estado',
              'Monto',
              'Pagado',
            ],
            data: charges
                .map(
                  (c) => [
                    c.userName ?? '#${c.userId}',
                    c.concept,
                    c.periodLabel ?? '',
                    feeChargeStatusLabel(c.status),
                    formatMoney(c.amount),
                    formatMoney(c.paidAmount),
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'cuotas_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> shareLedgerPdf({
    required List<LedgerEntry> entries,
    required String teamLabel,
  }) async {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(
            'Movimientos · $teamLabel',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Generado: ${fmt.format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Fecha',
              'Tipo',
              'Ámbito',
              'Descripción',
              'Monto',
            ],
            data: entries
                .map(
                  (e) => [
                    e.createdAt ?? '',
                    e.isIncome ? 'Ingreso' : 'Egreso',
                    e.isEventRelated ? 'Evento' : 'Equipo',
                    e.description,
                    '${e.isIncome ? '+' : '-'}${formatMoney(e.amount)}',
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'movimientos_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
