/// Funções auxiliares de formatação e datas.

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtMoney(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Data sem horário, em UTC (evita erros de horário de verão ao subtrair datas).
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Formato salvo no banco: yyyy-MM-dd
String dbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Quantidade sem zeros desnecessários: 2 -> "2", 0.5 -> "0,5", 0.25 -> "0,25".
String fmtQty(double v) {
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

/// Converte texto digitado ("0,5" ou "0.5") em número. Retorna null se inválido.
double? parseNum(String? text) =>
    double.tryParse((text ?? '').trim().replaceAll(',', '.'));