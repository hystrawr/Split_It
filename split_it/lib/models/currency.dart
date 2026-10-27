class Currency {
  const Currency({required this.code, required this.name});

  final String code;

  final String name;

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['iso_code'] as String,
      name: json['name'] as String,
    );
  }
}
