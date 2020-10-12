import 'dart:convert';

import 'package:eso/database/rule.dart';
import 'package:eso/global.dart';
import 'package:eso/model/profile.dart';
import 'package:eso/page/source/debug_rule_page.dart';
import 'package:eso/ui/widgets/draggable_scrollbar_sliver.dart';
import 'package:eso/utils.dart';
import 'package:eso/utils/rule_comparess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api.dart';
import '../../fonticons_icons.dart';
import 'login_rule_page.dart';

class EditRulePage extends StatefulWidget {
  final Rule rule;
  const EditRulePage({
    this.rule,
    Key key,
  }) : super(key: key);
  @override
  _EditRulePageState createState() => _EditRulePageState();
}

class _EditRulePageState extends State<EditRulePage> with WidgetsBindingObserver {
  var isLoading = false;
  Color primaryColor;
  Rule rule;
  bool _infoExpanded = true;
  bool _discoverExpanded = true;
  bool _searchExpanded = true;
  bool _chapterExpanded = true;
  bool _contentExpanded = true;
  ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 快速输入符号List
// ignore: non_constant_identifier_names
  final inputList = [
    {
      'encoding': '"encoding":"gbk"',
      'get-gbk': r'''{
    "url": "/modules/article/search.php?searchkey=$keyword&searchtype=articlename&page=$page",
    "encoding": "gbk"
}''',
      'get-headers': r'''{
    "url": "/modules/article/search.php?searchkey=$keyword&searchtype=articlename&page=$page",
    "headers":{
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36 Edg/84.0.522.40"
    }
}''',
      'post-form1': r'''{
    "url": "/modules/article/search.php",
    "method": "POST",
    "body": "searchkey=$keyword&searchtype=articlename",
    "headers": {
        "Content-Type": "application/x-www-form-urlencoded"
    }
}''',
      'post-form2': r'''{
    "url": "/modules/article/search.php",
    "method": "POST",
    "body": {
        "searchkey": "$keyword",
        "searchtype": "articlename"
    }
}''',
      'post-json': r'''{
    "url": "/modules/article/search.php",
    "method": "POST",
    "body": "{\"searchkey\": \"$keyword\",\"searchtype\": \"articlename\"}",
    "headers":{
        "Content-Type": "application/json"
    }
}''',
      'post-json-by-js': r'''@js:
({
    "url": "/modules/article/search.php",
    "method": "POST",
    "body": JSON.stringify({
        "searchkey": keyword,
        "searchtype": "articlename"
    }),
    "headers":{
        "Content-Type": "application/json"
    }
})''',
      'post-headers': r'''{
    "url": "/modules/article/search.php",
    "method": "POST",
    "body": "searchkey=$keyword&searchtype=articlename",
    "headers": {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36 Edg/84.0.522.40"
    }
}''',
      'xpath_class': '//*[@class="xx"]',
      'xpath_id': '//*[@id="xx"]',
      'match': "result.match(/xx/)[0];",
      'stringify': "JSON.stringify({});",
      'parse': "JSON.parse(xx);",
      'Macintosh-UA':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.113 Safari/537.36',
      'Android-UA':
          'Mozilla/5.0 (Linux; Android 9; MIX 2 Build/PKQ1.190118.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/80.0.3987.99 Mobile Safari/537.36',
    },
    {
      '`': '`',
      '"': '"',
      '\'': '\'',
      '@': '@',
      ':': ':',
      '&': '&',
      '|': '|',
      '%': '%',
      '/': '/',
      '\\': '\\',
      '[': '[',
      ']': ']',
      '{': '{',
      '}': '}',
      '<': '<',
      '>': '>',
      '\$': '\$',
      '.': '.',
      '#': '#',
      'keyword': 'keyword',
      'page': 'page',
      'pageSize': 'pageSize',
      'host': 'host',
      'result': 'result',
      'lastResult': 'lastResult',
      'text': 'text',
      'href': 'href',
      'src': 'src',
      'headers': 'headers',
      'User-Agent': 'User-Agent',
    }
  ];

