/// Formatação PT-BR: R$, DD/MM/AAAA e 24 horas (sem depender do pacote intl).
String two(int n) => n.toString().padLeft(2, '0');

String formatMoney(double value) {
  final cents = (value * 100).round();
  final negative = cents < 0;
  final abs = cents.abs();
  final intPart = (abs ~/ 100).toString();
  final decPart = two(abs % 100);
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final fromEnd = intPart.length - i;
    buf.write(intPart[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return '${negative ? '-' : ''}R\$ ${buf.toString()},$decPart';
}

/// Converte "1.234,56", "89,9" ou "89.90" em double. Retorna null se inválido.
double? parseMoney(String input) {
  var s = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(s);
}

double? parseDecimal(String input) {
  final s = input.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

String formatDecimal(double v, {int digits = 1}) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String formatDateTime(DateTime d) => '${formatDate(d)} ${formatTime(d)}';

String formatMinutesOfDay(int minutes) => '${two(minutes ~/ 60)}:${two(minutes % 60)}';

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h${two(m)}';
}

const weekdayNames = {
  1: 'Segunda',
  2: 'Terça',
  3: 'Quarta',
  4: 'Quinta',
  5: 'Sexta',
  6: 'Sábado',
  7: 'Domingo',
};

const weekdayShort = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};

const monthNames = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

String formatLongDate(DateTime d) =>
    '${weekdayNames[d.weekday]}, ${d.day} de ${monthNames[d.month - 1]}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String relativeDay(DateTime d) {
  final today = dateOnly(DateTime.now());
  final diff = dateOnly(d).difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  return formatDate(d);
}

String ageText(DateTime? birth) {
  if (birth == null) return 'Idade não informada';
  final now = DateTime.now();
  var years = now.year - birth.year;
  var months = now.month - birth.month;
  if (now.day < birth.day) months--;
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years <= 0) return months <= 1 ? '1 mês' : '$months meses';
  return years == 1 ? '1 ano' : '$years anos';
}

/// Converte "DD/MM/AAAA" em DateTime.
DateTime? parseDate(String input) {
  final parts = input.trim().split('/');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || y < 1900) return null;
  final date = DateTime(y, m, d);
  if (date.day != d || date.month != m) return null;
  return date;
}
