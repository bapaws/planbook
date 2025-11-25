import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:planbook_api/planbook_api.dart';

class TagsRepository {
  TagsRepository({required DatabaseTagApi tagApi}) : _tagApi = tagApi;

  final DatabaseTagApi _tagApi;

  Future<Stream<List<Tag>>> getTopLevelTags() async {
    return _tagApi.getTopLevelTags();
  }

  Stream<List<TagEntity>> getAllTags({
    Set<String> notIncludeTagIds = const {},
  }) {
    return _tagApi.getAllTags(notIncludeTagIds: notIncludeTagIds);
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
