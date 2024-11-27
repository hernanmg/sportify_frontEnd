import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ExportService {
  // Exportar a CSV
  Future<File> exportToCSV(
      List<Map<String, dynamic>> data, String fileName) async {
    final List<List<dynamic>> rows = [];

    // Encabezados
    rows.add(data.first.keys.toList());

    // Contenido
    for (var item in data) {
      rows.add(item.values.toList());
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.csv');

    return file.writeAsString(csvData);
  }

  // Exportar a PDF
  Future<File> exportToPDF(
      List<Map<String, dynamic>> data, String fileName) async {
    final pdf = pw.Document();

    // Construcción de la tabla
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Table.fromTextArray(
            headers: data.first.keys.toList(),
            data: data.map((item) => item.values.toList()).toList(),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');

    return file.writeAsBytes(await pdf.save());
  }
}
