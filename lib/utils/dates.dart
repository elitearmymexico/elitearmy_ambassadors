// lib/utils/dates.dart
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime toDateSafe(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  if (value is int) {
    // segundos vs milisegundos
    return value > 2000000000
        ? DateTime.fromMillisecondsSinceEpoch(value)
        : DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  if (value is String) {
    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;
    final asInt = int.tryParse(value);
    if (asInt != null) return toDateSafe(asInt);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _two(int n) => n.toString().padLeft(2, '0');
String fechaCorta(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
const _mesCorto = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
String fechaLarga(DateTime d) => '${_two(d.day)} ${_mesCorto[d.month - 1]} ${d.year}';
