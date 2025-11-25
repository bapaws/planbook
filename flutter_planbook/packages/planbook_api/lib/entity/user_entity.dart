import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

enum UserGender {
  unknown,
  male,
  female,
}

enum AiFrequency {
  high,
  medium,
  low;

  int get maxCount {
    return switch (this) {
      AiFrequency.high => 5,
      AiFrequency.medium => 3,
      _ => 1,
    };
  }
}

int getRewardDiamonds(int level) {
  return level * (level % 10 == 0 ? 2 : 1);
}

class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.username,
    this.avatar,
    this.gender,
    this.birthday,
    this.lastLaunchAppAt,
  });

  factory UserProfileEntity.fromMap(Map<String, dynamic> map) {
    final genderValue = map['gender'] as String?;
    final gender = switch (genderValue) {
      'male' => UserGender.male,
      'female' => UserGender.female,
      _ => UserGender.unknown,
    };
    return UserProfileEntity(
      id: map['id'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      username: map['username'] as String?,
      avatar: map['avatar'] as String?,
      gender: gender,
      birthday: map['birthday'] != null
          ? DateTime.parse(map['birthday'] as String)
          : null,
    );
  }

  factory UserProfileEntity.fromJson(String source) =>
      UserProfileEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  final String id;
  final String? username;
  final String? avatar;
  final UserGender? gender;
  final DateTime? birthday;
  final DateTime? lastLaunchAppAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    username,
    avatar,
    gender,
    birthday,
  ];

  UserProfileEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? username,
    String? avatar,
    UserGender? gender,
    DateTime? birthday,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt?.toIso8601String(),
      if (username != null) 'username': username,
      if (avatar != null) 'avatar': avatar,
      if (gender != null) 'gender': gender?.name,
      if (birthday != null) 'birthday': birthday?.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  // levelValue = (((level - 1) + ... + 1) * 5)
  // int get currentLevel {
  //   if (levelValue == 0) {
  //     return 1; // 0 篇笔记也对应 1 级
  //   } else {
  //     final level = ((1 + sqrt(1 + 8 * levelValue / 5.0)) / 2).floor();
  //     return level;
  //   }
  // }

  // /// 计算升级到下一级需要的 levelValue
  // int get nextLevelRequiredValue {
  //   final nextLevel = currentLevel + 1;
  //   return ((nextLevel * (nextLevel - 1)) / 2 * 5).ceil();
  // }

  // /// 计算当前等级进度百分比 (0.0 - 1.0)
  // double get levelProgress {
  //   final level = currentLevel;
  //   final currentLevelValue = (level * (level - 1)) / 2 * 5;
  //   final nextLevelValue = nextLevelRequiredValue;

  //   if (nextLevelValue == currentLevelValue) return 1;

  //   final progress =
  //       (levelValue - currentLevelValue) / (nextLevelValue - currentLevelValue);
  //   return progress.clamp(0.0, 1.0);
  // }

  // /// 计算距离下一级还需要多少 levelValue
  // int get remainingValueForNextLevel {
  //   return nextLevelRequiredValue - levelValue;
  // }
}

class UserEntity extends Equatable {
  const UserEntity({
    required this.user,
    this.profile,
  });

  String get id => user.id;
  String? get email => user.email;
  String? get phone => user.phone;
  DateTime get createdAt => DateTime.parse(user.createdAt);

  final supabase.User user;
  final UserProfileEntity? profile;

  String? get name => profile?.username;
  String? get avatar => profile?.avatar;
  DateTime? get birthday => profile?.birthday;
  UserGender? get gender => profile?.gender;

  int get joinDays => DateTime.now().difference(createdAt).inDays;
  String get nickname => name ?? 'me';

  UserEntity copyWith({
    supabase.User? user,
    UserProfileEntity? profile,
  }) {
    return UserEntity(
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [
    user,
    profile,
  ];
}
