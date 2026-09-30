import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/services/app_settings_service.dart';
import '../../../../shared/theme/app_colors.dart';

class GeminiKeyConfigDialog extends StatefulWidget {
  const GeminiKeyConfigDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const GeminiKeyConfigDialog(),
    );
  }

  @override
  State<GeminiKeyConfigDialog> createState() => _GeminiKeyConfigDialogState();
}

class _GeminiKeyConfigDialogState extends State<GeminiKeyConfigDialog> {
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();

  bool _isLoading = true;
  bool _isValidating = false;
  bool _obscurePrimary = false;
  bool _obscureSecondary = true;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _clipboardCandidate;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final primary = await AppSettingsService.getGeminiPrimaryApiKey();
    final secondary = await AppSettingsService.getGeminiSecondaryApiKey();

    String? clipKey;
    if (!kIsWeb && Platform.environment['FLUTTER_TEST'] != 'true') {
      try {
        final clip = await Clipboard.getData(Clipboard.kTextPlain);
        final text = clip?.text?.trim();
        if (text != null && (text.startsWith('AIzaSy') || text.startsWith('AQ.')) && text.length > 20) {
          clipKey = text;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _primaryController.text = primary ?? '';
        _secondaryController.text = secondary ?? '';
        _clipboardCandidate = clipKey;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  void _copyKey(String text, String label) {
    final clean = text.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $label entered yet to copy.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: clean));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Copied $label to clipboard!'),
        backgroundColor: const Color(0xFF0F382A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        controller.text = text;
        _statusMessage = null;
      });
    }
  }

  Future<void> _saveKeys({bool validate = true}) async {
    final primary = _primaryController.text.trim();
    final secondary = _secondaryController.text.trim();

    // 1. Immediately persist entered keys so they are NEVER lost regardless of validation outcome
    await AppSettingsService.setGeminiPrimaryApiKey(primary.isEmpty ? null : primary);
    await AppSettingsService.setGeminiSecondaryApiKey(secondary.isEmpty ? null : secondary);

    if (primary.isEmpty && secondary.isEmpty) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (validate) {
      setState(() {
        _isValidating = true;
        _statusMessage = 'Testing keys with Google Gemini...';
        _isSuccess = false;
      });

      bool primaryValid = true;
      if (primary.isNotEmpty) {
        setState(() => _statusMessage = 'Testing Primary Key with Google Gemini...');
        primaryValid = await AppSettingsService.validateGeminiApiKey(primary);
      }

      bool secondaryValid = true;
      if (secondary.isNotEmpty) {
        setState(() => _statusMessage = 'Testing Backup Key with Google Gemini...');
        secondaryValid = await AppSettingsService.validateGeminiApiKey(secondary);
      }

      if (!mounted) return;

      if (!primaryValid || !secondaryValid) {
        setState(() {
          _isValidating = false;
          final failedDesc = !primaryValid && !secondaryValid
              ? 'Both Primary and Backup keys'
              : !primaryValid
                  ? 'Primary Key (Gemini 3.8)'
                  : 'Backup Key (Gemini 3.7)';
          _statusMessage = '⚠️ Keys saved! Note: $failedDesc could not reach Google API. Ensure API is enabled in Google Cloud Console.';
          _isSuccess = false;
        });
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isValidating = false;
        _statusMessage = '✅ Gemini API keys verified & permanently backed up!';
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.lakeCyan, size: 24),
          SizedBox(width: 10),
          Text(
            'Configure Gemini AI Keys',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.lakeCyan),
              ),
            )
          : SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arcadia uses Gemini 3.8 Flash as the primary OCR engine. '
                      'If 3.8 is unavailable or experiencing high demand (503), '
                      'the app automatically fails over to Gemini 3.7 Flash.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.6)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield, color: Color(0xFF4CAF50), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Permanent Protection: API keys are auto-backed up across device storage and never lost on app updates.',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_clipboardCandidate != null && _primaryController.text != _clipboardCandidate) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            _primaryController.text = _clipboardCandidate!;
                            _obscurePrimary = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.lakeCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.lakeCyan),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.paste, color: AppColors.lakeCyan, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gemini key found in clipboard (${_clipboardCandidate!.substring(0, 10)}...). Tap to paste into Primary.',
                                  style: const TextStyle(color: AppColors.cyanLight, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Primary Key Field
                    const Row(
                      children: [
                        Icon(Icons.looks_one, color: AppColors.lakeCyan, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Primary Key (Gemini 3.8 Flash)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.lakeCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _primaryController,
                      obscureText: _obscurePrimary,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'AIzaSy... (Gemini 3.8 Flash)',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscurePrimary
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white60,
                                size: 20,
                              ),
                              tooltip: _obscurePrimary ? 'Show Key' : 'Hide Key',
                              onPressed: () =>
                                  setState(() => _obscurePrimary = !_obscurePrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: AppColors.lakeCyan, size: 20),
                              tooltip: 'Copy Primary Key',
                              onPressed: () => _copyKey(_primaryController.text, 'Primary Key'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_paste, color: AppColors.cyanLight, size: 20),
                              tooltip: 'Paste from Clipboard',
                              onPressed: () => _pasteInto(_primaryController),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Backup Key Field
                    const Row(
                      children: [
                        Icon(Icons.looks_two, color: AppColors.duneSand, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Backup Key (Gemini 3.7 Flash Failover)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.duneSand,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Used for Gemini 3.7 Flash if 3.8 is busy or quota is reached. Can be from a second Google project or account.',
                      style: TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _secondaryController,
                      obscureText: _obscureSecondary,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'AIzaSy... (optional secondary project)',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureSecondary
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white60,
                                size: 20,
                              ),
                              tooltip: _obscureSecondary ? 'Show Key' : 'Hide Key',
                              onPressed: () =>
                                  setState(() => _obscureSecondary = !_obscureSecondary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: AppColors.duneSand, size: 20),
                              tooltip: 'Copy Backup Key',
                              onPressed: () => _copyKey(_secondaryController.text, 'Backup Key'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_paste, color: AppColors.cyanLight, size: 20),
                              tooltip: 'Paste from Clipboard',
                              onPressed: () => _pasteInto(_secondaryController),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Quick Copy Keys Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 15),
                            label: const Text('Copy Primary Key', style: TextStyle(fontSize: 11.5)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.lakeCyan,
                              side: const BorderSide(color: AppColors.lakeCyan),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _copyKey(_primaryController.text, 'Primary Key'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 15),
                            label: const Text('Copy Backup Key', style: TextStyle(fontSize: 11.5)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.duneSand,
                              side: const BorderSide(color: AppColors.duneSand),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _copyKey(_secondaryController.text, 'Backup Key'),
                          ),
                        ),
                      ],
                    ),

                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess ? Colors.greenAccent : Colors.amber,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _isSuccess ? Colors.greenAccent : Colors.amber,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/app/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.open_in_new, size: 14, color: AppColors.cyanLight),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Get free Gemini API Keys at aistudio.google.com',
                              style: TextStyle(
                                color: AppColors.cyanLight,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (_statusMessage != null && !_isSuccess)
          TextButton(
            onPressed: _isValidating ? null : () => _saveKeys(validate: false),
            child: const Text('Save Anyway', style: TextStyle(color: Colors.amber)),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lakeCyan,
            foregroundColor: const Color(0xFF04110A),
          ),
          onPressed: _isValidating ? null : () => _saveKeys(validate: true),
          icon: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF04110A),
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(
            _isValidating ? 'Validating...' : 'Verify & Save',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
