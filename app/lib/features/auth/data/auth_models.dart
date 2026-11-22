/// Data models representing authenticated user and household data.
class UserModel {
  final String id;
  final String name;
  final String identifier;
  final String householdId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.identifier,
    required this.householdId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      identifier: json['identifier'] as String? ?? '',
      householdId: json['household_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'identifier': identifier,
      'household_id': householdId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class HouseholdModel {
  final String id;
  final String name;
  final String inviteCode;
  final bool isActive;
  final List<String> memberIds;

  HouseholdModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.isActive,
    required this.memberIds,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'My Kitchen',
      inviteCode: json['invite_code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      memberIds: (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
