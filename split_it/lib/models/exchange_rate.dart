class ExchangeRate {
  const ExchangeRate({
    required this.date,
    required this.base,
    required this.quote,
    required this.rate,
  });

  final String date;
  final String base;
  final String quote;
  final double rate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      date: json['date'] as String,
      base: json['base'] as String,
      quote: json['quote'] as String,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}
