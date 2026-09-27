import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../../database/app_database.dart';
import '../../../shared/theme/app_colors.dart';
import '../repository/player_repository.dart';

class PlayerEditScreen extends StatefulWidget {
  final PlayerRepository playerRepository;
  final Player? player;

  const PlayerEditScreen({
    super.key,
    required this.playerRepository,
    this.player,
  });

  @override
  State<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends State<PlayerEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _initialsController;
  late TextEditingController _hcpController;
  late TextEditingController _ghinController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String? _preferredTee;
  final _teeOptions = ['Black', 'Blue', 'White', 'Gold', 'Red'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _nicknameController = TextEditingController(text: p?.nickname ?? '');
    _initialsController = TextEditingController(text: p?.initials ?? '');
    _hcpController = TextEditingController(
      text: p != null ? p.handicapIndex.toString() : '10.0',
    );
    _ghinController = TextEditingController(text: p?.ghinNumber ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _preferredTee = p?.preferredTee ?? 'White';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _initialsController.dispose();
    _hcpController.dispose();
    _ghinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final hcp = double.tryParse(_hcpController.text.trim()) ?? 10.0;
      final fullName = _nameController.text.trim();
      final nickname = _nicknameController.text.trim();
      final initials = _initialsController.text.trim();
      final ghin = _ghinController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (widget.player == null) {
        await widget.playerRepository.createPlayer(
          fullName: fullName,
          nickname: nickname.isNotEmpty ? nickname : null,
          initials: initials.isNotEmpty ? initials : null,
          handicapIndex: hcp,
          preferredTee: _preferredTee,
          ghinNumber: ghin.isNotEmpty ? ghin : null,
          phoneNumber: phone.isNotEmpty ? phone : null,
          email: email.isNotEmpty ? email : null,
        );
      } else {
        final updated = widget.player!.copyWith(
          fullName: fullName,
          nickname: nickname.isNotEmpty ? nickname : fullName.split(' ').first,
          initials: initials.isNotEmpty ? initials.toUpperCase() : widget.player!.initials,
          handicapIndex: hcp,
          preferredTee: Value(_preferredTee),
          ghinNumber: Value(ghin.isNotEmpty ? ghin : null),
          phoneNumber: Value(phone.isNotEmpty ? phone : null),
          email: Value(email.isNotEmpty ? email : null),
        );
        await widget.playerRepository.updatePlayer(updated);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving player: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Player?'),
        content: Text('Remove "${widget.player?.fullName}" from the trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.player != null) {
      await widget.playerRepository.deletePlayer(widget.player!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.player != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Player' : 'Add Player'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Neal Patel',
                prefixIcon: Icon(Icons.person, color: AppColors.goldLight),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      hintText: 'e.g. Neal',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _initialsController,
                    decoration: const InputDecoration(
                      labelText: 'Initials',
                      hintText: 'NP',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hcpController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Handicap Index *',
                      hintText: '8.7',
                      prefixIcon: Icon(Icons.calculate, color: AppColors.goldLight),
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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _preferredTee,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Tee',
                    ),
                    items: _teeOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _preferredTee = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ghinController,
              decoration: const InputDecoration(
                labelText: 'GHIN Number',
                hintText: 'Optional',
                prefixIcon: Icon(Icons.badge, color: AppColors.goldLight),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'For text score updates',
                prefixIcon: Icon(Icons.phone, color: AppColors.goldLight),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Optional',
                prefixIcon: Icon(Icons.email, color: AppColors.goldLight),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Create Player'),
            ),
          ],
        ),
      ),
    );
  }
}
