import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/services/app_settings_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../models/round_score_import_draft.dart';
import '../services/external_ai_import_service.dart';
import '../services/gemini_round_scorecard_service.dart';
import '../services/on_device_text_recognition_service.dart';
import '../services/player_score_row_matcher.dart';
import '../services/round_import_validator.dart';
import '../services/round_scorecard_text_parser.dart';
import 'gemini_key_config_dialog.dart';

enum _RoundImportReader { offline, gemini }

class RoundScorecardImportResult {
  const RoundScorecardImportResult({
    required this.scoresByPlayerId,
  });

  final Map<String, List<int?>> scoresByPlayerId;
}

class RoundScorecardImportScreen extends StatefulWidget {
  const RoundScorecardImportScreen({
    super.key,
    required this.players,
    required this.holeCount,
    required this.parByHole,
  });

  final List<ImportPlayerCandidate> players;
  final int holeCount;
  final Map<int, int> parByHole;

  @override
  State<RoundScorecardImportScreen> createState() =>
      _RoundScorecardImportScreenState();
}

class _RoundScorecardImportScreenState
    extends State<RoundScorecardImportScreen> {
  final _imagePicker = ImagePicker();
  final _geminiService = GeminiRoundScorecardService();
  final _offlineService = const OnDeviceTextRecognitionService();
  final _offlineParser = const RoundScorecardTextParser();
  final _matcher = const PlayerScoreRowMatcher();
  final _validator = const RoundImportValidator();
  final _externalAiService = const ExternalAiImportService();

  XFile? _selectedImage;
  RoundScoreImportDraft? _draft;
  bool _isReading = false;
  String? _importError;
  _RoundImportReader? _activeReader;
  _RoundImportReader _selectedReader = _RoundImportReader.offline;
  ExternalAiAssistant? _externalAssistant;
  final Map<String, int?> _rowByPlayerId = <String, int?>{};
  final Map<String, double> _matchConfidenceByPlayerId = <String, double>{};

  @override
  void initState() {
    super.initState();
    for (final player in widget.players) {
      _rowByPlayerId[player.id] = null;
    }
  }

  Future<void> _selectExternalAssistant(ExternalAiAssistant assistant) async {
    setState(() {
      _externalAssistant = assistant;
      _importError = null;
    });
    await _openExternalAi(assistant);
  }

  Future<void> _openExternalAi(ExternalAiAssistant assistant) async {
    setState(() {
      _externalAssistant = assistant;
      _importError = null;
    });
    try {
      final openedInstalledApp = await _externalAiService.copyPromptAndOpen(
        assistant: assistant,
        prompt: _externalAiService.roundPrompt(
          holeCount: widget.holeCount,
          playerNames: widget.players
              .map((player) => player.fullName)
              .toList(growable: false),
        ),
      );
      if (!mounted) return;
      _showMessage(
        'Prompt copied! ${openedInstalledApp ? assistant.label : '${assistant.label} website'} opened. '
        'Attach the scorecard photo, send the prompt, then copy the complete response.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _importError =
            error.message ?? '${assistant.label} could not be opened.';
      });
    }
  }

  Future<void> _pasteExternalResponse() async {
    final assistant = _externalAssistant;
    if (assistant == null) return;
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final expectedPrompt = _externalAiService.roundPrompt(
      holeCount: widget.holeCount,
      playerNames: widget.players
          .map((player) => player.fullName)
          .toList(growable: false),
    );
    final clipboardText = clipboard?.text?.trim() ?? '';
    final clipboardStillHasPrompt = clipboardText == expectedPrompt.trim();
    final controller = TextEditingController(
      text: clipboardStillHasPrompt ? '' : clipboardText,
    );
    final response = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Paste ${assistant.label} response',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (clipboardStillHasPrompt) ...[
                Card(
                  color: AppColors.cardDark,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_outlined, color: Colors.amber),
                    title: const Text('Clipboard still contains the AI prompt', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Return to ${assistant.label}, copy its completed response, then paste it here.',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: controller,
                minLines: 8,
                maxLines: 16,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Paste the complete JSON response here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.lakeCyan),
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            icon: const Icon(Icons.content_paste_go, color: Color(0xFF06111D)),
            label: const Text('Import Response', style: TextStyle(color: Color(0xFF06111D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (response == null || !mounted) return;
    try {
      final draft = _geminiService.parseResponse(
        response,
        holeCount: widget.holeCount,
      );
      _applyDetectedDraft(draft);
    } on FormatException catch (error) {
      setState(() => _importError = error.message);
      _showMessage(error.message);
    }
  }

  Future<void> _copyExternalPromptAgain() async {
    final assistant = _externalAssistant;
    if (assistant == null) return;
    await Clipboard.setData(
      ClipboardData(
        text: _externalAiService.roundPrompt(
          holeCount: widget.holeCount,
          playerNames: widget.players
              .map((player) => player.fullName)
              .toList(growable: false),
        ),
      ),
    );
    if (!mounted) return;
    _showMessage(
      'The ${assistant.label} round prompt was copied again. Return to '
      '${assistant.label}, press and hold in the message box, then choose Paste.',
    );
  }

  Widget _buildExternalAiCard() {
    return Card(
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.cyanLight, size: 24),
                const SizedBox(width: 8),
                Text(
                  'RETURN FROM ${_externalAssistant!.label.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The prompt has been copied to your clipboard. In the AI app, '
              'attach the scorecard photo, paste the prompt, send it, and '
              'copy the completed JSON response.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _copyExternalPromptAgain,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('COPY PROMPT AGAIN'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lakeCyan,
                foregroundColor: const Color(0xFF06111D),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _pasteExternalResponse,
              icon: const Icon(Icons.content_paste_go),
              label: Text(
                'PASTE ${_externalAssistant!.label.toUpperCase()} RESPONSE',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseImage(ImageSource source) async {
    try {
      setState(() => _importError = null);
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
      );
      if (image == null || !mounted) return;
      setState(() {
        _selectedImage = image;
        _draft = null;
        _importError = null;
      });
      final externalAssistant = _externalAssistant;
      if (externalAssistant == null) {
        await _analyze(_selectedReader);
      } else {
        await _openExternalAi(externalAssistant);
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _isReading = false;
        _importError = error.code.toLowerCase().contains('permission')
            ? 'Photo access was denied. Allow access in phone settings and try again.'
            : 'The phone could not open that image. Try another photo.';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _isReading = false;
        _importError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isReading = false;
        _importError =
            'Analysis failed. Details: ${error.toString().replaceAll(RegExp(r'\s+'), ' ').trim()}';
      });
    }
  }

  Future<void> _analyze(_RoundImportReader reader) async {
    final image = _selectedImage;
    if (image == null || _isReading) return;

    if (reader == _RoundImportReader.gemini) {
      final key = await AppSettingsService.getGeminiApiKey();
      if (key == null || key.trim().isEmpty) {
        if (!mounted) return;
        final configured = await GeminiKeyConfigDialog.show(context);
        if (configured != true) {
          setState(() {
            _importError =
                'Gemini API key is required to scan scorecards. Tap Configure Key below, or select FREE ON-DEVICE.';
          });
          return;
        }
      }
    }

    setState(() {
      _isReading = true;
      _activeReader = reader;
      _importError = null;
      _draft = null;
    });
    try {
      final draft = switch (reader) {
        _RoundImportReader.offline => _offlineParser.parse(
          (await _offlineService.recognize(image.path)).text,
          holeCount: widget.holeCount,
        ),
        _RoundImportReader.gemini => await _geminiService.analyze(
          image.path,
          holeCount: widget.holeCount,
        ),
      };
      if (!mounted) return;
      _applyDetectedDraft(draft);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _importError = error.message);
    } catch (error) {
      if (!mounted) return;
      final detail = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      setState(() {
        _importError = '${reader == _RoundImportReader.offline ? 'Offline reader' : 'Gemini'} '
            'failed: $detail';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isReading = false;
          _activeReader = null;
        });
      }
    }
  }

  Future<void> _tryOtherReader() async {
    final other = _selectedReader == _RoundImportReader.offline
        ? _RoundImportReader.gemini
        : _RoundImportReader.offline;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Try other import method?'),
        content: Text(
          'The same saved photo will be re-analyzed with '
          '${other == _RoundImportReader.offline ? 'FREE ON-DEVICE' : 'GEMINI'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.lakeCyan),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Try Other Method', style: TextStyle(color: Color(0xFF06111D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _selectedReader = other;
      _externalAssistant = null;
    });
    await _analyze(other);
  }

  void _applyDetectedDraft(RoundScoreImportDraft draft) {
    final matches = _matcher.match(players: widget.players, rows: draft.rows);

    setState(() {
      _draft = draft;
      _importError = null;
      _matchConfidenceByPlayerId.clear();
      for (final player in widget.players) {
        final match = matches[player.id];
        _rowByPlayerId[player.id] = match?.rowIndex;
        if (match != null) {
          _matchConfidenceByPlayerId[player.id] = match.confidence;
        }
      }

      final usedRows = _rowByPlayerId.values.whereType<int>().toSet();
      var nextRow = 0;
      for (final player in widget.players) {
        if (_rowByPlayerId[player.id] != null) continue;
        while (nextRow < draft.rows.length && usedRows.contains(nextRow)) {
          nextRow++;
        }
        if (nextRow < draft.rows.length) {
          _rowByPlayerId[player.id] = nextRow;
          usedRows.add(nextRow);
        }
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _apply() {
    final draft = _draft;
    if (draft == null) return;

    final validation = _validator.validate(
      draft: draft,
      players: widget.players,
      rowByPlayerId: _rowByPlayerId,
      parByHole: widget.parByHole,
    );
    if (validation.hasBlockingIssues) {
      _showMessage(validation.blockingIssues.first.message);
      return;
    }

    final scores = <String, List<int?>>{};
    final selectedRows = <int>{};

    for (final player in widget.players) {
      final rowIndex = _rowByPlayerId[player.id];
      if (rowIndex == null || rowIndex < 0 || rowIndex >= draft.rows.length) {
        continue;
      }
      if (!selectedRows.add(rowIndex)) {
        _showMessage('Each detected row can only be assigned to one player.');
        return;
      }
      scores[player.id] = List<int?>.from(draft.rows[rowIndex].scores);
    }

    if (scores.isEmpty) {
      _showMessage('Assign at least one detected row to a player.');
      return;
    }

    Navigator.of(context).pop(
      RoundScorecardImportResult(scoresByPlayerId: scores),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard Round Import'),
      ),
      body: SafeArea(
        child: _draft == null ? _buildInput() : _buildReview(_draft!),
      ),
    );
  }

  Widget _buildInput() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppColors.surfaceDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppColors.lakeCyan, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Capture or select a scorecard photo. Use FREE ON-DEVICE offline OCR, or choose Gemini, ChatGPT, or Claude.',
                    style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ReaderSelector(
          selected: _externalAssistant == null ? _selectedReader : null,
          selectedExternal: _externalAssistant,
          enabled: !_isReading,
          onSelected: (reader) => setState(() {
            _selectedReader = reader;
            _externalAssistant = null;
          }),
          onExternalSelected: _selectExternalAssistant,
        ),
        if (_selectedReader == _RoundImportReader.gemini && _externalAssistant == null) ...[
          const SizedBox(height: 12),
          _buildGeminiKeyStatusCard(),
        ],
        const SizedBox(height: 16),
        if (_externalAssistant != null) ...[
          _buildExternalAiCard(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_note),
            label: const Text('ENTER SCORES MANUALLY'),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lakeCyan,
                    foregroundColor: const Color(0xFF06111D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isReading
                      ? null
                      : () => _chooseImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isReading
                      ? null
                      : () => _chooseImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
        if (_selectedImage != null && _externalAssistant == null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_selectedImage!.path),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.lakeCyan, foregroundColor: const Color(0xFF06111D)),
            onPressed: _isReading ? null : () => _analyze(_selectedReader),
            icon: const Icon(Icons.refresh),
            label: Text(
              _selectedReader == _RoundImportReader.offline
                  ? 'RE-READ FREE ON-DEVICE'
                  : 'RE-READ WITH GEMINI',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        if (_isReading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator(color: AppColors.lakeCyan)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _activeReader == _RoundImportReader.offline
                  ? 'Reading scores on-device using ML OCR...'
                  : 'Gemini is analyzing scorecard photo...',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
        if (_importError != null) ...[
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF2A1515),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.redAccent, width: 1.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.redAccent),
              title: Text(_importError!, style: const TextStyle(color: Colors.white)),
              subtitle: _selectedImage == null
                  ? null
                  : const Text(
                      'Photo is still selected. Choose another reader above to retry.',
                      style: TextStyle(color: Colors.white70),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReview(RoundScoreImportDraft draft) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_selectedImage != null) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.cardDark, foregroundColor: AppColors.cyanLight),
            onPressed: _isReading ? null : _tryOtherReader,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('TRY OTHER IMPORT METHOD', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
        if (_externalAssistant != null) ...[
          _buildExternalAiCard(),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Review Imported Round',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _draft = null),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
        _buildImportSummary(draft),
        if (draft.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final warning in draft.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $warning', style: const TextStyle(color: AppColors.duneSand, fontSize: 13)),
            ),
        ],
        const SizedBox(height: 14),
        ...List.generate(
          draft.rows.length,
          (rowIndex) => _buildDetectedRowCard(rowIndex, draft),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lakeCyan,
            foregroundColor: const Color(0xFF06111D),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _apply,
          icon: const Icon(Icons.check, size: 24),
          label: const Text(
            'Apply Scores to Round',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildImportSummary(RoundScoreImportDraft draft) {
    final assignedPlayerCount = _rowByPlayerId.values.whereType<int>().length;
    final completeRowCount = draft.rows
        .where(
          (row) =>
              row.enteredScoreCount == widget.holeCount && !row.hasInvalidScore,
        )
        .length;
    return Card(
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: AppColors.lakeCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${draft.rows.length} rows detected • '
                '$completeRowCount complete • '
                '$assignedPlayerCount players assigned',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedRowCard(int rowIndex, RoundScoreImportDraft draft) {
    final row = draft.rows[rowIndex];
    String? assignedPlayerId;
    for (final entry in _rowByPlayerId.entries) {
      if (entry.value == rowIndex) {
        assignedPlayerId = entry.key;
        break;
      }
    }
    final confidence = assignedPlayerId == null
        ? null
        : _matchConfidenceByPlayerId[assignedPlayerId];

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCORE ROW ${rowIndex + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.cyanLight, fontSize: 15),
                ),
                Text(
                  'OCR: ${row.sourceLabel}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: assignedPlayerId,
              decoration: const InputDecoration(
                labelText: 'Player for this row',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.lakeCyan),
                filled: true,
                fillColor: AppColors.surfaceElevated,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Unassigned / Ignore Row'),
                ),
                ...widget.players.map(
                  (player) => DropdownMenuItem<String?>(
                    value: player.id,
                    child: Text(player.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              onChanged: (playerId) {
                setState(() {
                  for (final player in widget.players) {
                    if (_rowByPlayerId[player.id] == rowIndex) {
                      _rowByPlayerId[player.id] = null;
                      _matchConfidenceByPlayerId.remove(player.id);
                    }
                  }
                  if (playerId != null) {
                    _rowByPlayerId[playerId] = rowIndex;
                    _matchConfidenceByPlayerId.remove(playerId);
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${_playerPreviewText(row)}'
              '${confidence == null
                  ? ''
                  : confidence >= 0.85
                  ? ' • Strong name match'
                  : ' • Verify player match'}',
              style: TextStyle(
                color: confidence != null && confidence >= 0.85 ? Colors.greenAccent : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ScoreGrid(
              scores: row.scores,
              parByHole: widget.parByHole,
              onChanged: (holeIndex, score) {
                setState(() => row.scores[holeIndex] = score);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _playerPreviewText(ImportedPlayerScoreRow row) {
    final coursePar = widget.parByHole.values.fold<int>(
      0,
      (sum, par) => sum + par,
    );
    final difference = row.totalScore - coursePar;
    final relative = difference == 0
        ? 'E'
        : difference > 0
        ? '+$difference'
        : '$difference';
    return '${row.enteredScoreCount}/${widget.holeCount} scores • Gross ${row.totalScore} • $relative';
  }

  Widget _buildGeminiKeyStatusCard() {
    return FutureBuilder<String?>(
      future: AppSettingsService.getGeminiApiKey(),
      builder: (context, snapshot) {
        final key = snapshot.data;
        final hasKey = key != null && key.isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: hasKey ? const Color(0xFF0D251C) : const Color(0xFF2E1C0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasKey ? Colors.greenAccent.withValues(alpha: 0.6) : AppColors.duneSand,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasKey ? Icons.check_circle_outline : Icons.vpn_key_outlined,
                color: hasKey ? Colors.greenAccent : AppColors.duneSand,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasKey ? 'Gemini 3.8 Flash Ready' : 'Gemini API Key Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hasKey ? Colors.greenAccent : AppColors.duneSand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasKey
                          ? 'Key active (ends in ...${key.length > 4 ? key.substring(key.length - 4) : key})'
                          : 'Configure API key for direct AI scorecard vision scan or use FREE ON-DEVICE OCR.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: hasKey
                      ? AppColors.lakeCyan.withValues(alpha: 0.25)
                      : AppColors.duneSand,
                  foregroundColor: hasKey ? AppColors.cyanLight : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  final changed = await GeminiKeyConfigDialog.show(context);
                  if (changed == true) {
                    setState(() {});
                  }
                },
                child: Text(
                  hasKey ? 'Change' : 'Configure',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReaderSelector extends StatelessWidget {
  const _ReaderSelector({
    required this.selected,
    required this.selectedExternal,
    required this.enabled,
    required this.onSelected,
    required this.onExternalSelected,
  });

  final _RoundImportReader? selected;
  final ExternalAiAssistant? selectedExternal;
  final bool enabled;
  final ValueChanged<_RoundImportReader> onSelected;
  final ValueChanged<ExternalAiAssistant> onExternalSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHOOSE SCORECARD READER',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 14, color: AppColors.cyanLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoundImportMethodButton(
                    icon: Icons.offline_bolt_outlined,
                    label: 'FREE ON-DEVICE',
                    selected: selected == _RoundImportReader.offline,
                    enabled: enabled,
                    onPressed: () => onSelected(_RoundImportReader.offline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoundImportMethodButton(
                    icon: Icons.auto_awesome,
                    label: 'GEMINI',
                    selected: selected == _RoundImportReader.gemini,
                    enabled: enabled,
                    onPressed: () => onSelected(_RoundImportReader.gemini),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoundImportMethodButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'CHATGPT',
                    selected: selectedExternal == ExternalAiAssistant.chatGpt,
                    enabled: enabled,
                    onPressed: () =>
                        onExternalSelected(ExternalAiAssistant.chatGpt),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoundImportMethodButton(
                    icon: Icons.psychology_outlined,
                    label: 'CLAUDE',
                    selected: selectedExternal == ExternalAiAssistant.claude,
                    enabled: enabled,
                    onPressed: () =>
                        onExternalSelected(ExternalAiAssistant.claude),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              selectedExternal != null
                  ? 'Copies a row-by-row prompt, opens ${selectedExternal!.label}, '
                        'and imports the response you copy back.'
                  : selected == _RoundImportReader.offline
                  ? 'Reads scorecard photos directly and privately on your phone without internet.'
                  : 'Fast multimodal AI scorecard vision analysis.',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundImportMethodButton extends StatelessWidget {
  const _RoundImportMethodButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lakeCyan,
              foregroundColor: const Color(0xFF06111D),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon, size: 20),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon, size: 20, color: Colors.white70),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          );
  }
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({
    required this.scores,
    required this.parByHole,
    required this.onChanged,
  });

  final List<int?> scores;
  final Map<int, int> parByHole;
  final void Function(int holeIndex, int? score) onChanged;

  @override
  Widget build(BuildContext context) {
    final frontEnd = scores.length < 9 ? scores.length : 9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _ScoreLegendMark(label: 'Birdie', circular: true),
            _ScoreLegendMark(label: 'Bogey', circular: false),
            _ScoreLegendMark(label: 'Eagle', circular: true, doubleMark: true),
            _ScoreLegendMark(
              label: 'Double+',
              circular: false,
              doubleMark: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _NineScoreRow(
          label: 'FRONT NINE',
          start: 0,
          end: frontEnd,
          scores: scores,
          parByHole: parByHole,
          onChanged: onChanged,
        ),
        if (scores.length > 9) ...[
          const SizedBox(height: 12),
          _NineScoreRow(
            label: 'BACK NINE',
            start: 9,
            end: scores.length < 18 ? scores.length : 18,
            scores: scores,
            parByHole: parByHole,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _ScoreLegendMark extends StatelessWidget {
  const _ScoreLegendMark({
    required this.label,
    required this.circular,
    this.doubleMark = false,
  });

  final String label;
  final bool circular;
  final bool doubleMark;

  @override
  Widget build(BuildContext context) {
    final color = circular
        ? AppColors.lakeCyan
        : Theme.of(context).colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          padding: doubleMark ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(circular ? 99 : 2),
          ),
          child: doubleMark
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(circular ? 99 : 1),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _NineScoreRow extends StatelessWidget {
  const _NineScoreRow({
    required this.label,
    required this.start,
    required this.end,
    required this.scores,
    required this.parByHole,
    required this.onChanged,
  });

  final String label;
  final int start;
  final int end;
  final List<int?> scores;
  final Map<int, int> parByHole;
  final void Function(int holeIndex, int? score) onChanged;

  @override
  Widget build(BuildContext context) {
    final total = scores
        .skip(start)
        .take(end - start)
        .whereType<int>()
        .fold(0, (sum, score) => sum + score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label • ${start == 0 ? 'OUT' : 'IN'}: $total',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 3.0;
            final count = end - start;
            if (count <= 0) return const SizedBox.shrink();
            final width =
                (constraints.maxWidth - spacing * (count - 1)) / count;
            return Row(
              children: [
                for (var index = start; index < end; index++) ...[
                  SizedBox(
                    width: width,
                    child: _ScoreEntryBox(
                      holeNumber: index + 1,
                      score: scores[index],
                      par: parByHole[index + 1] ?? 4,
                      onChanged: (score) => onChanged(index, score),
                    ),
                  ),
                  if (index < end - 1) const SizedBox(width: spacing),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ScoreEntryBox extends StatefulWidget {
  const _ScoreEntryBox({
    required this.holeNumber,
    required this.score,
    required this.par,
    required this.onChanged,
  });

  final int holeNumber;
  final int? score;
  final int par;
  final ValueChanged<int?> onChanged;

  @override
  State<_ScoreEntryBox> createState() => _ScoreEntryBoxState();
}

class _ScoreEntryBoxState extends State<_ScoreEntryBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.score?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _ScoreEntryBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expected = widget.score?.toString() ?? '';
    if (_controller.text != expected) {
      _controller.value = TextEditingValue(
        text: expected,
        selection: TextSelection.collapsed(offset: expected.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difference = widget.score == null ? 0 : widget.score! - widget.par;
    final underPar = difference < 0;
    final overPar = difference > 0;
    final doubleMark = difference.abs() >= 2;
    final radius = underPar ? 999.0 : 4.0;
    final color = underPar
        ? AppColors.lakeCyan
        : overPar
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.outline;

    final scoreField = TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      selectAllOnFocus: true,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
      decoration: InputDecoration(
        labelText: '${widget.holeNumber}',
        labelStyle: const TextStyle(fontSize: 10, color: Colors.white60),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(1, 9, 1, 7),
        border: InputBorder.none,
      ),
      onTap: () => _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      ),
      onChanged: (value) => widget.onChanged(int.tryParse(value)),
    );

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: color, width: difference == 0 ? 1 : 2),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: doubleMark ? const EdgeInsets.all(2) : EdgeInsets.zero,
      child: doubleMark
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: scoreField,
            )
          : scoreField,
    );
  }
}
