import '../models/round_score_import_draft.dart';
import 'player_score_row_matcher.dart';

class RoundImportValidationIssue {
  const RoundImportValidationIssue({
    required this.message,
    required this.isBlocking,
  });

  final String message;
  final bool isBlocking;
}

class RoundImportValidationReport {
  const RoundImportValidationReport({required this.issues});

  final List<RoundImportValidationIssue> issues;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);

  List<RoundImportValidationIssue> get blockingIssues =>
      issues.where((issue) => issue.isBlocking).toList(growable: false);

  List<RoundImportValidationIssue> get warnings =>
      issues.where((issue) => !issue.isBlocking).toList(growable: false);
}

class RoundImportValidator {
  const RoundImportValidator();

  RoundImportValidationReport validate({
    required RoundScoreImportDraft draft,
    required List<ImportPlayerCandidate> players,
    required Map<String, int?> rowByPlayerId,
    required Map<int, int> parByHole,
  }) {
    final issues = <RoundImportValidationIssue>[];
    final usedRows = <int>{};

    if (draft.rows.length < players.length) {
      issues.add(
        RoundImportValidationIssue(
          message:
              'Only ${draft.rows.length} score rows were detected for '
              '${players.length} players. Re-read the photo or add missing rows.',
          isBlocking: false, // Don't block if user only scored a subgroup
        ),
      );
    }

    for (final player in players) {
      final rowIndex = rowByPlayerId[player.id];
      if (rowIndex == null) {
        continue;
      }

      if (rowIndex < 0 || rowIndex >= draft.rows.length) {
        issues.add(
          RoundImportValidationIssue(
            message: '${player.fullName} is assigned to an invalid row.',
            isBlocking: true,
          ),
        );
        continue;
      }

      if (!usedRows.add(rowIndex)) {
        issues.add(
          RoundImportValidationIssue(
            message: 'Detected row ${rowIndex + 1} is assigned more than once.',
            isBlocking: true,
          ),
        );
      }

      final row = draft.rows[rowIndex];
      for (var index = 0; index < row.scores.length; index++) {
        final score = row.scores[index];
        final holeNumber = index + 1;
        if (score == null) {
          issues.add(
            RoundImportValidationIssue(
              message: '${player.fullName} is missing hole $holeNumber score.',
              isBlocking: true,
            ),
          );
          continue;
        }
        if (score < 1 || score > 15) {
          issues.add(
            RoundImportValidationIssue(
              message:
                  '${player.fullName} has an invalid score of $score on hole $holeNumber.',
              isBlocking: true,
            ),
          );
        }

        final par = parByHole[holeNumber];
        if (par != null && score == 1 && par >= 4) {
          issues.add(
            RoundImportValidationIssue(
              message:
                  '${player.fullName} has a 1 (ace) on par-$par hole $holeNumber. Please verify.',
              isBlocking: false,
            ),
          );
        }
      }
    }

    return RoundImportValidationReport(issues: issues);
  }
}
