import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:split_it/providers/currency_provider.dart';
import 'package:split_it/services/frankfurter_service.dart';

/// A fake API that answers /rates and /currencies like Frankfurter does.
MockClient _fakeApi() {
  return MockClient((request) async {
    if (request.url.path.endsWith('/rates')) {
      return http.Response(
        '[{"date":"2026-10-25","base":"PHP","quote":"USD","rate":0.02}]',
        200,
      );
    }
    return http.Response(
      '[{"iso_code":"PHP","name":"Philippine Peso"},'
      '{"iso_code":"USD","name":"United States Dollar"}]',
      200,
    );
  });
}

void main() {
  test('loadRates ends in success and fills the currency list', () async {
    final provider = CurrencyProvider(
      service: FrankfurterService(client: _fakeApi()),
    );

    await provider.loadRates();

    expect(provider.status, LoadStatus.success);
    expect(provider.currencies.length, 2);
  });

  test('convertToPhp divides by the rate', () async {
    final provider = CurrencyProvider(
      service: FrankfurterService(client: _fakeApi()),
    );
    await provider.loadRates();

    // 1 PHP = 0.02 USD, so 25 USD = 25 / 0.02 = 1250 PHP.
    expect(provider.convertToPhp(25, 'USD'), closeTo(1250, 0.001));
    expect(provider.convertToPhp(100, 'PHP'), 100);
    expect(provider.convertToPhp(10, 'EUR'), isNull);
  });

  test('loadRates ends in error when the API fails', () async {
    final failing = MockClient((request) async => http.Response('', 500));
    final provider = CurrencyProvider(
      service: FrankfurterService(client: failing),
    );

    await provider.loadRates();

    expect(provider.status, LoadStatus.error);
    expect(provider.errorMessage, isNotNull);
    expect(provider.hasRates, isFalse);
  });
}
