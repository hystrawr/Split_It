import 'package:flutter/material.dart';

import '../widgets/app_header.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/member_chip.dart';
import '../widgets/primary_button.dart';

/// Add Group screen (/addGroup): group name, default currency and members.
class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  // TODO: load the currency list from Frankfurter /currencies via
  // CurrencyProvider, with loading and error states.
  static const List<String> _currencies = [
    'PHP',
    'USD',
    'EUR',
    'JPY',
    'KRW',
    'SGD',
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final FocusNode _memberFocus = FocusNode();
  String _currency = 'PHP';

  /// Members other than the owner, who is always in the group.
  final List<String> _members = [];
  String? _memberError;

  /// The owner plus everyone added below.
  int get _memberCount => _members.length + 1;

  @override
  void dispose() {
    _nameController.dispose();
    _memberController.dispose();
    _memberFocus.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    final taken =
        name.toLowerCase() == 'you' ||
        _members.any((m) => m.toLowerCase() == name.toLowerCase());

    setState(() {
      if (name.isEmpty) {
        _memberError = 'Enter a member name';
      } else if (taken) {
        _memberError = '$name is already in the group';
      } else {
        _members.add(name);
        _memberError = null;
        _memberController.clear();
      }
    });
    _memberFocus.requestFocus();
  }

  void _removeMember(String name) {
    setState(() => _members.remove(name));
  }

  /// True once the user has typed or picked anything.
  bool get _hasChanges =>
      _nameController.text.trim().isNotEmpty ||
      _memberController.text.trim().isNotEmpty ||
      _members.isNotEmpty ||
      _currency != 'PHP';

  Future<void> _confirmDiscard() async {
    final discard = await ConfirmDialog.show(
      context,
      title: 'Discard group?',
      message: 'The details you entered will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard && mounted) Navigator.pop(context);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a group name';
    }
    return null;
  }

  void _createGroup() {
    final nameValid = _formKey.currentState!.validate();
    final enoughMembers = _memberCount >= 2;
    if (!enoughMembers) {
      setState(() => _memberError = 'Add at least one other member');
    }
    if (!nameValid || !enoughMembers) return;

    // TODO: save the group through GroupProvider.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Back button and system back both go through here.
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: const AppHeader(title: 'New Group'),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text('Group name', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  // Clears the error as soon as the user types a name.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // Rebuild so the back button knows the form has data.
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Baguio trip',
                  ),
                ),
                const SizedBox(height: 20),
                Text('Default currency', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  items: [
                    for (final code in _currencies)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _currency = value);
                  },
                ),
                const SizedBox(height: 20),
                Text('Members ($_memberCount)', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildMemberInput(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const MemberChip(name: 'You', subtitle: 'owner'),
                    for (final member in _members)
                      MemberChip(
                        name: member,
                        onRemove: () => _removeMember(member),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Create Group',
                  expand: true,
                  onPressed: _createGroup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Expanded(
          child: TextField(
            controller: _memberController,
            focusNode: _memberFocus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            // Not onSubmitted: that also drops focus, so the next name
            // typed would be lost.
            onEditingComplete: _addMember,
            onChanged: (_) => setState(() => _memberError = null),
            decoration: InputDecoration(
              hintText: 'Member name',
              errorText: _memberError,
            ),
          ),
        ),
        PrimaryButton(label: 'Add', icon: Icons.add, onPressed: _addMember),
      ],
    );
  }
}
