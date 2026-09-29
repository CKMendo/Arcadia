import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../repository/course_repository.dart';

class CourseEditScreen extends StatefulWidget {
  final CourseRepository courseRepository;
  final Course? course;

  const CourseEditScreen({
    super.key,
    required this.courseRepository,
    this.course,
  });

  @override
  State<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController(text: 'Arcadia');
  final _stateController = TextEditingController(text: 'MI');

  int _holeCount = 18;
  late List<int> _pars;
  late List<int> _strokeIndexes;

  // Tees with hole-by-hole yardages
  final List<_TeeItem> _tees = [
    _TeeItem(name: 'Blue', rating: 73.0, slope: 135, yardage: 6800),
    _TeeItem(name: 'White', rating: 71.0, slope: 128, yardage: 6300),
  ];

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      final c = widget.course!;
      _nameController.text = c.name;
      _cityController.text = c.city;
      _stateController.text = c.state;
      _holeCount = c.holeCount;
    }
    _initHoles(_holeCount);
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    if (widget.course == null) return;
    final details = await widget.courseRepository.getCourseDetails(widget.course!.id);
    if (details != null && mounted) {
      setState(() {
        _pars = details.holes.map((h) => h.par).toList();
        _strokeIndexes = details.holes.map((h) => h.strokeIndex).toList();
        if (details.teeBoxes.isNotEmpty) {
          _tees.clear();
          for (final t in details.teeBoxes) {
            _tees.add(_TeeItem(
              name: t.teeBox.name,
              rating: t.teeBox.courseRating,
              slope: t.teeBox.slopeRating,
              yardage: t.totalYardage,
              holeYardages: Map<int, int>.from(t.holeYardages),
            ));
          }
        }
      });
    }
  }

  void _initHoles(int count) {
    _holeCount = count;
    // Standard par 72: 4 par 3s, 10 par 4s, 4 par 5s
    _pars = List.generate(count, (i) {
      if (i == 2 || i == 5 || i == 12 || i == 16) return 3;
      if (i == 0 || i == 4 || i == 10 || i == 14) return 5;
      return 4;
    });
    _strokeIndexes = List.generate(count, (i) => i + 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _addTee() {
    setState(() {
      _tees.add(_TeeItem(name: 'Gold', rating: 68.5, slope: 122, yardage: 5800));
    });
  }

  void _removeTee(int index) {
    if (_tees.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one tee box is required', style: TextStyle(fontSize: 16)),
        ),
      );
      return;
    }
    setState(() {
      _tees.removeAt(index);
    });
  }

  Future<void> _confirmDeleteCourse() async {
    if (widget.course == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Delete Course?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${widget.course!.name}"? All associated hole pars, handicap ratings, and tee yardages will be removed.',
          style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 20),
            label: const Text('Delete Permanently', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await widget.courseRepository.deleteCourse(widget.course!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              content: Text(
                'Course "${widget.course!.name}" has been deleted.',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting course: $e')),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one tee box', style: TextStyle(fontSize: 16)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final teeInputs = _tees.map((t) {
        // If hole yardages exist and total yardage is 0, auto-sum
        int totalYardage = t.yardage;
        if (totalYardage == 0 && t.holeYardages.isNotEmpty) {
          totalYardage = t.holeYardages.values.fold(0, (sum, y) => sum + y);
        }

        return TeeBoxInput(
          name: t.name.trim(),
          courseRating: t.rating,
          slopeRating: t.slope,
          totalYardage: totalYardage,
          holeYardages: t.holeYardages.isNotEmpty ? t.holeYardages : null,
        );
      }).toList();

      if (widget.course != null) {
        // UPDATE EXISTING COURSE
        await widget.courseRepository.updateCourse(
          courseId: widget.course!.id,
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          holeCount: _holeCount,
          pars: _pars,
          strokeIndexes: _strokeIndexes,
          tees: teeInputs,
        );
      } else {
        // CREATE NEW COURSE
        await widget.courseRepository.createCourse(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          holeCount: _holeCount,
          pars: _pars,
          strokeIndexes: _strokeIndexes,
          tees: teeInputs,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving course: $e', style: const TextStyle(fontSize: 16)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course' : 'New Course'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
              tooltip: 'Delete Course',
              onPressed: (_isSaving || _isDeleting) ? null : _confirmDeleteCourse,
            ),
          TextButton(
            onPressed: (_isSaving || _isDeleting) ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.cyanLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Course Details Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COURSE INFORMATION',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.cyanLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Course Name *',
                        labelStyle: TextStyle(fontSize: 17),
                        hintText: 'e.g. Arcadia Bluffs (The Bluffs)',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cityController,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'City',
                              labelStyle: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _stateController,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'State',
                              labelStyle: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Holes: ',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text('18 Holes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          selected: _holeCount == 18,
                          onSelected: (sel) {
                            if (sel) setState(() => _initHoles(18));
                          },
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text('9 Holes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          selected: _holeCount == 9,
                          onSelected: (sel) {
                            if (sel) setState(() => _initHoles(9));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tees Card with hole yardages
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TEE BOXES & DISTANCES',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.cyanLight,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addTee,
                          icon: const Icon(Icons.add_circle_outline, size: 22),
                          label: const Text('Add Tee', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.cyanLight,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_tees.length, (idx) {
                      final tee = _tees[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: tee.name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Tee Name',
                                      labelStyle: TextStyle(fontSize: 15),
                                      isDense: true,
                                    ),
                                    onChanged: (val) => tee.name = val,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: tee.rating.toString(),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Rating',
                                      hintText: '72.4',
                                      labelStyle: TextStyle(fontSize: 15),
                                      isDense: true,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (val) => tee.rating = double.tryParse(val) ?? tee.rating,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: tee.slope.toString(),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Slope',
                                      hintText: '135',
                                      labelStyle: TextStyle(fontSize: 15),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => tee.slope = int.tryParse(val) ?? tee.slope,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    key: ValueKey('${tee.name}_totalYardage_${tee.yardage}'),
                                    initialValue: tee.yardage > 0 ? tee.yardage.toString() : '',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Total Yds',
                                      hintText: '6800',
                                      labelStyle: TextStyle(fontSize: 14),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => tee.yardage = int.tryParse(val) ?? tee.yardage,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 22, color: Colors.white54),
                                  onPressed: () => _removeTee(idx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Expandable hole yardages trigger
                            InkWell(
                              onTap: () {
                                setState(() => tee.isExpanded = !tee.isExpanded);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1B2B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          tee.isExpanded ? Icons.expand_less : Icons.expand_more,
                                          color: AppColors.cyanLight,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Hole Yardages for ${tee.name} (${tee.holeYardages.values.where((y) => y > 0).length}/$_holeCount set)',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                    if (tee.holeYardages.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          final sum = tee.holeYardages.values.fold(0, (s, y) => s + y);
                                          if (sum > 0) {
                                            setState(() => tee.yardage = sum);
                                          }
                                        },
                                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 24)),
                                        child: const Text('Auto-Sum Total', style: TextStyle(fontSize: 12, color: AppColors.lakeCyan)),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Expanded hole distance inputs
                            if (tee.isExpanded) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF081320),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(_holeCount, (hIdx) {
                                    final holeNum = hIdx + 1;
                                    final currentYd = tee.holeYardages[holeNum] ?? 0;

                                    return SizedBox(
                                      width: 78,
                                      child: TextFormField(
                                        initialValue: currentYd > 0 ? '$currentYd' : '',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '#$holeNum (${_pars[hIdx]}p)',
                                          labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanLight),
                                          hintText: 'yds',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          if (parsed != null && parsed > 0) {
                                            tee.holeYardages[holeNum] = parsed;
                                          } else {
                                            tee.holeYardages.remove(holeNum);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Holes Configuration (Par & HCP)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HOLE CONFIGURATION (PAR & HCP)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.cyanLight,
                          ),
                        ),
                        Text(
                          'Par ${_pars.fold(0, (sum, p) => sum + p)}',
                          style: const TextStyle(
                            color: AppColors.duneSand,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_holeCount, (i) {
                      final holeNum = i + 1;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: i.isEven ? AppColors.surfaceElevated.withAlpha(120) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '#$holeNum',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppColors.cyanLight,
                                ),
                              ),
                            ),
                            const Text(
                              'Par',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                  value: 3,
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                    child: Text('3', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 4,
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                    child: Text('4', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 5,
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                    child: Text('5', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                              selected: {_pars[i]},
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                visualDensity: VisualDensity.comfortable,
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              onSelectionChanged: (set) {
                                setState(() => _pars[i] = set.first);
                              },
                            ),
                            const Spacer(),
                            const Text(
                              'HCP',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButton<int>(
                                value: _strokeIndexes[i],
                                isDense: true,
                                dropdownColor: AppColors.surfaceElevated,
                                underline: const SizedBox.shrink(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                items: List.generate(_holeCount, (idx) => idx + 1)
                                    .map((si) => DropdownMenuItem(
                                          value: si,
                                          child: Text('$si', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _strokeIndexes[i] = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSaving || _isDeleting) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lakeCyan,
                  foregroundColor: const Color(0xFF04111D),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                child: Text(isEditing ? 'Save Changes' : 'Create Course'),
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: (_isSaving || _isDeleting) ? null : _confirmDeleteCourse,
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
                  label: const Text(
                    'Delete This Course',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _TeeItem {
  String name;
  double rating;
  int slope;
  int yardage;
  Map<int, int> holeYardages;
  bool isExpanded = false;

  _TeeItem({
    required this.name,
    required this.rating,
    required this.slope,
    required this.yardage,
    Map<int, int>? holeYardages,
  }) : holeYardages = holeYardages ?? {};
}
