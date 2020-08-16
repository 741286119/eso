import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eso/utils/cache_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils.dart';

/// 图像预览页中的图像列表项
class PhotoItem {
  /// 文件URL或文件Path
  final String url;

  final Map<String, String> headers;

  const PhotoItem(this.url, {this.headers});
}

/// 图像预览页面
class PhotoViewPage extends StatefulWidget {
  /// 图像列表
  final List<PhotoItem> items;

  /// 默认选中第几个图像
  final int index;

  /// 是否支持旋转
  final bool enableRotation;

  /// hero
  final String heroTag;

  /// 长按事件
  final ValueChanged<int> onLongPress;

  const PhotoViewPage(
      {Key key, @required this.items, this.index = 0, this.enableRotation = false, this.heroTag, this.onLongPress})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PhotoViewPageState();
}

class _PhotoViewPageState extends State<PhotoViewPage> {
  PageController controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index >= 0 && widget.index < widget.items.length ? widget.index : 0;
    controller = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GestureDetector(
            child: Container(
                color: Colors.black,
                child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    var item = widget.items[index];
                    return PhotoViewGalleryPageOptions(
                      //imageProvider: NetworkImage(item.url),
                      imageProvider: CachedNetworkImageProvider(item.url, headers: item.headers),
                      heroAttributes: widget.heroTag != null && widget.index == index ? PhotoViewHeroAttributes(tag: widget.heroTag) : null,
                    );
                  },
                  itemCount: count,
                  loadingBuilder: (context, event) {
                    return Center(
                      child: SizedBox(width: 50, height: 50,
                          child: CircularProgressIndicator(strokeWidth: 1.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.white30))
                      ),
                    );
                  },
                  backgroundDecoration: null,
                  pageController: controller,
                  enableRotation: widget.enableRotation,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                )),
            // onTap: () {
            //   Navigator.of(context).pop();
            // },
            onLongPress: doLongPress,
            //onSecondaryLongPress: doLongPress,
          ),
          SafeArea(
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50.0))),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                ),
                Expanded(
                  child: Text("${currentIndex + 1} / $count",
                      style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                ),
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white54),
                    onPressed: doLongPress,
                    tooltip: "菜单",
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50.0))),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                ),
              ],
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: count >= 9 ? MediaQuery.of(context).size.width - 80 : count >= 6 ? 200 : count < 3 ? 50 : 100,
                height: count == 1 ? 0 : 50,
                child: count < 2 ? null : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    count,
                    (i) => GestureDetector(
                      child: CircleAvatar(
                        radius: 3.5,
                        backgroundColor: currentIndex == i
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withAlpha(100),
                      ),
                    ),
                  ).toList(),
                ),
              ))
        ],
      ),
    );
  }

  int get count => widget.items == null ? 0 : widget.items.length;

  void doLongPress() {
    // iOS 风格底部弹出框
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Container(
            child: Stack(
              children: <Widget>[
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.98,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        buildPopButton(context, Text("保存图像", style: TextStyle(color: Colors.black87, fontSize: 16)), isLast: false, onTap: () {
                          Navigator.of(context).pop();
                          saveImage(CachedNetworkImageProvider(widget.items[currentIndex].url));
                        }),
                        buildPopButton(context, Text("复制图像地址", style: TextStyle(color: Colors.black87, fontSize: 16)), isLast: false, isFirst: false, onTap: () async {
                          await Clipboard.setData(ClipboardData(text: widget.items[currentIndex].url));
                          Utils.toast("已复制图片地址");
                          Navigator.of(context).pop();
                        }),
                        buildPopButton(context, Text("在浏览器中打开", style: TextStyle(color: Colors.black87, fontSize: 16)), isFirst: false, onTap: () async {
                          launch(widget.items[currentIndex].url);
                          Navigator.of(context).pop();
                        }),
                        buildPopButton(context, Text("取消", style: TextStyle(color: Theme.of(context).errorColor)), onTap: () {
                          Navigator.of(context).pop();
                        })
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  /// 保存图像
  saveImage(CachedNetworkImageProvider provider) async {
    // 检查并请求权限
    if (await CacheUtil().requestPermission() != true) {
      Utils.toast("授权失败");
      return;
    }

    // 获取文件或图片
    DefaultCacheManager mgr = provider.cacheManager ?? DefaultCacheManager();
    String url = provider.url;
    Map<String, String> headers = provider.headers;
    File file = await mgr.getSingleFile(url, headers: headers);

    final result = Platform.isWindows || Platform.isLinux
        ? await CacheUtil(basePath: "download").putFile(Utils.getFileNameAndExt(file.path), file)
        : await ImageGallerySaver.saveImage(file.readAsBytesSync());
    if (result is bool && result == true) {
      Utils.toast("保存成功");
    } else if (result is String && null != result  && result.isNotEmpty) {
      String str = Uri.decodeComponent(result);
      Utils.toast("成功保存到\n$str");
    } else {
      Utils.toast("保存失败");
    }
  }

  /// 生成 iOS 风格底部弹出框需要的 button
  static Widget buildPopButton(BuildContext context, Widget text,
      {bool isFirst = true,
        bool isLast = true,
        double circular = 10,
        VoidCallback onTap}) {
    var borderSide = BorderSide(color: Colors.black12, width: 0.5);
    var borderRadius;
    var margin;

    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(circular);
      margin = EdgeInsets.only(bottom: 10, left: 10, right: 10);
    } else if (isFirst) {
      borderRadius = BorderRadius.vertical(
          top: Radius.circular(circular));
      margin = EdgeInsets.only(
        left: 10,
        right: 10,
      );
    } else if (isLast) {
      borderRadius = BorderRadius.vertical(
          bottom: Radius.circular(circular));
      margin = EdgeInsets.only(left: 10, right: 10, bottom: 10);
    } else {
      margin = EdgeInsets.only(left: 10, right: 10);
    }

    return Container(
      height: 45.0,
      width: double.infinity,
      margin: margin,
      child: FlatButton(
        child: text,
        onPressed: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.zero,
          side: borderSide
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
    );
  }
}
