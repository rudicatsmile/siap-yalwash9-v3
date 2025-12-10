class DocNumberDecision {
  final String value;
  final bool readOnly;
  const DocNumberDecision(this.value, this.readOnly);
}

DocNumberDecision decideDocNumberPart2(
  String kategoriDesc, {
  String? jenisKode,
  String? laporanKode,
}) {
  final k = kategoriDesc.toLowerCase().trim();
  if (k.contains('undangan')) {
    return const DocNumberDecision('UND', true);
  }
  if (k.contains('rapat')) {
    return const DocNumberDecision('RPT', true);
  }
  if (k.contains('dokumen')) {
    final jk = (jenisKode ?? '').trim();
    if (jk.isEmpty) return const DocNumberDecision('', false);
    return DocNumberDecision(jk, false);
  }
  if (k.contains('laporan')) {
    final lk = (laporanKode ?? '').trim();
    if (lk.isEmpty) return const DocNumberDecision('', false);
    return DocNumberDecision(lk, false);
  }
  return const DocNumberDecision('', false);
}
