import 'package:flutter/foundation.dart';

import '../models/currency.dart';
import '../services/frankfurter_service.dart';

/// Where a request is: not started, waiting, done, or failed.
enum LoadStatus { initial, loading, success, error }

/// Shared exchange-rate state for the Add Group and Add/Expense screens.
/// Rates are fetched once and cached, so every screen converts with the same
/// numbers without calling the API again.
class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider({FrankfurterService? service})
    : _service = service ?? FrankfurterService();

  final FrankfurterService _service;

  LoadStatus _status = LoadStatus.initial;
  String? _errorMessage;

  /// Quote currency → rate, where 1 PHP = rate × currency.
  Map<String, double> _rates = {};
  List<Currency> _currencies = [];

  LoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Currency> get currencies => _currencies;
  bool get isLoading => _status == LoadStatus.loading;

  /// True once rates have loaded at least once, even if a later reload failed.
  bool get hasRates => _rates.isNotEmpty;

  /// Fetches the latest rates and the currency list.
  /// On failure the last rates that loaded are kept, so conversion still works.
  Future<void> loadRates() async {
    _status = LoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final rates = await _service.fetchRates();
      final currencies = await _service.fetchCurrencies();

      _rates = {'PHP': 1.0, for (final rate in rates) rate.quote: rate.rate};
      // Only offer currencies that can actually be converted.
      _currencies = currencies
          .where((currency) => _rates.containsKey(currency.code))
          .toList();
      _status = LoadStatus.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = LoadStatus.error;
    }

    notifyListeners();
  }

  /// Converts [amount] in [currency] to PHP, or returns null if there is no
  /// rate for [currency] yet. Rates are 1 PHP = rate × currency, so we divide.
  double? convertToPhp(double amount, String currency) {
    final rate = _rates[currency];
    if (rate == null || rate == 0) return null;
    return amount / rate;
  }

  /// The rate saved with an expense (1 PHP = rate × currency), or null.
  double? rateFor(String currency) => _rates[currency];

  /// How many pesos one unit of [currency] is worth, e.g. 1 USD = ₱58.24.
  /// Used for the conversion line on the Add/Edit Expense screen.
  double? phpPerUnit(String currency) => convertToPhp(1, currency);
}
