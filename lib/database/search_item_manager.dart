import 'dart:convert';

import 'chapter_item.dart';
import 'search_item.dart';
import '../global.dart';

class SearchItemManager {
  static List<SearchItem> _searchItem;
  static List<SearchItem> get searchItem => _searchItem;
  static String get key => Global.searchItemKey;

  static String genChapterKey(int id) => "chapter$id";

  /// 根据类型和排序规则取出收藏
  static List<SearchItem> getSearchItemByType(int contentType, SortType sortType) {
    final searchItem = <SearchItem>[];
    _searchItem.forEach((element) {
      if (element.ruleContentType == contentType) searchItem.add(element);
    });
    //排序
    switch (sortType) {
      case SortType.CREATE:
        searchItem.sort((a, b) => b.createTime.compareTo(a.createTime));
        break;
      case SortType.UPDATE:
        searchItem.sort((a, b) => b.updateTime.compareTo(a.updateTime));
        break;
      case SortType.LASTREAD:
        searchItem.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
        break;
    }
    return searchItem;
  }

  static bool isFavorite(String originTag, String url) {
    return _searchItem.any((item) => item.originTag == originTag && item.url == url);
  }

  static Future<bool> toggleFavorite(SearchItem searchItem) {
    if (isFavorite(searchItem.originTag, searchItem.url)) {
      return removeSearchItem(searchItem.url, searchItem.id);
    } else {
      //添加时间信息
      searchItem.createTime = DateTime.now().microsecondsSinceEpoch;
      searchItem.updateTime = DateTime.now().microsecondsSinceEpoch;
      searchItem.lastReadTime = DateTime.now().microsecondsSinceEpoch;
      return addSearchItem(searchItem);
    }
  }

  static Future<bool> addSearchItem(SearchItem searchItem) async {
    _searchItem.add(searchItem);
    return await saveSearchItem() &&
        await saveChapter(searchItem.id, searchItem.chapters);
  }

  static List<ChapterItem> getChapter(int id) {
    return LocalStorage
        .getStringList(genChapterKey(id))
        .map((item) => ChapterItem.fromJson(jsonDecode(item)))
        .toList();
  }

  static void initSearchItem() {
    _searchItem = <SearchItem>[];
    LocalStorage
        .getStringList(key)
        ?.forEach((item) => _searchItem.add(SearchItem.fromJson(jsonDecode(item))));
  }

  static Future<bool> removeSearchItem(String url, int id) async {
    await LocalStorage.remove(genChapterKey(id));
    _searchItem.removeWhere((item) => item.url == url);
    return saveSearchItem();
  }

  static Future<bool> saveSearchItem() async {
    return await LocalStorage.set(
        key, _searchItem.map((item) => jsonEncode(item.toJson())).toList());
  }

  static Future<bool> removeChapter(int id) {
    return LocalStorage.remove(genChapterKey(id));
  }

  static Future<bool> saveChapter(int id, List<ChapterItem> chapters) async {
    return await LocalStorage.set(
        genChapterKey(id), chapters.map((item) => jsonEncode(item.toJson())).toList());
  }

  static Future<String> backupItems() async {
    if (_searchItem == null || _searchItem.isEmpty)
      initSearchItem();
    String s = json.encode(_searchItem.map((item) {
      Map<String, dynamic> json = item.toJson();
      json["chapters"] =
          getChapter(item.id).map((chapter) => jsonEncode(chapter.toJson())).toList();
      return json;
    }).toList());
    return s;
  }

  static Future<bool> restore(String data) async {
    List json = jsonDecode(data);
    json.forEach((item) {
      SearchItem searchItem = SearchItem.fromJson(item);
      if (!isFavorite(searchItem.originTag, searchItem.url)) {
        List<ChapterItem> chapters = (jsonDecode('${item["chapters"]}') as List)
            .map((chapter) => ChapterItem.fromJson(chapter))
            .toList();
        saveChapter(searchItem.id, chapters);
        _searchItem.add(searchItem);
      }
    });
    saveSearchItem();
    return true;
  }
}

enum SortType { UPDATE, CREATE, LASTREAD }
