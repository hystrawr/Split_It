import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../providers/currency_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/member_chip.dart';
import '../widgets/primary_button.dart';

/// Route arguments for /addExpense. [expenseId] is set only when editing.
class AddExpenseArgs {
  const AddExpenseArgs({required this.groupId, this.expenseId});

  final String? groupId;
  final String? expenseId;
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const List<String> _categories = ['Food', 'Ride', 'Bills', 'Others'];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _whereController = TextEditingController();
  final _itemController = TextEditingController();

  String _currency = 'PHP';
  String _category = _categories.first;

  /// Member ids, not names, since two members could share a name.
  String? _paidBy;
  final Set<String> _dividedWith = {};

  /// Set after the first Save tap so the "Divided with" error only shows then.
  bool _submitted = false;

  /// True while saving, so Save can't be tapped twice.
  bool _saving = false;

  /// The fields are filled from the group / expense once, the first time
  /// the providers are read.
  bool _initialized = false;

  Group? _group;

  /// The expense being edited, or null when adding.
  Expense? _original;

  AddExpenseArgs? get _args =>
      ModalRoute.of(context)?.settings.arguments as AddExpenseArgs?;

  bool get _isEditing => _args?.expenseId != null;

  List<Member> get _members => _group?.members ?? const [];

  /// PHP first, then every currency Frankfurter can convert.
  List<String> _currencyCodes(CurrencyProvider currencies) => [
    'PHP',
    for (final currency in currencies.currencies)
      if (currency.code != 'PHP') currency.code,
  ];

  /// The rate to save with the expense (1 PHP = rate × currency).
  /// An edited expense keeps its saved rate unless the currency changes,
  /// so old expenses don't move when the rates do.
  double? _rateFor(CurrencyProvider currencies) {
    if (_currency == 'PHP') return 1;
    final original = _original;
    if (original != null && original.currency == _currency) {
      return original.rate;
    }
    return currencies.rateFor(_currency);
  }

  /// "≈ ₱1456.00 · 1 USD = ₱58.24 (Frankfurter)". Null hides the line.
  String? _conversionText(CurrencyProvider currencies) {
    final rate = _rateFor(currencies);
    if (rate == null || rate == 0) return null;
    final rateText = '1 $_currency = ${_peso(1 / rate)} (Frankfurter)';
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return rateText;
    return '≈ ${_peso(amount / rate)} · $rateText';
  }

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  bool get _isDirty {
    final original = _original;
    if (original == null) {
      return _amountController.text.isNotEmpty ||
          _whereController.text.isNotEmpty ||
          _itemController.text.isNotEmpty ||
          _paidBy != null ||
          _dividedWith.isNotEmpty;
    }
    return double.tryParse(_amountController.text.trim()) != original.amount ||
        _whereController.text.trim() != original.where ||
        _itemController.text.trim() != original.item ||
        _currency != original.currency ||
        _category != original.category ||
        _paidBy != original.paidBy ||
        !setEquals(_dividedWith, original.splitWith.toSet());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final groups = context.read<GroupProvider>();
    final args = _args;
    final expenseId = args?.expenseId;
    _original = expenseId == null ? null : groups.expenseById(expenseId);
    final groupId = _original?.groupId ?? args?.groupId;
    _group = groupId == null ? null : groups.groupById(groupId);

    final original = _original;
    if (original != null) {
      _amountController.text = _formatAmount(original.amount);
      _whereController.text = original.where;
      _itemController.text = original.item;
      _currency = original.currency;
      _category = _categories.contains(original.category)
          ? original.category
          : _categories.last;
      _paidBy = original.paidBy;
      _dividedWith.addAll(original.splitWith);
    } else if (_group != null) {
      _currency = _group!.defaultCurrency;
    }
  }

  /// 300.0 → "300", 12.5 → "12.5", so the field looks like what was typed.
  static String _formatAmount(double amount) => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toString();

