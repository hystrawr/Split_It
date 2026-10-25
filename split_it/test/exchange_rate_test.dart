import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:split_it/models/currency.dart';
import 'package:split_it/models/exchange_rate.dart';
import 'package:split_it/services/frankfurter_service.dart';

void main() {
  test('ExchangeRate.fromJson reads a Frankfurter rate', () {
    final rate = ExchangeRate.fromJson({
      'date': '2026-10-25',
      'base': 'PHP',
      'quote': 'USD',
      'rate': 0.01587,
    });

    expect(rate.quote, 'USD');
    expect(rate.rate, 0.01587);
  });

  test('ExchangeRate.fromJson accepts a whole-number rate', () {
    final rate = ExchangeRate.fromJson({
      'date': '2026-10-25',
      'base': 'PHP',
      'quote': 'XYZ',
      'rate': 2,
    });

    expect(rate.rate, 2.0);
  });

  test('Currency.fromJson reads iso_code as code', () {
    final currency = Currency.fromJson({
      'iso_code': 'USD',
      'name': 'United States Dollar',
    });

    expect(currency.code, 'USD');
  });

  test('fetchRates parses a successful response', () async {
    final client = MockClient((request) async {
      return http.Response(
        '[{"date":"2026-10-25","base":"PHP","quote":"USD","rate":0.01587}]',
        200,
      );
    });

    final rates = await FrankfurterService(client: client).fetchRates();

    expect(rates.single.quote, 'USD');
  });

  test('fetchRates throws ApiException when the server fails', () async {
    final client = MockClient((request) async {
      return http.Response('{"message":"invalid currency"}', 422);
    });

    expect(
      FrankfurterService(client: client).fetchRates(),
      throwsA(isA<ApiException>()),
    );
  });

  test('fetchRates throws ApiException on invalid JSON', () async {
    final client = MockClient((request) async {
      return http.Response('not json', 200);
    });

    expect(
      FrankfurterService(client: client).fetchRates(),
      throwsA(isA<ApiException>()),
    );
  });
}
