import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';

/// Muestra el comprobante de un pago (imagen o PDF indicador).
class PaymentReceiptDialog extends StatefulWidget {
  final int paymentId;
  final String? mimeType;

  const PaymentReceiptDialog({
    super.key,
    required this.paymentId,
    this.mimeType,
  });

  static Future<void> show(
    BuildContext context, {
    required int paymentId,
    String? mimeType,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => PaymentReceiptDialog(
        paymentId: paymentId,
        mimeType: mimeType,
      ),
    );
  }

  @override
  State<PaymentReceiptDialog> createState() => _PaymentReceiptDialogState();
}

class _PaymentReceiptDialogState extends State<PaymentReceiptDialog> {
  final _financeService = FinanceService();
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await _financeService.fetchPaymentReceipt(widget.paymentId);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        _error = bytes == null ? 'No hay comprobante adjunto' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = FinanceService.errorMessage(e);
      });
    }
  }

  bool get _isPdf =>
      widget.mimeType == 'application/pdf' ||
      (widget.mimeType?.contains('pdf') ?? false);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comprobante de pago'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(_error!)
                : _isPdf
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              size: 64, color: Colors.red.shade700),
                          const SizedBox(height: 8),
                          const Text(
                            'Comprobante en PDF guardado en el servidor.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : InteractiveViewer(
                        child: Image.memory(
                          _bytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