  @override
  void dispose() {
    _amountController.dispose();
    _whereController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await ConfirmDialog.show(
      context,
      title: 'Discard expense?',
      message: 'The details you entered will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (discard && mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState!.validate();
    if (!formValid || _dividedWith.isEmpty) return;

    final group = _group;
    if (group == null) return;

    final rate = _rateFor(context.read<CurrencyProvider>());
    if (rate == null || rate == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No rate for $_currency yet. Retry or use PHP."),
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final original = _original;
    final expense = Expense(
      id: original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      groupId: group.id,
      where: _whereController.text.trim(),
      item: _itemController.text.trim(),
      category: _category,
      amount: amount,
      currency: _currency,
      rate: rate,
      amountPhp: amount / rate,
      paidBy: _paidBy!,
      // Member order, so the split breakdown lists people the same way.
      splitWith: [
        for (final member in group.members)
          if (_dividedWith.contains(member.id)) member.id,
      ],
      date: original?.date ?? DateTime.now(),
    );

    setState(() => _saving = true);
    final groups = context.read<GroupProvider>();
    if (original == null) {
      await groups.addExpense(expense);
    } else {
      await groups.updateExpense(expense);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter an amount';
    if (amount <= 0) return 'Amount must be more than 0';
    return null;
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return 'Enter $field';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: _isEditing ? 'Edit Expense' : 'Add Expense',
          showBack: false,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildAmountCard(),
                const SizedBox(height: 20),
                _buildLabel('Where'),
                TextFormField(
                  controller: _whereController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Panda Coffee',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) => _validateRequired(value, 'a place'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildLabel('Item'),
                TextFormField(
                  controller: _itemController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Iced latte',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (value) => _validateRequired(value, 'an item'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildLabel('Category'),
                _buildCategoryChips(),
                const SizedBox(height: 16),
                _buildLabel('Paid by'),
                _buildPaidByDropdown(),
                const SizedBox(height: 16),
                _buildLabel('Divided with'),
                _buildDividedWith(),
                const SizedBox(height: 28),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildAmountCard() {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: AppColors.sage,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'Amount',
            style: textTheme.titleMedium?.copyWith(color: AppColors.darkGreen),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  style: textTheme.headlineMedium,
                  decoration: const InputDecoration(hintText: '0.00'),
                  validator: _validateAmount,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildCurrencyPill(),
              ),
            ],
          ),
          _buildConversionLine(),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill() {
    final currencies = context.watch<CurrencyProvider>();

    return PopupMenuButton<String>(
      tooltip: 'Currency',
      initialValue: _currency,
      onSelected: (code) => setState(() => _currency = code),
      itemBuilder: (_) => [
        for (final code in _currencyCodes(currencies))
          PopupMenuItem(value: code, child: Text(code)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          border: const Border.fromBorderSide(AppTheme.outlineSide),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(
              _currency,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
            const Icon(Icons.expand_more, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// "≈ ₱… · 1 USD = ₱…" under the amount, with loading and error states.
  /// Hidden for PHP since nothing needs converting.
  Widget _buildConversionLine() {
    if (_currency == 'PHP') return const SizedBox.shrink();

    final currencies = context.watch<CurrencyProvider>();
    final text = _conversionText(currencies);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.darkGreen);

    if (text == null && currencies.isLoading) {
      return Row(
        spacing: 8,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          Text('Getting the latest rate…', style: style),
        ],
      );
    }

    if (text == null) {
      return Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              currencies.errorMessage ?? "Couldn't get the $_currency rate.",
              style: style?.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: context.read<CurrencyProvider>().loadRates,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Text(text, style: style);
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in _categories)
          ChoiceChip(
            label: Text(category),
            selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
          ),
      ],
    );
  }

  // DropdownMenu like the currency picker on Add Group, so the menu has the
  // app's outline. FormField keeps the "Choose who paid" check.
  Widget _buildPaidByDropdown() {
    return FormField<String>(
      initialValue: _paidBy,
      validator: (value) => value == null ? 'Choose who paid' : null,
      builder: (field) => DropdownMenu<String>(
        initialSelection: _members.any((m) => m.id == _paidBy) ? _paidBy : null,
        hintText: 'Choose who paid',
        errorText: field.errorText,
        // full width, like the other fields
        expandedInsets: EdgeInsets.zero,
        // tapping opens the menu without the keyboard
        requestFocusOnTap: false,
        // DropdownMenu skips the app's input theme by default, which loses
        // the white fill
        inputDecorationTheme: Theme.of(context).inputDecorationTheme,
        leadingIcon: const Icon(Icons.person_outline),
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
          for (final member in _members)
            DropdownMenuEntry(
              value: member.id,
              label: member.name,
              trailingIcon: member.id == _paidBy
                  ? const Icon(Icons.check, size: 18)
                  : null,
              style: _menuItemStyle(selected: member.id == _paidBy),
            ),
        ],
        onSelected: (memberId) {
          field.didChange(memberId);
          setState(() => _paidBy = memberId);
        },
      ),
    );
  }

  /// menu row: amber pill for the picked member, light amber on hover
  static ButtonStyle _menuItemStyle({required bool selected}) {
    return MenuItemButton.styleFrom(
      backgroundColor: selected ? AppColors.amber : Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      overlayColor: AppColors.paid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildDividedWith() {
    final textTheme = Theme.of(context).textTheme;

    if (_members.isEmpty) {
      return Text(
        'No members in this group yet.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in _members)
              MemberChip(
                name: member.name,
                selected: _dividedWith.contains(member.id),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _dividedWith.add(member.id);
                  } else {
                    _dividedWith.remove(member.id);
                  }
                }),
              ),
          ],
        ),
        if (_submitted && _dividedWith.isEmpty)
          Text(
            'Pick at least one person',
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
      ],
    );
  }

  Widget _buildActions() {
    // IntrinsicHeight + stretch keeps Cancel as tall as Save, whose icon
    // makes it a little taller.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Cancel',
              color: AppColors.surface,
              expand: true,
              onPressed: _cancel,
            ),
          ),
          Expanded(
            child: PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Save',
              icon: Icons.check,
              expand: true,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
