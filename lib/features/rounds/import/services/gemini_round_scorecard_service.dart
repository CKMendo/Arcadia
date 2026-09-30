import '../../../../shared/services/gemini_ocr_service.dart';
import '../models/round_score_import_draft.dart';

/// Scorecard OCR service for scoring entry.
/// Delegates all AI vision processing and model execution to the centralized [GeminiOcrService].
class GeminiRoundScorecardService {
  static String? apiKey;

  static const String defaultModel = GeminiOcrService.primaryModel;
  static const String primaryModel = GeminiOcrService.primaryModel;
  static const String fallbackModel = GeminiOcrService.backupModel;
  static const String emergencyModel = GeminiOcrService.fallbackModel;

  Future<RoundScoreImportDraft> analyze(
    String imagePath, {
    required int holeCount,
    String? targetPlayerName,
    List<ImportedPlayerScoreRow> existingRows = const [],
  }) {
    return GeminiOcrService.analyzePlayerScorecard(
      imagePath,
      holeCount: holeCount,
      targetPlayerName: targetPlayerName,
      existingRows: existingRows,
      explicitApiKey: apiKey,
    );
  }

  RoundScoreImportDraft parseResponse(
    String response, {
    required int holeCount,
  }) {
    return GeminiOcrService.parsePlayerScorecardResponse(
      response,
      holeCount: holeCount,
    );
  }
}
