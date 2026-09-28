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
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isValidating = false;
  bool _obscureText = true;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await AppSettingsService.getGeminiApiKey();
    if (mounted) {
      setState(() {
        _controller.text = key ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _controller.text = text;
        _statusMessage = null;
      });
    }
  }

  Future<void> _saveKey({bool validate = true}) async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await AppSettingsService.setGeminiApiKey(null);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (validate) {
      setState(() {
        _isValidating = true;
        _statusMessage = 'Testing key with Gemini 2.5 Flash...';
        _isSuccess = false;
      });

      final isValid = await AppSettingsService.validateGeminiApiKey(key);
      if (!mounted) return;

      if (!isValid) {
        setState(() {
          _isValidating = false;
          _statusMessage =
              'Key could not reach Gemini API. Ensure generativelanguage API is enabled in Google Cloud Console or choose "Save Anyway".';
          _isSuccess = false;
        });
        return;
      }
    }

    await AppSettingsService.setGeminiApiKey(key);
    if (mounted) {
      setState(() {
        _isValidating = false;
        _statusMessage = '✅ Gemini API Key verified and saved!';
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
            'Configure Gemini Key',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.lakeCyan),
              ),
            )
          : SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct scorecard vision scanning uses Google Gemini 2.5 Flash. '
                    'Enter your Gemini API key below.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    obscureText: _obscureText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIzaSy...',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      prefixIcon: const Icon(Icons.key, color: AppColors.lakeCyan),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white60,
                            ),
                            tooltip: _obscureText ? 'Show Key' : 'Hide Key',
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_paste, color: AppColors.cyanLight),
                            tooltip: 'Paste from Clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.greenAccent : Colors.amber,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://aistudio.google.com/app/apikey'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: AppColors.cyanLight),
                        SizedBox(width: 6),
                        Text(
                          'Get a free Gemini API Key at aistudio.google.com',
                          style: TextStyle(
                            color: AppColors.cyanLight,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (_statusMessage != null && !_isSuccess)
          TextButton(
            onPressed: _isValidating ? null : () => _saveKey(validate: false),
            child: const Text('Save Anyway', style: TextStyle(color: Colors.amber)),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lakeCyan,
            foregroundColor: const Color(0xFF04110A),
          ),
          onPressed: _isValidating ? null : () => _saveKey(validate: true),
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
