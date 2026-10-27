import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/currency_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/member_chip.dart';
import '../widgets/primary_button.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final FocusNode _memberFocus = FocusNode();
  String _currency = 'PHP';

  /// members except owner
  final List<String> _members = [];
  String? _memberError;

  /// true while saving, so Create Group can't be tapped twice
  bool _saving = false;

  /// all members
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

  /// true once smtng is picked
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

  Future<void> _createGroup() async {
    final nameValid = _formKey.currentState!.validate();
    final enoughMembers = _memberCount >= 2;
    if (!enoughMembers) {
      setState(() => _memberError = 'Add at least one other member');
    }
    if (!nameValid || !enoughMembers) return;

    setState(() => _saving = true);
    await context.read<GroupProvider>().addGroup(
      name: _nameController.text.trim(),
      defaultCurrency: _currency,
      // GroupProvider makes the first name the owner.
      memberNames: ['You', ..._members],
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // back system
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
                  // clears the error after name being written
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // erebuild so the backbutton knows the from has data
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
                _buildCurrencyField(),
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
                  onPressed: _saving ? null : _createGroup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// currency picker filled from Frankfurter /currencies (CurrencyProvider),
  /// with loading and error states
  Widget _buildCurrencyField() {
    final currencyProvider = context.watch<CurrencyProvider>();

    if (currencyProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      );
    }

    final currencies = currencyProvider.currencies;
    if (currencies.isEmpty) {
      // no list (e.g. no internet); PHP still works since it needs no rate
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            currencyProvider.errorMessage ?? "Couldn't load currencies.",
            style: const TextStyle(color: AppColors.error),
          ),
          const Text('The group will use PHP for now.'),
          PrimaryButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: context.read<CurrencyProvider>().loadRates,
          ),
        ],
      );
    }

    // DropdownMenu, not DropdownButtonFormField: only its menu can have an
    // outline, so it matches the app's cards
    return DropdownMenu<String>(
      initialSelection: currencies.any((c) => c.code == _currency)
          ? _currency
          : null,
      // full width, like the other fields
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      // tapping opens the menu without the keyboard
      requestFocusOnTap: false,
      // DropdownMenu skips the app's input theme by default, which loses
      // the white fill
      inputDecorationTheme: Theme.of(context).inputDecorationTheme,
      trailingIcon: const Icon(Icons.keyboard_arrow_down),
      selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up),
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(AppTheme.outlineSide),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      ),
      dropdownMenuEntries: [
        for (final currency in currencies)
          DropdownMenuEntry(
            value: currency.code,
            label: '${currency.code} · ${currency.name}',
            trailingIcon: currency.code == _currency
                ? const Icon(Icons.check, size: 18)
                : null,
            style: _currencyItemStyle(selected: currency.code == _currency),
          ),
      ],
      onSelected: (value) {
        if (value != null) setState(() => _currency = value);
      },
    );
  }

  /// menu row: amber pill for the picked currency, light amber on hover
  static ButtonStyle _currencyItemStyle({required bool selected}) {
    return MenuItemButton.styleFrom(
      backgroundColor: selected ? AppColors.amber : Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      overlayColor: AppColors.paid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
