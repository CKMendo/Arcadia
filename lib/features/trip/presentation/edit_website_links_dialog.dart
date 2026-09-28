import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/services/app_settings_service.dart';
import '../../../../shared/theme/app_colors.dart';

class EditWebsiteLinksDialog extends StatefulWidget {
  const EditWebsiteLinksDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const EditWebsiteLinksDialog(),
    );
  }

  @override
  State<EditWebsiteLinksDialog> createState() => _EditWebsiteLinksDialogState();
}

class _EditWebsiteLinksDialogState extends State<EditWebsiteLinksDialog> {
  final _webUrlController = TextEditingController();
  final _tinyUrlController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final webUrl = await AppSettingsService.getWebsiteUrl();
    final tinyUrl = await AppSettingsService.getTinyUrl();
    if (mounted) {
      setState(() {
        _webUrlController.text = webUrl;
        _tinyUrlController.text = tinyUrl;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _webUrlController.dispose();
    _tinyUrlController.dispose();
    super.dispose();
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        controller.text = text;
      });
    }
  }

  Future<void> _save() async {
    final web = _webUrlController.text.trim();
    final tiny = _tinyUrlController.text.trim();

    await AppSettingsService.updateWebsiteLinks(
      websiteUrl: web.isEmpty ? AppSettingsService.defaultWebsiteUrl : web,
      tinyUrl: tiny.isEmpty ? null : tiny,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
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
          Icon(Icons.edit, color: AppColors.lakeCyan, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Edit Website & TinyURL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize your public website destination and custom TinyURL shortlink. '
                      'Players will use this link to view live cumulative standings and pairings.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Website Destination URL
                    const Text(
                      'Website Destination URL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _webUrlController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        prefixIcon: const Icon(Icons.public, color: AppColors.lakeCyan, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste, color: AppColors.cyanLight, size: 20),
                          tooltip: 'Paste from Clipboard',
                          onPressed: () => _pasteInto(_webUrlController),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Short Link / TinyURL
                    const Text(
                      'Custom Short Link (TinyURL)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.duneSand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter any custom tinyurl.com link you created (e.g. https://tinyurl.com/arcadia2027)',
                      style: TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tinyUrlController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://tinyurl.com/...',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        prefixIcon: const Icon(Icons.bolt, color: AppColors.duneSand, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste, color: AppColors.cyanLight, size: 20),
                          tooltip: 'Paste from Clipboard',
                          onPressed: () => _pasteInto(_tinyUrlController),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick Fill Active Cloudflare URL button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cyanLight,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'Reset to Active Cloudflare Tunnel URL',
                        style: TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                      ),
                      onPressed: () {
                        setState(() {
                          _webUrlController.text = AppSettingsService.defaultWebsiteUrl;
                          _tinyUrlController.text = AppSettingsService.defaultTinyUrl;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lakeCyan,
            foregroundColor: const Color(0xFF04110A),
          ),
          onPressed: _save,
          icon: const Icon(Icons.check, size: 18),
          label: const Text(
            'Save Links',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
