import 'dart:async';
import 'dart:convert';

import 'package:eso/database/rule.dart';
import 'package:eso/evnts/restore_event.dart';
import 'package:eso/global.dart';
import 'package:eso/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditSourceProvider with ChangeNotifier {
  List<Rule> _rulesFilter;
  List<Rule> _rules;
  final int type;
  List<Rule> get rules => _ruleContentType < 0 ? _rules : _rulesFilter;
  bool _isLoading;
  bool get isLoading => _isLoading;

  bool _isLoadingUrl;
  bool get isLoadingUrl => _isLoadingUrl;

  /// 内容类型
  int _ruleContentType = -1;
  int get ruleContentType => _ruleContentType;
  set ruleContentType(v) => _setRuleContentType(v);

  EditSourceProvider({this.type = 1}) {
    _isLoadingUrl = false;
    _eventStream = eventBus.on<RestoreEvent>().listen((event) {
      refreshData();
    });
    refreshData();
  }

  Future<int> addFromUrl(String url, bool isFromYICIYUAN) async {
    if (isLoadingUrl) return 0;
    _isLoadingUrl = true;
    notifyListeners();
    try {
      final res = await http.get("$url", headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36'
      });
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json is Map) {
        final id = await Global.ruleDao.insertOrUpdateRule(
            isFromYICIYUAN ? Rule.fromYiCiYuan(json) : Rule.fromJson(json));
        if (id != null) {
          _isLoadingUrl = false;
          refreshData();
          return 1;
        }
      } else if (json is List) {
        final ids = await Global.ruleDao.insertOrUpdateRules(json
            .map((rule) => isFromYICIYUAN ? Rule.fromYiCiYuan(rule) : Rule.fromJson(rule))
            .toList());
        if (ids.length > 0) {
          _isLoadingUrl = false;
          refreshData();
          return ids.length;
        }
      }
    } catch (e) {}
    _isLoadingUrl = false;
    notifyListeners();
    return 0;
  }

  _setRuleContentType(int value) {
    _ruleContentType = value;
    if (_ruleContentType < 0) {
      _rulesFilter = null;
      return;
    }
    _rulesFilter = [];
    if (_rules == null) return;
    _rules.forEach((element) {
      if (element.contentType == value) _rulesFilter.add(element);
    });
  }

  //获取源列表 1所有 2发现
  void refreshData([bool reFindAllRules = true]) async {
    if (!reFindAllRules) {
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 100));
    switch (this.type) {
      case 1:
        _rules = await Global.ruleDao.findAllRules();
        break;
      case 2:
        _rules = await Global.ruleDao.findAllDiscoverRules();
        break;
    }
    _isLoading = false;
    _setRuleContentType(_ruleContentType);
    notifyListeners();
  }

  ///启用、禁用
  void toggleEnableSearch(Rule rule, [bool enable, bool notify = true]) async {
    if (_isLoading) return;
    _isLoading = true;
    rule.enableSearch = enable ?? !rule.enableSearch;
    await Global.ruleDao.insertOrUpdateRule(rule);
    if (notify == true) notifyListeners();
    _isLoading = false;
  }

  ///删除规则
  void deleteRule(Rule rule) async {
    if (_isLoading) return;
    _isLoading = true;
    _rules.remove(rule);
    await Global.ruleDao.deleteRule(rule);
    notifyListeners();
    _isLoading = false;
  }

  ///清空源
  void deleteAllRules() async {
    if (_isLoading) return;
    _isLoading = true;
    _rules.clear();
    await Global.ruleDao.clearAllRules();
    notifyListeners();
    _isLoading = false;
  }

  ///置顶
  void setSortMax(Rule rule) async {
    if (_isLoading) return;
    _isLoading = true;

    Rule maxSort = await Global.ruleDao.findMaxSort();
    rule.sort = maxSort.sort + 1;
    //更换顺序
    _rules.remove(rule);
    _rules.insert(0, rule);
    //保存到数据库
    await Global.ruleDao.insertOrUpdateRule(rule);
    notifyListeners();
    _isLoading = false;
  }

  SourceSortType lastSortType;

  DateTime _loadTime;
  void getRuleListByNameDebounce(String name) {
    _loadTime = DateTime.now();
    Future.delayed(const Duration(milliseconds: 301), () {
      if (DateTime.now().difference(_loadTime).inMilliseconds > 300) {
        getRuleListByName(name);
      }
    });
  }

  ///搜索
  void getRuleListByName(String name) async {
    switch (this.type) {
      case 1:
        _rules = await Global.ruleDao.getRuleByName('%$name%', '%$name%');
        break;
      case 2:
        _rules = await Global.ruleDao.getDiscoverRuleByName('%$name%', '%$name%');
        break;
    }
    _setRuleContentType(_ruleContentType);
    notifyListeners();
  }

  ///全选
  Future<void> toggleCheckAllRule() async {
    //循环处理（如果有未勾选则全选 没有则全不选）
    int _enCheck = _rules.indexWhere((e) => (!e.enableSearch), 0);
    _rules.forEach((rule) {
      rule.enableSearch = !(_enCheck < 0);
    });
    notifyListeners();
    //保存到数据库
    await Global.ruleDao.insertOrUpdateRules(_rules);
  }

  StreamSubscription _eventStream;

  @override
  void dispose() {
    _rules.clear();
    _eventStream.cancel();
    super.dispose();
  }

  static Future<List<Rule>> backupRules() async {
    return await Global.ruleDao.findAllRules();
  }

  static Future<bool> restore(List<dynamic> rules, bool reset) async {
    if (reset) await Global.ruleDao.clearAllRules();
    if (rules != null) {
      for (var item in rules) {
        var _rule = Rule.fromJson(item);
        await Global.ruleDao.insertOrUpdateRule(_rule);
      }
    }
    return true;
  }
}

/// 规则排序类型
enum SourceSortType {
  type,
  name,
  author,
  updateTime,
  createTime,
}
