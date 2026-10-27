import 'package:flutter/material.dart';

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

/// Add/Edit Expense screen (/addExpense). Expects [AddExpenseArgs] as the
/// route argument: the groupId, plus the expenseId when editing.
///
/// UI only. Members, currencies, the conversion line and saving all come
/// from the data layer; nothing is calculated or stored here.
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
  String? _paidBy;
  final Set<String> _dividedWith = {};

  /// Set after the first Save tap so the "Divided with" error only shows then.
  bool _submitted = false;

  AddExpenseArgs? get _args =>
      ModalRoute.of(context)?.settings.arguments as AddExpenseArgs?;

  bool get _isEditing => _args?.expenseId != null;

  // TODO: read these from GroupProvider / CurrencyProvider once the data
  // layer is in. When editing, also fill the controllers and fields above
  // from the expense.
  List<String> get _members => const [];
  List<String> get _currencyCodes => const ['PHP'];

  // TODO: the conversion line from CurrencyProvider, e.g.
  // "≈ ₱1,456.00 · 1 USD = ₱58.24 (Frankfurter)". Null hides the line.
  bool get _rateLoading => false;
  String? get _rateError => null;
  String? get _conversionText => null;

  // TODO: ask CurrencyProvider for the rate again.
  void _retryRate() {}

  bool get _isDirty =>
      _amountController.text.isNotEmpty ||
      _whereController.text.isNotEmpty ||
      _itemController.text.isNotEmpty ||
      _paidBy != null ||
      _dividedWith.isNotEmpty;

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

  void _save() {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState!.validate();
    if (!formValid || _dividedWith.isEmpty) return;

    // TODO: save (or update) the expense through GroupProvider.
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
      canPop: !_isDirty,
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
    return PopupMenuButton<String>(
      tooltip: 'Currency',
      initialValue: _currency,
      onSelected: (code) => setState(() => _currency = code),
      itemBuilder: (_) => [
        for (final code in _currencyCodes)
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

    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.darkGreen);

    if (_rateLoading) {
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

    if (_rateError != null) {
      return Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _rateError!,
              style: style?.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(onPressed: _retryRate, child: const Text('Retry')),
        ],
      );
    }

    final text = _conversionText;
    if (text == null) return const SizedBox.shrink();
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

  Widget _buildPaidByDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paidBy,
      hint: const Text('Choose who paid'),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
      items: [
        for (final name in _members)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: (name) => setState(() => _paidBy = name),
      validator: (value) => value == null ? 'Choose who paid' : null,
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
            for (final name in _members)
              MemberChip(
                name: name,
                selected: _dividedWith.contains(name),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _dividedWith.add(name);
                  } else {
                    _dividedWith.remove(name);
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
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
