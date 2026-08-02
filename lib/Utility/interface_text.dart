String withoutInterfaceTrailingPeriod(String text) {
  final match = RegExp(r'\.(\s*)$').firstMatch(text);
  if (match == null || (match.start > 0 && text[match.start - 1] == '.')) {
    return text;
  }

  return '${text.substring(0, match.start)}${match.group(1) ?? ''}';
}
