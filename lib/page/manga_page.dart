import 'dart:math';

import 'package:eso/model/manga_page_provider.dart';
import 'package:eso/model/profile.dart';
import 'package:eso/ui/ui_chapter_select.dart';
import 'package:eso/ui/ui_fade_in_image.dart';
import 'package:eso/ui/ui_manga_menu.dart';
import 'package:eso/ui/ui_system_info.dart';
import 'package:eso/ui/zoom_view.dart';
import 'package:eso/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../database/search_item.dart';
import 'langding_page.dart';
import 'photo_view_page.dart';

/// 漫画显示页面
class MangaPage extends StatefulWidget {
  final SearchItem searchItem;

  const MangaPage({
    this.searchItem,
    Key key,
  }) : super(key: key);

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  Widget page;
  MangaPageProvider __provider;

  @override
  Widget build(BuildContext context) {
    if (page == null) {
      final provider = Provider.of<Profile>(context, listen: false);
      page = buildPage(
        provider.mangaKeepOn,
        provider.mangaLandscape,
        provider.mangaDirection,
      );
    }
    return page;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    __provider?.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Widget buildPage(bool keepOn, bool landscape, int direction) {
    return ChangeNotifierProvider<MangaPageProvider>.value(
      value: MangaPageProvider(
        searchItem: widget.searchItem,
        keepOn: keepOn,
        landscape: landscape,
        direction: direction,
      ),
      child: Scaffold(
        body: Consumer2<MangaPageProvider, Profile>(
          builder:
              (BuildContext context, MangaPageProvider provider, Profile profile, _) {
            if (__provider == null) {
              __provider = provider;
            }
            if (profile.mangaFullScreen) {
              SystemChrome.setEnabledSystemUIOverlays([]);
            } else {
              SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
            }
            if (provider.content == null) {
              return LandingPage();
            }
            updateSystemChrome(provider.showMenu);
            return GestureDetector(
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: <Widget>[
                  NotificationListener(
                    onNotification: (t) {
                      if (t is ScrollEndNotification) {
                        provider.refreshProgress();
                      }
                      return false;
                    },
                    child: buildSmartRefresh(provider, profile),
                  ),
                  profile.showMangaInfo
                      ? UISystemInfo(
                          mangaInfo: provider.searchItem.durChapter,
                          mangaCount: provider.content.length,
                        )
                      : Container(),
                  provider.showMenu
                      ? UIMangaMenu(
                          searchItem: widget.searchItem,
                        )
                      : Container(),
                  provider.showChapter
                      ? UIChapterSelect(
                          searchItem: widget.searchItem,
                          loadChapter: provider.loadChapter,
                        )
                      : Container(),
                  provider.isLoading
                      ? Opacity(
                          opacity: 0.8,
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Theme.of(context).canvasColor,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 42,
                                vertical: 20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoActivityIndicator(),
                                  SizedBox(height: 20),
                                  Text(
                                    "加载中...",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity.abs() > 100) {
                  if (provider.showSetting) {
                    provider.showSetting = false;
                  } else if (provider.showMenu) {
                    provider.showMenu = false;
                  }
                }
              },
              onVerticalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity.abs() > 100) {
                  if (provider.showSetting) {
                    provider.showSetting = false;
                  } else if (provider.showMenu) {
                    provider.showMenu = false;
                  }
                }
              },
              onTapUp: (TapUpDetails details) {
                final size = MediaQuery.of(context).size;
                if (details.globalPosition.dx > size.width * 3 / 8 &&
                    details.globalPosition.dx < size.width * 5 / 8 &&
                    details.globalPosition.dy > size.height * 3 / 8 &&
                    details.globalPosition.dy < size.height * 5 / 8) {
                  provider.showMenu = !provider.showMenu;
                  provider.showSetting = false;
                } else {
                  provider.showChapter = false;
                }
              },
            );
          },
        ),
      ),
    );
  }

  RefreshController _refreshController = RefreshController();

