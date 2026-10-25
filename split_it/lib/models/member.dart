class Member {
  const Member({
    required this.id,
    required this.name,
    this.isOwner = false,
  });

  final String id;
  final String name;
  final bool isOwner;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isOwner': isOwner,
    };
  }
}