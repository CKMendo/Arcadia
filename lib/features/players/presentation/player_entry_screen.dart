import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/course_handicap_calculator.dart';
import '../../../shared/utils/player_initials_helper.dart';
import '../../../shared/widgets/player_avatar.dart';
import '../repository/player_repository.dart';

class PlayerEntryScreen extends StatefulWidget {
  final PlayerRepository playerRepository;
  final Player? player; // If non-null, editing mode; if null, entry mode

  const PlayerEntryScreen({
    super.key,
    required this.playerRepository,
    this.player,
  });

  @override
  State<PlayerEntryScreen> createState() => _PlayerEntryScreenState();
}

class _PlayerEntryScreenState extends State<PlayerEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hcpController;
  late TextEditingController _phoneController;

  // Optional fields
  late TextEditingController _nicknameController;
  late TextEditingController _ghinController;
  String? _preferredTee;
  String? _photoPath;

  final _teeOptions = ['Black', 'Blue', 'White', 'Gold', 'Red'];
  bool _isSaving = false;
  bool _showAdditionalDetails = false;

  bool get isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _hcpController = TextEditingController(
      text: p != null ? p.handicapIndex.toStringAsFixed(1) : '',
    );
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _nicknameController = TextEditingController(text: p?.nickname ?? '');
    _ghinController = TextEditingController(text: p?.ghinNumber ?? '');
    _preferredTee = p?.preferredTee ?? 'White';
    _photoPath = p?.photoPath;

    _nameController.addListener(_onFieldChanged);
    _hcpController.addListener(_onFieldChanged);

    if (isEditing &&
        ((p?.nickname != null && p!.nickname.isNotEmpty && p.nickname != p.fullName.split(' ').first) ||
            (p?.ghinNumber != null && p!.ghinNumber!.isNotEmpty))) {
      _showAdditionalDetails = true;
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hcpController.dispose();
    _phoneController.dispose();
    _nicknameController.dispose();
    _ghinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'player_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

        setState(() {
          _photoPath = savedFile.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Headshot selected! Tap Save to keep changes.', style: TextStyle(fontSize: 16)),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach photo: $e', style: const TextStyle(fontSize: 16))),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Headshot Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Upload a photo now or leave this space blank to fill in later.',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.lakeCyan, size: 24),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.lakeCyan, size: 24),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_photoPath != null && _photoPath!.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                  ),
                  title: const Text('Remove Photo (Leave Space)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final hcp = double.tryParse(_hcpController.text.trim()) ?? 10.0;
      final fullName = _nameController.text.trim();
      final nickname = _nicknameController.text.trim();
      final phone = _phoneController.text.trim();
      final ghin = _ghinController.text.trim();

      if (!isEditing) {
        await widget.playerRepository.createPlayer(
          fullName: fullName,
          nickname: nickname.isNotEmpty ? nickname : null,
          handicapIndex: hcp,
          preferredTee: _preferredTee,
          ghinNumber: ghin.isNotEmpty ? ghin : null,
          phoneNumber: phone.isNotEmpty ? phone : null,
          photoPath: _photoPath,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "$fullName" to the roster!', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.lakeDeep,
              duration: const Duration(seconds: 2),
            ),
          );

          // Reset form fields for rapid addition of next player
          _nameController.clear();
          _hcpController.clear();
          _phoneController.clear();
          _nicknameController.clear();
          _ghinController.clear();
          setState(() {
            _photoPath = null;
            _preferredTee = 'White';
          });
        }
      } else {
        final updated = widget.player!.copyWith(
          fullName: fullName,
          nickname: nickname.isNotEmpty ? nickname : fullName.split(' ').first,
          initials: PlayerInitialsHelper.compute(fullName),
          handicapIndex: hcp,
          preferredTee: Value(_preferredTee),
          ghinNumber: Value(ghin.isNotEmpty ? ghin : null),
          phoneNumber: Value(phone.isNotEmpty ? phone : null),
          photoPath: Value(_photoPath),
        );
        await widget.playerRepository.updatePlayer(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "$fullName"!', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving player: $e', style: const TextStyle(fontSize: 17))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.player == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Player?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text('Remove "${widget.player?.fullName}" from the trip?', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.playerRepository.deletePlayer(widget.player!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _computeInitials(String name) {
    return PlayerInitialsHelper.compute(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Player' : 'Player Entry'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
              tooltip: 'Delete Player',
              onPressed: _delete,
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tournament Branding Card with Crest
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F2236), Color(0xFF0A1522)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.duneSand, width: 1.5),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/arcadia_cup_crest.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ARCADIA COASTAL CUP 2027',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                      color: AppColors.cyanLight,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Golfer Profile & Roster Entry',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Headshot Section with prominent placeholder space
                      _buildHeadshotSpaceSection(),
                      const SizedBox(height: 22),

                      // NAME Field (Required)
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'NAME *',
                          hintText: 'e.g. Chet Mehta',
                          prefixIcon: Icon(Icons.person, color: AppColors.lakeCyan, size: 26),
                          helperText: 'Full golfer name for roster & scorecards',
                          helperStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter golfer name';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),

                      // Row for HANDICAP and PHONE NUMBER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HANDICAP Field (Required)
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: _hcpController,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'HANDICAP *',
                                hintText: '8.7',
                                prefixIcon: Icon(Icons.calculate, color: AppColors.lakeCyan, size: 26),
                                helperText: 'Current index',
                                helperStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Preferred Tee Box (Quick Selector)
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              initialValue: _preferredTee,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                              dropdownColor: AppColors.surfaceElevated,
                              decoration: const InputDecoration(
                                labelText: 'TEE',
                                helperText: 'Default tee',
                                helperStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                              items: _teeOptions
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _preferredTee = val),
                            ),
                          ),
                        ],
                      ),

                      // Live Calculated Course Handicaps
                      Builder(builder: (context) {
                        final hcp = double.tryParse(_hcpController.text.trim());
                        if (hcp == null) return const SizedBox(height: 18);
                        final tee = _preferredTee ?? 'White';
                        final bluffsCh = CourseHandicapCalculator.forBluffs(hcp, tee);
                        final southCh = CourseHandicapCalculator.forSouth(hcp, tee);
                        return Container(
                          margin: const EdgeInsets.only(top: 14, bottom: 18),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1F33),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.5), width: 1.4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.golf_course, color: AppColors.cyanLight, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'COURSE HANDICAPS ($tee Tee)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: AppColors.cyanLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'The Bluffs',
                                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'HCP $bluffsCh',
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'The South',
                                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'HCP $southCh',
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.duneSand),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // PHONE NUMBER Field (Required)
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'PHONE NUMBER *',
                          hintText: 'e.g. (313) 555-0188',
                          prefixIcon: Icon(Icons.phone, color: AppColors.lakeCyan, size: 26),
                          helperText: 'For live scoring notifications and group texts',
                          helperStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Additional Optional Details Toggle
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _showAdditionalDetails,
                          title: const Text(
                            'Additional Details (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyanLight,
                            ),
                          ),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nicknameController,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'Nickname',
                                      hintText: 'e.g. Chet',
                                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.lakeCyan, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _ghinController,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      labelText: 'GHIN #',
                                      hintText: 'Optional',
                                      prefixIcon: Icon(Icons.tag, color: AppColors.lakeCyan, size: 24),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF06111D)),
                              )
                            : Icon(isEditing ? Icons.check_circle : Icons.person_add, size: 26),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Add Player to Roster',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Section Header: Live Player List with Headshot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.format_list_bulleted, color: AppColors.cyanLight, size: 22),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'CURRENT ROSTER',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.1,
                                      color: AppColors.cyanLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<List<Player>>(
                            stream: widget.playerRepository.watchAllPlayers(),
                            builder: (context, snap) {
                              final count = snap.data?.length ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  '$count / 8 PLAYERS',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All entered players will appear below with headshots, handicaps, and phone numbers:',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Real-time List of Players with Headshots
              StreamBuilder<List<Player>>(
                stream: widget.playerRepository.watchAllPlayers(),
                builder: (context, snapshot) {
                  final players = snapshot.data ?? [];

                  if (players.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            const Text(
                              'No players added yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Fill in Name, Handicap, and Phone above, then tap "Add Player to Roster".',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await widget.playerRepository.seedSample8Players();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sample 8 players loaded with phone numbers!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.bolt, size: 20),
                              label: const Text('Load Sample 8 Players'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = players[index];
                          return _buildPlayerListItem(context, p);
                        },
                        childCount: players.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadshotSpaceSection() {
    final initials = _nameController.text.trim().isNotEmpty
        ? _computeInitials(_nameController.text)
        : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _photoPath != null ? AppColors.lakeCyan : AppColors.cardBorder,
          width: _photoPath != null ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          // Distinct Headshot Space with Camera Badge
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F1E2E),
                    border: Border.all(
                      color: _photoPath != null ? AppColors.lakeCyan : AppColors.lakeCyan.withValues(alpha: 0.6),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lakeCyan.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _photoPath != null && _photoPath!.isNotEmpty && File(_photoPath!).existsSync()
                        ? Image.file(
                            File(_photoPath!),
                            fit: BoxFit.cover,
                            width: 84,
                            height: 84,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                size: 28,
                                color: AppColors.cyanLight,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.lakeCyan,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceDark, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 15,
                      color: Color(0xFF06111D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Explanatory space info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'HEADSHOT SPACE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_photoPath != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lakeCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanLight)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _photoPath != null
                      ? 'Photo set! Tap photo to replace or remove.'
                      : 'Reserved space for headshot portrait. Leave blank now and fill in photos later, or tap to attach.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showPhotoOptions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _photoPath != null ? Icons.edit : Icons.add_photo_alternate,
                        size: 18,
                        color: AppColors.duneSand,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _photoPath != null ? 'Change photo' : 'Select photo (Optional)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.duneSand,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerListItem(BuildContext context, Player p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        // Headshot space left for player
        leading: PlayerAvatar(
          name: p.fullName,
          initials: p.initials,
          photoPath: p.photoPath,
          radius: 26,
          isHeadshotSpace: true,
          showBadge: true,
          badgeIcon: p.photoPath != null ? Icons.check : Icons.camera_alt,
          onTap: () => _updateExistingPlayerPhoto(p),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                p.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (p.nickname.isNotEmpty && p.nickname != p.fullName) ...[
              const SizedBox(width: 8),
              Text(
                '"${p.nickname}"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.duneSand,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // HANDICAP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.lakeCyan.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      'HCP ${p.handicapIndex.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lakeCyan,
                      ),
                    ),
                  ),

                  // Course Handicaps for Bluffs and South
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1F33),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cyanLight.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Bluffs: ${CourseHandicapCalculator.forBluffs(p.handicapIndex, p.preferredTee ?? 'White')} • South: ${CourseHandicapCalculator.forSouth(p.handicapIndex, p.preferredTee ?? 'White')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyanLight,
                      ),
                    ),
                  ),

                  // PHONE NUMBER Badge
                  if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B3E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.cyanLight),
                          const SizedBox(width: 6),
                          Text(
                            p.phoneNumber!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Preferred Tee
                  if (p.preferredTee != null && p.preferredTee!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lakeDeep.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        '${p.preferredTee} Tee',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Headshot space status hint
              Text(
                p.photoPath != null && p.photoPath!.isNotEmpty
                    ? 'Photo attached • Tap avatar to change'
                    : 'Headshot space reserved • Tap avatar to fill in photo',
                style: TextStyle(
                  fontSize: 12,
                  color: p.photoPath != null ? AppColors.cyanLight : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.lakeCyan, size: 24),
          tooltip: 'Edit Player',
          onPressed: () => _editPlayer(p),
        ),
        onTap: () => _editPlayer(p),
      ),
    );
  }

  void _editPlayer(Player p) {
    if (isEditing && widget.player?.id == p.id) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerEntryScreen(
          playerRepository: widget.playerRepository,
          player: p,
        ),
      ),
    );
  }

  Future<void> _updateExistingPlayerPhoto(Player p) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Headshot for ${p.fullName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text('Attach or replace the player headshot:', style: TextStyle(fontSize: 15, color: Colors.white70)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.lakeCyan, size: 26),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'player_${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
                    await widget.playerRepository.updatePlayerPhoto(p.id, savedFile.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.lakeCyan, size: 26),
                title: const Text('Take Photo with Camera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'player_${p.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
                    await widget.playerRepository.updatePlayerPhoto(p.id, savedFile.path);
                  }
                },
              ),
              if (p.photoPath != null && p.photoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
                  title: const Text('Remove Photo (Leave Space)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.playerRepository.updatePlayerPhoto(p.id, null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
