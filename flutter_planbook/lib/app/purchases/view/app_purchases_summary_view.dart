// import 'package:flutter/material.dart';
// import 'package:diaryx/l10n/l10n.dart';

// class AppPurchasesSummaryView extends StatelessWidget {
//   const AppPurchasesSummaryView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final l10n = context.l10n;
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 16,
//       ),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.surfaceContainerHighest,
//         ),
//       ),
//       child: DefaultTextStyle(
//         style: theme.textTheme.titleMedium!.copyWith(
//           color: theme.colorScheme.onSurface,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSummaryRow('🗓️', l10n.unlimitedTask),
//             _buildSummaryRow('🏷', l10n.unlimitedTag),
//             _buildSummaryRow('📋', l10n.unlimitedNote),
//             _buildSummaryRow('💾', l10n.unlimitedStorage),
//             _buildSummaryRow('🚀', l10n.unlimitedFutureFeatures),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         vertical: 8,
//       ),
//       child: Row(
//         children: [
//           Text(icon),
//           const SizedBox(width: 8),
//           Text(text),
//         ],
//       ),
//     );
//   }
// }
