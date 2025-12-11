import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/tag/supabase_tag_api.dart';

class TagsRepository {
  TagsRepository({
    required SharedPreferences sp,
    required DatabaseTagApi tagApi,
  }) : _tagApi = tagApi,
       _supabaseTagApi = SupabaseTagApi(sp: sp),
       _db = tagApi.db;

  final DatabaseTagApi _tagApi;
  final SupabaseTagApi _supabaseTagApi;
  final AppDatabase _db;

  Stream<List<Tag>> getTopLevelTags() {
    return _tagApi.getTopLevelTags();
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
  }) {
    _syncTags();
    return _tagApi.getAllTags(notIncludeTagIds: notIncludeTagIds);
  }

  Future<void> _syncTags({
    bool force = false,
  }) async {
    final tags = await _supabaseTagApi.getLatestTags(force: force);
    await _db.transaction(() async {
      for (final tag in tags) {
        await _db.into(_db.tags).insertOnConflictUpdate(tag);
      }
    });
  }

  Future<TagEntity?> getTagEntityById(String id) async {
    return _tagApi.getTagEntityById(id);
  }

  Future<TagEntity?> getTagEntityByName(String name) async {
    return _tagApi.getTagEntityByName(name);
  }

  Future<void> createTag({
    required String name,
    required ColorScheme lightColorScheme,
    required ColorScheme darkColorScheme,
    String? id,
    TagEntity? parentTag,
  }) async {
    await _tagApi.createTag(
      name: name,
      lightColorScheme: lightColorScheme,
      darkColorScheme: darkColorScheme,
      id: id,
      parentTag: parentTag,
    );
  }

  Future<void> updateTag({
    required String id,
    String? name,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
    TagEntity? parentTag,
  }) async {
    await _tagApi.updateTag(
      id: id,
      name: name,
      lightColorScheme: lightColorScheme,
      darkColorScheme: darkColorScheme,
      parentTag: parentTag,
    );
  }

  /// 递归删除 tag 及其所有子 tag
  Future<void> deleteTag(String id) async {
    await _tagApi.deleteTag(id);
  }

  Future<void> deleteTagById(String id) async {
    await _tagApi.deleteTagById(id);
  }

  Future<void> deleteAllTags() async {
    await _tagApi.deleteAllTags();
  }
}