  @override
  Widget build(BuildContext context) {
    primaryColor = Theme.of(context).primaryColor;
    if (null == rule) {
      rule = widget.rule ?? Rule.newRule();
      _discoverExpanded = rule.enableDiscover;
      _searchExpanded = rule.enableSearch;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(widget.rule == null ? '新建规则' : '编辑规则'),
        actions: [
          IconButton(
            icon: Icon(
                Global.isDesktop ? FIcons.copy : FIcons.share_2),
            tooltip: Global.isDesktop ? "复制" : "分享",
            onPressed: () {
              if (Global.isDesktop) {
                Clipboard.setData(ClipboardData(text: RuleCompress.compass(rule)));
                Utils.toast("已保存到剪贴板");
              } else {
                FlutterShare.share(
                  title: '亦搜 eso',
                  text: RuleCompress.compass(rule), //jsonEncode(rule.toJson()),
                  //linkUrl: '${searchItem.url}',
                  chooserTitle: '选择分享的应用',
                );
              }
            },
          ),
          IconButton(
            icon: Icon(FIcons.save),
            iconSize: 21,
            tooltip: "保存",
            onPressed: () => _saveRule(context),
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: "调试",
            onPressed: () async {
              if (isLoading) return;
              isLoading = true;
              rule.modifiedTime = DateTime.now().microsecondsSinceEpoch;
              await Global.ruleDao.insertOrUpdateRule(rule);
              isLoading = false;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DebugRulePage(rule: rule)));
            },
          ),
          _buildpopupMenu(context),
        ],
      ),
      body: Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Expanded(
              child: DraggableScrollbar.semicircle(
            controller: _controller,
            child: ListView(
              controller: _controller,
              children: [
                _buildInfo(context),
                _buildDiscover(context),
                _buildSearch(context),
                _buildChapter(context),
                _buildContent(context),
              ],
            ),
          )),
          Offstage(
            offstage: false, //_isHideFastInput,
            child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: Global.lineSize))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: inputList.map((list) => _buildInputHelp(list)).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputHelp(Map<String, String> inputList) {
    final inputKeys = inputList.keys.toList();
    final inputValues = inputList.values.toList();
    return Container(
      height: 32,
      alignment: Alignment.center,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: inputKeys.length,
        physics: BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                inputKeys[index],
                style: TextStyle(fontSize: 16, height: 2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              final fastText = inputValues[index];
              final textSelection = currentController.selection;
              currentController.text = currentController.text.replaceRange(
                textSelection.start,
                textSelection.end,
                fastText,
              );
              currentOnChanged(currentController.text);
              currentController.selection = textSelection.copyWith(
                baseOffset: textSelection.end + fastText.length,
                extentOffset: textSelection.end + fastText.length,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailsText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: Profile.staticFontFamily,
        ),
      ),
    );
  }

  TextEditingController currentController;
  void Function(String text) currentOnChanged;

  Widget _buildEditText(
    String text,
    String labelText,
    void Function(String text) onChanged, {
    int minLines = 1,
    int maxLines,
  }) {
    final controller = TextEditingController(text: text);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        focusNode: FocusNode()
          ..addListener(() {
            currentController = controller;
            currentOnChanged = onChanged;
          }),
        minLines: minLines,
        maxLines: maxLines,
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: TextStyle(color: primaryColor),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle("基本规则"),
      initiallyExpanded: _infoExpanded,
      onExpansionChanged: (value) => _infoExpanded = value,
      children: [
        _buildDetailsText('创建时间：${DateTime.fromMicrosecondsSinceEpoch(rule.createTime)}'),
        _buildDetailsText(
            '修改时间：${DateTime.fromMicrosecondsSinceEpoch(rule.modifiedTime)}'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _buildDetailsText('类型(contentType)：'),
              DropdownButton<int>(
                isDense: true,
                value: rule.contentType,
                onChanged: (value) {
                  setState(() {
                    rule.contentType = value;
                  });
                },
                items: List.generate(
                  5,
                  (index) => DropdownMenuItem<int>(
                    child: Text(API.getRuleContentTypeName(index)),
                    value: index,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildEditText(
          rule.name,
          '名称(name)',
          (text) => rule.name = text,
          maxLines: 1,
        ),
        _buildEditText(
          rule.host,
          '域名(host)',
          (text) => rule.host = text,
          maxLines: 1,
        ),
        _buildEditText(
          rule.group,
          '分组(group)',
          (text) => rule.group = text,
          maxLines: 1,
        ),
        _buildEditText(
          rule.author,
          '作者(author)',
          (text) => rule.author = text,
          maxLines: 1,
        ),
        _buildEditText(
          rule.postScript,
          '签名档(post script, p.s.)',
          (text) => rule.postScript = text,
        ),
        _buildEditText(
          rule.userAgent,
          '用户代理字符串(userAgent)',
          (text) => rule.userAgent = text,
        ),
        _buildEditText(
          rule.loadJs,
          '加载js内容(loadJs)',
          (text) => rule.loadJs = text,
        ),
        _buildEditText(
          rule.loginUrl,
          '登录地址(loginUrl)',
          (text) => rule.loginUrl = text,
        ),
        _buildEditText(
          rule.cookies,
          '小饼干(cookies)',
          (text) => rule.cookies = text,
        ),
      ],
    );
  }

  Widget _buildDiscover(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle("发现规则"),
      initiallyExpanded: _discoverExpanded,
      onExpansionChanged: (value) => _discoverExpanded = value,
      children: [
        SwitchListTile(
          title: Text('启用'),
          value: rule.enableDiscover,
          onChanged: (value) {
            setState(() {
              rule.enableDiscover = value;
            });
          },
        ),
        _buildEditText(
          rule.discoverUrl,
          '地址(discoverUrl)',
          (text) => rule.discoverUrl = text,
        ),
        _buildEditText(
          rule.discoverList,
          '列表(discoverList)',
          (text) => rule.discoverList = text,
        ),
        _buildEditText(
          rule.discoverName,
          '名称(discoverName)',
          (text) => rule.discoverName = text,
        ),
        _buildEditText(
          rule.discoverAuthor,
          '作者(discoverAuthor)',
          (text) => rule.discoverAuthor = text,
        ),
        _buildEditText(
          rule.discoverCover,
          '封面(discoverCover)',
          (text) => rule.discoverCover = text,
        ),
        _buildEditText(
          rule.discoverChapter,
          '最新章节(discoverChapter)',
          (text) => rule.discoverChapter = text,
        ),
        _buildEditText(
          rule.discoverDescription,
          '简介(discoverDescription)',
          (text) => rule.discoverDescription = text,
        ),
        _buildEditText(
          rule.discoverTags,
          '标签(discoverTags)',
          (text) => rule.discoverTags = text,
        ),
        _buildEditText(
          rule.discoverResult,
          '结果(discoverResult)',
          (text) => rule.discoverResult = text,
        ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle("搜索规则"),
      initiallyExpanded: _searchExpanded,
      onExpansionChanged: (value) => _searchExpanded = value,
      children: [
        SwitchListTile(
          title: Text('启用'),
          value: rule.enableSearch,
          onChanged: (value) {
            setState(() {
              rule.enableSearch = value;
            });
          },
        ),
        _buildEditText(
          rule.searchUrl,
          '地址(searchUrl)',
          (text) => rule.searchUrl = text,
        ),
        _buildEditText(
          rule.searchList,
          '列表(searchList)',
          (text) => rule.searchList = text,
        ),
        _buildEditText(
          rule.searchName,
          '名称(searchName)',
          (text) => rule.searchName = text,
        ),
        _buildEditText(
          rule.searchAuthor,
          '作者(searchAuthor)',
          (text) => rule.searchAuthor = text,
        ),
        _buildEditText(
          rule.searchCover,
          '封面(searchCover)',
          (text) => rule.searchCover = text,
        ),
        _buildEditText(
          rule.searchChapter,
          '最新章节(searchChapter)',
          (text) => rule.searchChapter = text,
        ),
        _buildEditText(
          rule.searchDescription,
          '简介(searchDescription)',
          (text) => rule.searchDescription = text,
        ),
        _buildEditText(
          rule.searchTags,
          '标签(searchTags)',
          (text) => rule.searchTags = text,
        ),
        _buildEditText(
          rule.searchResult,
          '结果(searchResult)',
          (text) => rule.searchResult = text,
        ),
      ],
    );
  }

  Widget _buildChapter(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle("章节规则"),
      initiallyExpanded: _chapterExpanded,
      onExpansionChanged: (value) => _chapterExpanded = value,
      children: [
        SwitchListTile(
          title: Text('启用多线路'),
          value: rule.enableMultiRoads,
          onChanged: (value) {
            setState(() {
              rule.enableMultiRoads = value;
            });
          },
        ),
        _buildEditText(
          rule.chapterUrl,
          '地址(chapterUrl)',
          (text) => rule.chapterUrl = text,
        ),
        _buildEditText(
          rule.chapterRoads,
          '线路(chapterRoads)',
          (text) => rule.chapterRoads = text,
        ),
        _buildEditText(
          rule.chapterRoadName,
          '线路名称(chapterRoadName)',
          (text) => rule.chapterRoadName = text,
        ),
        _buildEditText(
          rule.chapterList,
          '章节列表(chapterList)',
          (text) => rule.chapterList = text,
        ),
        _buildEditText(
          rule.chapterName,
          '章节名称(chapterName)',
          (text) => rule.chapterName = text,
        ),
        _buildEditText(
          rule.chapterTime,
          '更新时间(chapterTime)',
          (text) => rule.chapterTime = text,
        ),
        _buildEditText(
          rule.chapterCover,
          '章节封面(chapterCover)',
          (text) => rule.chapterCover = text,
        ),
        _buildEditText(
          rule.chapterLock,
          '章节状态(chapterLock)',
          (text) => rule.chapterLock = text,
        ),
        _buildEditText(
          rule.chapterResult,
          '结果(chapterResult)',
          (text) => rule.chapterResult = text,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle("正文规则"),
      initiallyExpanded: _contentExpanded,
      onExpansionChanged: (value) => _contentExpanded = value,
      children: [
        SwitchListTile(
          title: Text('启用CryptoJS'),
          value: rule.useCryptoJS,
          onChanged: (value) {
            setState(() {
              rule.useCryptoJS = value;
            });
          },
        ),
        _buildEditText(
          rule.contentUrl,
          '地址(contentUrl)',
          (text) => rule.contentUrl = text,
        ),
        _buildEditText(
          rule.contentItems,
          '内容(contentItems)',
          (text) => rule.contentItems = text,
        ),
      ],
    );
  }

  Future<bool> _saveRule(BuildContext context) async {
    Utils.toast("开始保存");
    if (isLoading) return false;
    isLoading = true;
    final count = await Global.ruleDao.insertOrUpdateRule(rule);
    isLoading = false;
    if (count > 0) {
      Utils.toast("保存成功");
      return true;
    } else {
      Utils.toast("保存失败");
      return false;
    }
  }

  Future<bool> _loadFromClipBoard(BuildContext context, bool isYICIYUAN) async {
    if (isLoading) return false;
    isLoading = true;
    final text = (await Clipboard.getData(Clipboard.kTextPlain)).text;
    isLoading = false;
    try {
      setState(() {
        rule = isYICIYUAN
            ? Rule.fromYiCiYuan(jsonDecode(text), rule)
            : text.startsWith(RuleCompress.tag)
                ? RuleCompress.decompass(text, rule)
                : Rule.fromJson(jsonDecode(text), rule);
      });
      Utils.toast("已从剪贴板导入");
      return true;
    } catch (e) {
      Utils.toast("导入失败：" + e.toString(), duration: Duration(seconds: 2));
      return false;
    }
  }

  PopupMenuButton _buildpopupMenu(BuildContext context) {
    const SAVE = 0;
    const FROM_CLIPBOARD = 1;
    const TO_CLIPBOARD = 2;
    const DEBUG_WITHOUT_SAVE = 3;
    const FROM_YICIYUAN = 4;
    const TO_SHARE = 5;
    const SOURCE_HELP = 6;
    const LOGIN = 7;
    const SHARE = 8;
    const HELP = 9;
    final primaryColor = Theme.of(context).primaryColor;
    return PopupMenuButton<int>(
      icon: Icon(FIcons.more_vertical),
      offset: Offset(0, 40),
      onSelected: (int value) {
        switch (value) {
          case SAVE:
            _saveRule(context);
            break;
          case FROM_CLIPBOARD:
            _loadFromClipBoard(context, false);
            break;
          case FROM_YICIYUAN:
            _loadFromClipBoard(context, true);
            break;
          case TO_CLIPBOARD:
            Clipboard.setData(ClipboardData(text: jsonEncode(rule.toJson())));
            Utils.toast("已保存到剪贴板");
            break;
          case DEBUG_WITHOUT_SAVE:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => DebugRulePage(rule: rule)));
            break;
          case TO_SHARE:
            FlutterShare.share(
              title: '亦搜 eso',
              text: jsonEncode(rule.toJson()),
              //linkUrl: '${searchItem.url}',
              chooserTitle: '选择分享的应用',
            );
            break;
          case SOURCE_HELP:
            launch('https://github.com/mabDc/eso_source/blob/master/README.md');
            break;
          case LOGIN:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => LoginRulePage(rule: rule)))
                .whenComplete(() => setState(() {}));
            break;
          case SHARE:
            FlutterShare.share(
              title: '亦搜 eso',
              text: jsonEncode(rule.toJson()),
              //linkUrl: '${searchItem.url}',
              chooserTitle: '选择分享的应用',
            );
            break;
          case HELP:
            launch('https://github.com/mabDc/eso_source/blob/master/README.md');
            break;
          default:
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('登录'),
              Icon(
                FIcons.user,
                color: primaryColor,
              ),
            ],
          ),
          value: LOGIN,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('从剪贴板导入'),
              Icon(
                FIcons.clipboard,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_CLIPBOARD,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('阅读或异次元'),
              Icon(
                FIcons.book_open,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_YICIYUAN,
        ),
        // PopupMenuItem(
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: <Widget>[
        //       Text('分享规则至'),
        //       Icon(
        //         Icons.share,
        //         color: primaryColor,
        //       ),
        //     ],
        //   ),
        //   value: TO_CLIPBOARD,
        // ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('导出到剪贴板'),
              Icon(
                FIcons.copy,
                color: primaryColor,
              ),
            ],
          ),
          value: TO_CLIPBOARD,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('分享原始文本'),
              Icon(
                FIcons.share_2,
                color: primaryColor,
              ),
            ],
          ),
          value: SHARE,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('调试但不保存'),
              Icon(
                Icons.bug_report,
                color: primaryColor,
              ),
            ],
          ),
          value: DEBUG_WITHOUT_SAVE,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('帮助'),
              Icon(
                FIcons.help_circle,
                color: primaryColor,
              ),
            ],
          ),
          value: HELP,
        ),
        // PopupMenuItem(
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: <Widget>[
        //       Text('保存规则'),
        //       Icon(
        //         FIcons.save,
        //         color: primaryColor,
        //       ),
        //     ],
        //   ),
        //   value: SAVE,
        // ),
        // PopupMenuItem(
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: <Widget>[
        //       Text('规则说明'),
        //       Icon(
        //         FIcons.help_circle,
        //         color: primaryColor,
        //       ),
        //     ],
        //   ),
        //   value: SOURCE_HELP,
        // ),
      ],
    );
  }
}
