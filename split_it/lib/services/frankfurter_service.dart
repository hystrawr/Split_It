import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/currency.dart';
import '../models/exchange_rate.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FrankfurterService {
  FrankfurterService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://api.frankfurter.dev/v2';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  Future<List<ExchangeRate>> fetchRates({String base = 'PHP'}) async {
    final data = await _getList('/rates?base=$base');
    return data
        .map((r) => ExchangeRate.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Currency>> fetchCurrencies() async {
    final data = await _getList('/currencies');
    return data
        .map((c) => Currency.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> _getList(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl$path'))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'Server error (${response.statusCode}). Please try again.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const ApiException('Received unexpected data from the server.');
      }
      return decoded;
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on http.ClientException {
      throw const ApiException('No internet connection.');
    } on TimeoutException {
      throw const ApiException('The request timed out. Check your connection.');
    } on FormatException {
      throw const ApiException('Received unexpected data from the server.');
    }
  }
}
