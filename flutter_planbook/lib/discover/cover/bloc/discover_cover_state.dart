part of 'discover_cover_bloc.dart';

final class DiscoverCoverState extends Equatable {
  const DiscoverCoverState({
    required this.year,
    this.selectedCoverPath,
    this.builtinCovers = const [],
    this.builtinColorSchemes = const [],
    this.status = PageStatus.initial,
  });

  static const defaultBuiltinCovers = <String>[
    'assets/images/cover.jpg',
    'assets/images/cover1.jpg',
    'https://images.unsplash.com/photo-1696937059544-d27af28d458d?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/photo-1579546928686-286c9fbde1ec?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1756550984584-9f63f43fe10d?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1577398628395-4ebd1f36731b?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1652804961521-c9fbc7a3f0f1?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/photo-1552324190-9e86fa095c4a?w=525&h=747&auto=format&fit=crop&q=60',

    'assets/images/cover2.jpg',
    'https://images.unsplash.com/photo-1578926078640-668b1fb75403?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1578926078693-4eb3d4499e43?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1576504365365-091376931772?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/vector-1749578421397-b35fff9bc733?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1752297637713-28fb74bff04a?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1752297641412-e4e89076a1ac?q=60&w=525&h=747&auto=format&fit=crop',
    'https://images.unsplash.com/vector-1752297633507-18a235a72b79?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1751865858183-ca2921ef918c?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1760200828835-87714b82fea5?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1743605778103-66e504db0168?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1577086664705-2beb311a8029?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1749703676619-3ddf1eb2a819?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/vector-1749703676502-911c395c7649?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1752730654476-5f283681b342?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1752730647832-8a04b0c9d985?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1752730654216-5124c8254fb6?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/vector-1749981795632-4495fef7ec8c?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1746468548860-007780956ab3?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1743420288372-cec70e856256?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/vector-1749730126421-31f04d0bb763?w=525&h=747&auto=format&fit=crop&q=60',

    'https://images.unsplash.com/vector-1758961913832-c739cc004167?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1759147175663-28b58cdd9cd1?w=525&h=747&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/vector-1749484636449-a642b4ff5c1d?w=525&h=747&auto=format&fit=crop&q=60',
  ];

  final int year;
  final String? selectedCoverPath;
  final List<String> builtinCovers;
  final List<ColorScheme> builtinColorSchemes;
  final PageStatus status;

  @override
  List<Object?> get props => [
    year,
    selectedCoverPath,
    builtinCovers,
    builtinColorSchemes,
    status,
  ];

  DiscoverCoverState copyWith({
    int? year,
    String? selectedCoverPath,
    List<String>? builtinCovers,
    List<ColorScheme>? builtinColorSchemes,
    PageStatus? status,
  }) {
    return DiscoverCoverState(
      year: year ?? this.year,
      selectedCoverPath: selectedCoverPath ?? this.selectedCoverPath,
      builtinCovers: builtinCovers ?? this.builtinCovers,
      builtinColorSchemes: builtinColorSchemes ?? this.builtinColorSchemes,
      status: status ?? this.status,
    );
  }
}
