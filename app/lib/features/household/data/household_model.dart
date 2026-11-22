/// Model representing a household.
class HouseholdModel {
  final String id;
  final String name;
  final String inviteCode;
  final bool isActive;
  final List<Member> members;

  HouseholdModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.isActive,
    required this.members,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      isActive: json['is_active'] as bool,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => Member.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Member of a household.
class Member {
  final String id;
  final String name;

  Member({required this.id, required this.name});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
