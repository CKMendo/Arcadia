class ImportedPlayerScoreRow {
  ImportedPlayerScoreRow({
    required this.sourceLabel,
    required this.scores,
    required this.sourceText,
  });

  String sourceLabel;
  List<int?> scores;
  final String sourceText;

  int get enteredScoreCount => scores.whereType<int>().length;

  int get totalScore =>
      scores.whereType<int>().fold(0, (sum, score) => sum + score);

  bool get hasInvalidScore =>
      scores.whereType<int>().any((score) => score < 1 || score > 15);
}

class RoundScoreImportDraft {
  RoundScoreImportDraft({
    required this.holeCount,
    required this.rows,
    required this.warnings,
  });

  final int holeCount;
  final List<ImportedPlayerScoreRow> rows;
  final List<String> warnings;
}
