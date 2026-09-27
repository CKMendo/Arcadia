import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../repository/course_repository.dart';

class CourseEditScreen extends StatefulWidget {
  final CourseRepository courseRepository;

  const CourseEditScreen({
    super.key,
    required this.courseRepository,
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

  // Tees
  final List<_TeeItem> _tees = [
    _TeeItem(name: 'Blue', rating: 73.0, slope: 135, yardage: 6800),
    _TeeItem(name: 'White', rating: 71.0, slope: 128, yardage: 6300),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initHoles(18);
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
        const SnackBar(content: Text('At least one tee box is required')),
      );
      return;
    }
    setState(() {
      _tees.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one tee box')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final teeInputs = _tees.map((t) {
        return TeeBoxInput(
          name: t.name,
          courseRating: t.rating,
          slopeRating: t.slope,
          totalYardage: t.yardage,
        );
      }).toList();

      await widget.courseRepository.createCourse(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        holeCount: _holeCount,
        pars: _pars,
        strokeIndexes: _strokeIndexes,
        tees: teeInputs,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving course: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Course'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COURSE INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name *',
                        hintText: 'e.g. Arcadia Bluffs (The Bluffs)',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(labelText: 'State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Holes: ', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('18 Holes'),
                          selected: _holeCount == 18,
                          onSelected: (sel) {
                            if (sel) setState(() => _initHoles(18));
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('9 Holes'),
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

            // Tees Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TEE BOXES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.gold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addTee,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Tee'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.goldLight,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_tees.length, (idx) {
                      final tee = _tees[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF072118),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: tee.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Tee Name',
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
                                    decoration: const InputDecoration(
                                      labelText: 'Rating',
                                      hintText: '72.4',
                                      isDense: true,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (val) => tee.rating =
                                        double.tryParse(val) ?? tee.rating,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: tee.slope.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Slope',
                                      hintText: '135',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) =>
                                        tee.slope = int.tryParse(val) ?? tee.slope,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.white54),
                                  onPressed: () => _removeTee(idx),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Holes Configuration
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HOLE CONFIGURATION (PAR & HCP INDEX)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppColors.gold,
                          ),
                        ),
                        Text(
                          'Par ${_pars.fold(0, (sum, p) => sum + p)}',
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_holeCount, (i) {
                      final holeNum = i + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                '#$holeNum',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Par:', style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 6),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 3, label: Text('3')),
                                ButtonSegment(value: 4, label: Text('4')),
                                ButtonSegment(value: 5, label: Text('5')),
                              ],
                              selected: {_pars[i]},
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onSelectionChanged: (set) {
                                setState(() => _pars[i] = set.first);
                              },
                            ),
                            const Spacer(),
                            const Text('HCP:', style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 60,
                              child: DropdownButton<int>(
                                value: _strokeIndexes[i],
                                isDense: true,
                                dropdownColor: AppColors.cardDark,
                                underline: const SizedBox.shrink(),
                                items: List.generate(_holeCount, (idx) => idx + 1)
                                    .map((si) => DropdownMenuItem(
                                          value: si,
                                          child: Text('$si'),
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
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save Course'),
            ),
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

  _TeeItem({
    required this.name,
    required this.rating,
    required this.slope,
    required this.yardage,
  });
}
