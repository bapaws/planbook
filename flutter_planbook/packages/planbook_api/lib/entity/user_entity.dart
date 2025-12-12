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
    this.launchCount = 0,
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
      lastLaunchAppAt: map['last_launch_app_at'] != null
          ? DateTime.parse(map['last_launch_app_at'] as String)
          : null,
      launchCount: map['launch_count'] as int? ?? 0,
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
  final int launchCount;

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
    lastLaunchAppAt,
    launchCount,
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
    DateTime? lastLaunchAppAt,
    int? launchCount,
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
      lastLaunchAppAt: lastLaunchAppAt ?? this.lastLaunchAppAt,
      launchCount: launchCount ?? this.launchCount,
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
      if (lastLaunchAppAt != null)
        'last_launch_app_at': lastLaunchAppAt?.toIso8601String(),
      'launch_count': launchCount,
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

  /// 脱敏手机号：显示前3位和后4位，中间用*代替
  /// 例如：138****1234
  String _maskPhone(String phone) {
    if (phone.length <= 7) {
      // 如果手机号长度不足，直接返回
      return phone;
    }
    if (phone.length == 11) {
      // 标准11位手机号：显示前3位和后4位
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    } else {
      // 其他长度的手机号：显示前3位和后3位
      final visibleEnd = phone.length > 6 ? 3 : phone.length - 3;
      final maskLength = phone.length - 3 - visibleEnd;
      return '${phone.substring(0, 3)}${'*' * maskLength}${phone.substring(phone.length - visibleEnd)}';
    }
  }

  /// 脱敏邮箱：显示@前面的前2-3位和@后面的完整域名
  /// 例如：ab***@example.com 或 abc***@example.com
  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex == -1) {
      // 如果没有@符号，直接返回
      return email;
    }
    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (localPart.length <= 2) {
      // 如果@前面只有1-2个字符，显示1个字符
      return '${localPart[0]}***$domain';
    } else if (localPart.length <= 4) {
      // 如果@前面有3-4个字符，显示前2个字符
      return '${localPart.substring(0, 2)}***$domain';
    } else {
      // 如果@前面有5个或更多字符，显示前3个字符
      return '${localPart.substring(0, 3)}***$domain';
    }
  }

  String? get displayName {
    if (profile?.username != null && profile!.username!.isNotEmpty) {
      return profile!.username!;
    }
    if (phone != null && phone!.isNotEmpty) return _maskPhone(phone!);
    if (email != null && email!.isNotEmpty) return _maskEmail(email!);
    return 'me';
  }

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
