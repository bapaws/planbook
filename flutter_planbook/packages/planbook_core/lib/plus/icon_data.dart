// import 'dart:convert';

// import 'package:flutter/material.dart';

// extension IconDataPlus on IconData {
//   Map<String, dynamic> toMap() {
//     return {
//       'codePoint': codePoint,
//       'fontFamily': fontFamily,
//       'fontPackage': fontPackage,
//       'matchTextDirection': matchTextDirection,
//       'fontFamilyFallback': fontFamilyFallback,
//     };
//   }

//   String toJson() {
//     return jsonEncode(toMap());
//   }

//   static IconData fromMap(Map<String, dynamic> map) {
//     return IconData(
//       map['codePoint'] as int,
//       fontFamily: map['fontFamily'] as String?,
//       fontPackage: map['fontPackage'] as String?,
//       matchTextDirection: map['matchTextDirection'] as bool,
//       fontFamilyFallback: map['fontFamilyFallback'] as List<String>?,
//     );
//   }

//   static IconData? fromJson(String json) {
//     try {
//       if (json.isEmpty) {
//         return null;
//       }
//       final map = jsonDecode(json) as Map;
//       return fromMap(Map<String, dynamic>.from(map));
//     } on Exception catch (e) {
//       debugPrint('Error parsing IconData from JSON: $e');
//       return null;
//     }
//   }
// }
