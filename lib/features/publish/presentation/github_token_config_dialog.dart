import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/services/app_settings_service.dart';
import '../../../../shared/theme/app_colors.dart';

class GitHubTokenConfigDialog extends StatefulWidget {
  const GitHubTokenConfigDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const GitHubTokenConfigDialog(),
    );
  }

  @override
  State<GitHubTokenConfigDialog> createState() => _GitHubTokenConfigDialogState();
}

class _GitHubTokenConfigDialogState extends State<GitHubTokenConfigDialog> {
  final _tokenController = TextEditingController();

  bool _isLoading = true;
  bool _isValidating = false;
  bool _obscureToken = true;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AppSettingsService.getGitHubToken();
    if (mounted) {
      setState(() {
        _tokenController.text = token ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _tokenController.text = text;
        _statusMessage = null;
      });
    }
  }

  Future<void> _saveToken({bool validate = true}) async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      await AppSettingsService.setGitHubToken(null);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (validate) {
      setState(() {
        _isValidating = true;
        _statusMessage = 'Verifying GitHub repository permissions...';
        _isSuccess = false;
      });

      final valid = await AppSettingsService.validateGitHubToken(token);
      if (!mounted) return;

      if (!valid) {
        setState(() {
          _isValidating = false;
          _statusMessage =
              '⚠️ GitHub token rejected. Please ensure the token has "repo" or "contents: write" access to CKMendo/Arcadia.';
          _isSuccess = false;
        });
        return;
      }
    }

    await AppSettingsService.setGitHubToken(token);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _statusMessage = '✅ GitHub token verified & saved!';
        _isSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _openGitHubTokenPage() async {
    final uri = Uri.parse(
      'https://github.com/settings/tokens/new?scopes=repo&description=Arcadia+Golf+Publishing',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C1927),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.lakeCyan, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.public, color: AppColors.lakeCyan, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'GitHub Website Publishing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
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
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2B3E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Host: ckmendo.github.io/Arcadia',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyanLight,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'To publish live tournament updates from your phone directly to GitHub Pages, a GitHub Personal Access Token is needed once.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Generate Token Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.duneSand),
                      label: const Text(
                        'Create Token on GitHub (1-Click)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.duneSand,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.duneSand),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openGitHubTokenPage,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1. Tap button above to open GitHub.\n2. Leave "repo" checked & tap "Generate token".\n3. Copy the token (starts with ghp_) and paste below:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Token Field
                  TextFormField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: 'GITHUB PERSONAL ACCESS TOKEN',
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanLight),
                      hintText: 'ghp_...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.key, color: AppColors.lakeCyan, size: 22),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureToken ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureToken = !_obscureToken),
                          ),
                          IconButton(
                            icon: const Icon(Icons.paste, color: AppColors.cyanLight, size: 20),
                            tooltip: 'Paste from clipboard',
                            onPressed: _paste,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? const Color(0xFF0F382A)
                            : const Color(0xFF381515),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lakeCyan,
            foregroundColor: const Color(0xFF06111D),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _isValidating ? null : () => _saveToken(validate: true),
          child: _isValidating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06111D)),
                )
              : const Text('Verify & Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}