  Widget buildSmartRefresh(MangaPageProvider provider, Profile profile) {
    return ZoomView(
      child: RefreshConfiguration(
        enableBallisticLoad: false,
        child: SmartRefresher(
            header: CustomHeader(
              builder: (BuildContext context, RefreshStatus mode) {
                Widget body;
                if (mode == RefreshStatus.idle) {
                  body = Text("滑动加载上一章");
                } else if (mode == RefreshStatus.refreshing) {
                  body = CupertinoActivityIndicator();
                } else if (mode == RefreshStatus.failed) {
                  body = Text("加载失败!请重试!");
                } else if (mode == RefreshStatus.canRefresh) {
                  body = Text("释放加载上一章!");
                } else {
                  body = Text("加载完成或没有更多数据");
                }
                final angle = profile.mangaDirection == Profile.mangaDirectionLeftToRight
                    ? pi / 2 * 3
                    : profile.mangaDirection == Profile.mangaDirectionRightToLeft
                        ? pi / 2
                        : 0;
                if (angle > 0) {
                  return Container(
                    height: 60.0,
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        height: 260,
                        width: 260,
                        padding: EdgeInsets.only(top: 200),
                        alignment: Alignment.center,
                        child: body,
                      ),
                    ),
                  );
                }
                return Container(
                  height: 60.0,
                  child: Center(child: body),
                );
              },
            ),
            footer: CustomFooter(
              builder: (BuildContext context, LoadStatus mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = Text("滑动加载下一章");
                } else if (mode == LoadStatus.loading) {
                  body = CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = Text("加载失败!请重试!");
                } else if (mode == LoadStatus.canLoading) {
                  body = Text("松手加载下一章!");
                } else {
                  body = Text("加载完成或没有更多数据");
                }
                final angle = profile.mangaDirection == Profile.mangaDirectionLeftToRight
                    ? pi / 2 * 3
                    : profile.mangaDirection == Profile.mangaDirectionRightToLeft
                        ? pi / 2
                        : 0;
                if (angle > 0) {
                  return Container(
                    height: 60.0,
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: angle,
                      child: body,
                    ),
                  );
                }
                return Container(
                  height: 60.0,
                  alignment: Alignment.center,
                  child: body,
                );
              },
            ),
            controller: _refreshController,
            enablePullUp: true,
            child: _buildMangaContent(provider, profile),
            onRefresh: () async {
              await provider.loadChapterHideLoading(true);
              _refreshController.refreshCompleted();
            },
            onLoading: () async {
              await provider.loadChapterHideLoading(false);
              _refreshController.loadComplete();
            }),
      ),
    );
  }

  Widget _buildMangaContent(MangaPageProvider provider, Profile profile) {
    Axis direction;
    bool reverse;
    switch (profile.mangaDirection) {
      case Profile.mangaDirectionTopToBottom:
        direction = Axis.vertical;
        reverse = false;
        break;
      case Profile.mangaDirectionLeftToRight:
        direction = Axis.horizontal;
        reverse = false;
        break;
      case Profile.mangaDirectionRightToLeft:
        direction = Axis.horizontal;
        reverse = true;
        break;
      default:
        direction = Axis.vertical;
        reverse = false;
    }
    return ListView.builder(
      padding: EdgeInsets.all(0),
      physics: BouncingScrollPhysics(),
      scrollDirection: direction,
      reverse: reverse,
      controller: provider.controller,
      itemCount: provider.content.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.content.length) {
          return Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(
              top: 50,
              left: 32,
              right: 10,
              bottom: 30,
            ),
            child: Text(
              "当前章节已结束\n${provider.searchItem.durChapter}",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: Profile.staticFontFamily,
                height: 2,
                color: Theme.of(context).textTheme.bodyText1.color,
              ),
            ),
          );
        }
        final path = '${provider.content[index]}';
        return GestureDetector(
          onLongPress: () {
            Utils.startPageWait(
                context,
                PhotoViewPage(
                  items: provider.content
                      .map((e) => PhotoItem(e, headers: provider.headers))
                      .toList(),
                  index: index,
                ));
          },
          // child: FadeInImage(
          //   placeholder: AssetImage(Global.waitingPath),
          //   image: checkUrl(path, provider.headers),
          //   fit: BoxFit.fitWidth,
          // ),
          child:
              UIFadeInImage(url: path, header: provider.headers, placeHolderHeight: 200),
        );
      },
    );
  }

  bool lastShowMenu = false;

  updateSystemChrome(bool showMenu) {
    if (showMenu == lastShowMenu) return;
    if (showMenu) {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    } else {
      SystemChrome.setEnabledSystemUIOverlays([]);
    }
  }
}
