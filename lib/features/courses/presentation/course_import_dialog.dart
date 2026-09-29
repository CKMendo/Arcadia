import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../repository/course_repository.dart';
import '../services/course_import_service.dart';

class CourseImportDialog extends StatefulWidget {
  final CourseRepository courseRepository;

  const CourseImportDialog({
    super.key,
    required this.courseRepository,
  });

  static Future<String?> show(BuildContext context, CourseRepository repository) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF091420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CourseImportDialog(courseRepository: repository),
    );
  }

  @override
  State<CourseImportDialog> createState() => _CourseImportDialogState();
}

class _CourseImportDialogState extends State<CourseImportDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _promptCourseController = TextEditingController();
  final TextEditingController _csvController = TextEditingController();
  final TextEditingController _csvCourseNameController = TextEditingController(text: 'Arcadia Bluffs (The Bluffs)');
  final TextEditingController _csvCityController = TextEditingController(text: 'Arcadia');
  final TextEditingController _csvStateController = TextEditingController(text: 'MI');

  bool _isPromptExpanded = false;
  CourseImportData? _previewData;
  String? _parseError;
  bool _isImporting = false;

  final List<CourseImportData> _presets = CourseImportService.getBuiltInPresets();
  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initial preview set to first preset
    if (_presets.isNotEmpty) {
      _previewData = _presets.first;
    }
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {
      _parseError = null;
      if (_tabController.index == 0) {
        _previewData = _presets[_selectedPresetIndex];
      } else if (_tabController.index == 1) {
        _updateJsonPreview();
      } else if (_tabController.index == 2) {
        _updateCsvPreview();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    _promptCourseController.dispose();
    _csvController.dispose();
    _csvCourseNameController.dispose();
    _csvCityController.dispose();
    _csvStateController.dispose();
    super.dispose();
  }

  void _updateJsonPreview() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _previewData = null;
        _parseError = null;
      });
      return;
    }
    try {
      final parsed = CourseImportService.parseJson(text);
      setState(() {
        _previewData = parsed;
        _parseError = null;
      });
    } catch (e) {
      setState(() {
        _previewData = null;
        _parseError = 'Invalid JSON: $e';
      });
    }
  }

  void _updateCsvPreview() {
    final text = _csvController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _previewData = null;
        _parseError = null;
      });
      return;
    }
    try {
      final parsed = CourseImportService.parseScorecardText(
        text,
        defaultName: _csvCourseNameController.text.trim().isNotEmpty
            ? _csvCourseNameController.text.trim()
            : 'Imported Course',
        defaultCity: _csvCityController.text.trim(),
        defaultState: _csvStateController.text.trim(),
      );
      setState(() {
        _previewData = parsed;
        _parseError = null;
      });
    } catch (e) {
      setState(() {
        _previewData = null;
        _parseError = 'Could not parse scorecard: $e';
      });
    }
  }

  Future<void> _importSelectedCourse() async {
    if (_previewData == null) return;
    setState(() => _isImporting = true);

    try {
      final courseId = await widget.courseRepository.createCourse(
        name: _previewData!.name,
        city: _previewData!.city,
        state: _previewData!.state,
        holeCount: _previewData!.holeCount,
        pars: _previewData!.pars,
        strokeIndexes: _previewData!.strokeIndexes,
        tees: _previewData!.tees,
      );

      if (mounted) {
        Navigator.of(context).pop(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F3826),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Successfully imported "${_previewData!.name}" with complete hole & distance info!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing course: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lakeCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_download, color: AppColors.lakeCyan, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Golf Course',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      Text(
                        'Import full hole pars, stroke indexes, & tee yardages',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.lakeCyan,
              indicatorWeight: 3,
              labelColor: AppColors.cyanLight,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Presets'),
                Tab(icon: Icon(Icons.code, size: 18), text: 'JSON'),
                Tab(icon: Icon(Icons.table_chart, size: 18), text: 'Scorecard CSV'),
              ],
            ),
          ),

          // Tab content + preview
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildJsonTab(),
                _buildCsvTab(),
              ],
            ),
          ),

          // Bottom Import Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF07101A),
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_previewData != null && !_isImporting) ? _importSelectedCourse : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lakeCyan,
                    foregroundColor: const Color(0xFF04111D),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isImporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline, size: 24),
                  label: Text(
                    _previewData != null
                        ? 'Import "${_previewData!.name}" (${_previewData!.holeCount} Holes)'
                        : 'Select or Paste Course Data',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: PRESETS
  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'SELECT A VERIFIED COURSE PRESET:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: AppColors.cyanLight,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(_presets.length, (idx) {
          final p = _presets[idx];
          final isSelected = _selectedPresetIndex == idx;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isSelected ? const Color(0xFF0F2B3E) : AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.lakeCyan : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedPresetIndex = idx;
                  _previewData = p;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.lakeCyan : Colors.white38,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.city}, ${p.state} • ${p.holeCount} Holes • Par ${p.totalPar}',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tees: ${p.tees.map((t) => '${t.name} (${t.totalYardage} yds)').join(', ')}',
                            style: const TextStyle(fontSize: 13, color: AppColors.duneLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildPreviewCard(),
      ],
    );
  }

  // TAB 2: JSON
  Widget _buildAiInstructionTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F263B), Color(0xFF091827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lakeCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.cyanLight, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW TO GET COURSE JSON WITH AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: AppColors.cyanLight,
                      ),
                    ),
                    Text(
                      'Get 18-hole scorecards for any course in seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF133628),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'ChatGPT • Claude • Gemini',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '1. Enter the course name below (optional).\n2. Tap "Copy AI Course Prompt" and paste it into ChatGPT, Claude, or Gemini.\n3. Copy the AI reply and tap "Paste from Clipboard" below.',
            style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCourseController,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Target Course Name (Optional)',
              hintText: 'e.g. Whistling Straits, Pebble Beach, Pine Valley',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.golf_course, color: AppColors.lakeCyan, size: 20),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final courseName = _promptCourseController.text.trim();
                    final prompt = CourseImportService.getAiPromptTemplate(
                      courseName: courseName.isNotEmpty ? courseName : null,
                    );
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF132235),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                courseName.isNotEmpty
                                    ? 'AI Prompt for "$courseName" copied! Paste into ChatGPT, Claude, or Gemini.'
                                    : 'AI Course Prompt copied! Paste into ChatGPT, Claude, or Gemini.',
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy AI Course Prompt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lakeCyan,
                    foregroundColor: const Color(0xFF04111D),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isPromptExpanded = !_isPromptExpanded;
                  });
                },
                icon: Icon(_isPromptExpanded ? Icons.expand_less : Icons.visibility_outlined, size: 18),
                label: Text(_isPromptExpanded ? 'Hide' : 'Preview Prompt'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          if (_isPromptExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF06111D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                CourseImportService.getAiPromptTemplate(
                  courseName: _promptCourseController.text.trim().isNotEmpty
                      ? _promptCourseController.text.trim()
                      : null,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJsonTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAiInstructionTile(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PASTE & IMPORT JSON:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppColors.cyanLight,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _jsonController.text = CourseImportService.getSampleJsonTemplate();
                    _updateJsonPreview();
                  },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Load Demo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: CourseImportService.getSampleJsonTemplate()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Raw JSON schema copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Schema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _jsonController,
          maxLines: 7,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Paste complete course JSON here (markdown code blocks and raw JSON are automatically parsed)...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => _updateJsonPreview(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _jsonController.text = data!.text!;
                  _updateJsonPreview();
                }
              },
              icon: const Icon(Icons.paste, size: 18),
              label: const Text('Paste from Clipboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.cyanLight,
              ),
            ),
            if (_jsonController.text.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _jsonController.clear();
                  _updateJsonPreview();
                },
                icon: const Icon(Icons.clear, color: Colors.white60, size: 20),
                tooltip: 'Clear',
              ),
            ],
            const Spacer(),
            if (_previewData != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3826),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF34D399)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Color(0xFF34D399)),
                    const SizedBox(width: 6),
                    Text(
                      'Valid (${_previewData!.holeCount} Holes, ${_previewData!.tees.length} Tees)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (_parseError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(_parseError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        _buildPreviewCard(),
      ],
    );
  }

  // TAB 3: SCORECARD CSV
  Widget _buildCsvTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _csvCourseNameController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  isDense: true,
                ),
                onChanged: (_) => _updateCsvPreview(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _csvCityController,
                style: const TextStyle(fontSize: 15, color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'City',
                  isDense: true,
                ),
                onChanged: (_) => _updateCsvPreview(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _csvStateController,
                style: const TextStyle(fontSize: 15, color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'State',
                  isDense: true,
                ),
                onChanged: (_) => _updateCsvPreview(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCORECARD DATA (Hole, Par, HCP, Tees):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppColors.cyanLight,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _csvController.text = CourseImportService.getSampleScorecardCsv();
                _updateCsvPreview();
              },
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text('Load Sample', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _csvController,
          maxLines: 7,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Hole, 1, 2, 3...\nPar, 5, 3, 5...\nHCP, 5, 9, 17...\nBlue, 490, 175, 505...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => _updateCsvPreview(),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _csvController.text = data!.text!;
              _updateCsvPreview();
            }
          },
          icon: const Icon(Icons.paste, size: 18),
          label: const Text('Paste Scorecard from Clipboard'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            foregroundColor: AppColors.cyanLight,
          ),
        ),
        if (_parseError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Text(_parseError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        _buildPreviewCard(),
      ],
    );
  }

  // PREVIEW CARD WITH HOLE SCORECARD & YARDAGES
  Widget _buildPreviewCard() {
    if (_previewData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'No course preview available yet.',
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    final p = _previewData!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.visibility, color: AppColors.lakeCyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'COURSE PREVIEW',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.cyanLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lakeCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lakeCyan),
                ),
                child: Text(
                  '${p.holeCount} HOLES • PAR ${p.totalPar}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyanLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(
            '${p.city}, ${p.state}',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.cardBorder, height: 20),

          // Tees List
          const Text(
            'TEE BOXES & RATINGS:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          ...p.tees.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorFromHex(t.colorHex),
                      border: Border.all(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${t.totalYardage} yds)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${t.courseRating.toStringAsFixed(1)} / ${t.slopeRating}',
                    style: const TextStyle(color: AppColors.lakeCyan, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          // Hole-by-Hole Scorecard Matrix (Scrollable horizontal table)
          const Text(
            'HOLE-BY-HOLE DETAILS & DISTANCES:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(48),
              border: TableBorder.all(color: AppColors.cardBorder, width: 1),
              children: [
                // Header row: Hole #
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF142436)),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Hole', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                      ),
                    ),
                    ...List.generate(p.holeCount, (i) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.cyanLight)),
                          ),
                        )),
                  ],
                ),
                // Par row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF0F1E2E)),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Par', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                      ),
                    ),
                    ...p.pars.map((par) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text('$par', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                          ),
                        )),
                  ],
                ),
                // HCP row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFF0F1E2E)),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('HCP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                      ),
                    ),
                    ...p.strokeIndexes.map((si) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text('$si', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.duneSand)),
                          ),
                        )),
                  ],
                ),
                // Yardage rows per tee
                ...p.tees.map((tee) {
                  return TableRow(
                    decoration: BoxDecoration(color: const Color(0xFF16283C).withValues(alpha: 0.7)),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            tee.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...List.generate(p.holeCount, (i) {
                        final holeNum = i + 1;
                        final yd = tee.holeYardages?[holeNum];
                        return TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              yd != null ? '$yd' : '-',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    final clean = hex.replaceAll('#', '');
    final val = int.tryParse('FF$clean', radix: 16);
    return val != null ? Color(val) : Colors.blue;
  }
}
