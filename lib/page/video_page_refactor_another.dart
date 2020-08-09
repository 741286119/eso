// import 'dart:io';
// import 'dart:ui';

// import 'package:dlna/dlna.dart';
// import 'package:eso/model/profile.dart';
// import 'package:eso/ui/ui_chapter_select.dart';
// import 'package:eso/ui/widgets/eso_video_progress_indicator.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:outline_material_icons/outline_material_icons.dart';
// import 'package:provider/provider.dart';
// import 'package:screen/screen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:video_player/video_player.dart';

// import '../api/api_manager.dart';
// import '../database/search_item.dart';
// import '../database/search_item_manager.dart';
// import '../model/audio_service.dart';
// import '../utils.dart';
// import '../utils/dlna_util.dart';

// class VideoPage extends StatelessWidget {
//   final SearchItem searchItem;
//   const VideoPage({this.searchItem, Key key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light,
//       child: Scaffold(
//         backgroundColor: Colors.black87,
//         body: ChangeNotifierProvider<VideoPageProvider>(
//           create: (context) => VideoPageProvider(searchItem: searchItem),
//           builder: (BuildContext context, child) {
//             final provider = context.select((VideoPageProvider provider) => provider);
//             final isLoading = context.select((VideoPageProvider provider) => provider.isLoading);
//             final showController = context.select((VideoPageProvider provider) => provider.showController);
//             final hint = context.select((VideoPageProvider provider) => provider.hint);
//             final showChapter = context.select((VideoPageProvider provider) => provider.showChapter);
//             return Stack(
//               children: [
//                 if (!isLoading) _buildPlayer(context),
//                 if (isLoading)
//                   Align(
//                     alignment: Alignment.topCenter,
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 120),
//                       child: _buildLoading(context),
//                     ),
//                   ),
//                 if (isLoading)
//                   Positioned(
//                     left: 30,
//                     bottom: 100,
//                     right: 30,
//                     child: _buildLoadingText(context),
//                   ),
//                 if (showController)
//                   _buildTopBar(context),
//                 if (showController)
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: Container(
//                       padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
//                       color: Color(0x20000000),
//                       child: _buildBottomBar(context),
//                     ),
//                   ),
//                 if (showChapter)
//                    UIChapterSelect(
//                      loadChapter: (index) => provider.loadChapter(index),
//                      searchItem: searchItem,
//                      color: Colors.black45,
//                      fontColor: Colors.white70,
//                      border: BorderSide(color: Colors.white12, width: Global.borderSize),
//                      heightScale: 0.6,
//                    ),
//                 if (hint != null)
//                   Align(
//                     alignment: Alignment.center,
//                     child: Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Color(0x20000000),
//                         borderRadius: BorderRadius.all(Radius.circular(8)),
//                       ),
//                       child: hint,
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildPlayer(BuildContext context) {
//     final controller =
//         context.select((VideoPageProvider provider) => provider.controller);
//     final provider = Provider.of<VideoPageProvider>(context, listen: false);
//     return GestureDetector(
//       child: Container(
//         // 增加color才能使全屏手势生效
//         color: Colors.transparent,
//         width: double.infinity,
//         height: double.infinity,
//         alignment: Alignment.center,
//         child: AspectRatio(
//           aspectRatio: controller.value.aspectRatio,
//           child: VideoPlayer(controller),
//         ),
//       ),
//       onDoubleTap: provider.playOrPause,
//       onTap: provider.toggleControllerBar,
//       onHorizontalDragStart: provider.onHorizontalDragStart,
//       onHorizontalDragUpdate: provider.onHorizontalDragUpdate,
//       onHorizontalDragEnd: provider.onHorizontalDragEnd,
//       onVerticalDragStart: provider.onVerticalDragStart,
//       onVerticalDragUpdate: provider.onVerticalDragUpdate,
//     );
//   }

//   Widget _buildLoading(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           height: 20,
//           width: 20,
//           margin: EdgeInsets.only(bottom: 10),
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(const Color(0xA0FFFFFF)),
//             strokeWidth: 2,
//           ),
//         ),
//         Text(
//           context.select((VideoPageProvider provider) => provider.titleText),
//           style: const TextStyle(
//             color: const Color(0xD0FFFFFF),
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             height: 2,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoadingText(BuildContext context) {
//     context.select((VideoPageProvider provider) => provider.loadingText.length);
//     const style = TextStyle(
//       color: Color(0xB0FFFFFF),
//       fontSize: 12,
//     );
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: context
//           .select((VideoPageProvider provider) => provider.loadingText)
//           .map((s) => Text(
//                 s,
//                 style: style,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ))
//           .toList(),
//     );
//   }

//   Widget _buildTopBar(BuildContext context) {
//     final provider = context.select((VideoPageProvider provider) => provider);
//     final _theme = Theme.of(context).appBarTheme;
//     return SizedBox(
//       height: 60,
//       child: AppBarEx(
//         backgroundColor: Colors.transparent,
//         titleSpacing: 0,
//         brightness: Brightness.dark,
//         iconTheme: _theme.iconTheme.copyWith(color: Colors.white),
//         actionsIconTheme: _theme.actionsIconTheme.copyWith(color: Colors.white),
//         title: Text(
//           provider.titleText,
//           style: TextStyle(color: Colors.white, fontFamily: Profile.fontFamily),
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//         actions: provider.screenAxis == Axis.horizontal ? [] : [
//           AppBarButton(
//             icon: Icon(Icons.open_in_new),
//             onPressed: provider.openInNew,
//             tooltip: "使用其他播放器打开",
//           ),
//           Utils.isDesktop ? AppBarButton(
//             icon: Icon(Icons.zoom_out_map),
//             onPressed: provider.zoom,
//             tooltip: "缩放",
//           ) :  AppBarButton(
//             icon: Icon(Icons.format_list_bulleted),
//             onPressed: ()=> provider.toggleChapterList(),
//             tooltip: "节目列表",
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomBar(BuildContext context) {
//     return Consumer<VideoPageProvider>(
//       builder: (context, provider, child) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               ESOVideoProgressIndicator(
//                   provider.controller,
//                   allowScrubbing: true,
//                   padding: const EdgeInsets.fromLTRB(20, 2, 20, 4)
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 26),
//                 child: Text(
//                   provider.isLoading
//                       ? '' // "--:-- / --:--"
//                       : "${provider.position} / ${provider.duration}",
//                   style: TextStyle(fontSize: 10, color: Colors.white),
//                   textAlign: TextAlign.end,
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   if (provider.screenAxis == Axis.horizontal)
//                     IconButton(
//                       color: Colors.white,
//                       iconSize: 20,
//                       padding: EdgeInsets.zero,
//                       icon: Icon(Icons.open_in_new),
//                       onPressed: provider.openInNew,
//                       tooltip: "使用其他播放器打开",
//                     ),
//                   IconButton(
//                     color: Colors.white,
//                     iconSize: 20,
//                     padding: EdgeInsets.zero,
//                     icon: Icon(Icons.airplay),
//                     onPressed: () => provider.openDLNA(context),
//                     tooltip: "DLNA投屏",
//                   ),
//                   IconButton(
//                     color: Colors.white,
//                     iconSize: 25,
//                     padding: EdgeInsets.zero,
//                     icon: Icon(Icons.skip_previous),
//                     onPressed: () =>
//                         provider.parseContent(searchItem.durChapterIndex - 1),
//                     tooltip: "上一集",
//                   ),
//                   IconButton(
//                     color: Colors.white,
//                     iconSize: 40,
//                     padding: EdgeInsets.zero,
//                     icon: Icon(
//                       !provider.isLoading && provider.isPlaying
//                           ? Icons.pause
//                           : Icons.play_arrow,
//                     ),
//                     onPressed: provider.playOrPause,
//                     tooltip: !provider.isLoading && provider.isPlaying ? "暂停" : "播放",
//                   ),
//                   IconButton(
//                     color: Colors.white,
//                     iconSize: 25,
//                     padding: EdgeInsets.zero,
//                     icon: Icon(Icons.skip_next),
//                     onPressed: () =>
//                         provider.parseContent(searchItem.durChapterIndex + 1),
//                     tooltip: "下一集",
//                   ),
//                   IconButton(
//                     color: Colors.white,
//                     iconSize: 20,
//                     padding: EdgeInsets.zero,
//                     icon: Icon(Icons.screen_rotation),
//                     onPressed: provider.screenRotation,
//                     tooltip: "旋转",
//                   ),
//                   if (provider.screenAxis == Axis.horizontal)
//                     Utils.isDesktop ? IconButton(
//                       color: Colors.white,
//                       iconSize: 20,
//                       padding: EdgeInsets.zero,
//                       icon: Icon(Icons.zoom_out_map),
//                       onPressed: provider.zoom,
//                       tooltip: "缩放",
//                     ) : IconButton(
//                       color: Colors.white,
//                       iconSize: 20,
//                       padding: EdgeInsets.zero,
//                       icon: Icon(Icons.format_list_bulleted),
//                       onPressed: ()=> provider.toggleChapterList(),
//                       tooltip: "节目列表",
//                     ),
//                 ],
//               )
//             ],
//           ),
//         );
//       },
//     );
//   }

// }

// class VideoPageProvider with ChangeNotifier {
//   final SearchItem searchItem;
//   String _titleText;
//   String get titleText => _titleText;
//   List<String> _content;
//   List<String> get content => _content;

//   final loadingText = <String>[];
//   bool _disposed;

//   VideoPlayerController _controller;
//   VideoPlayerController get controller => _controller;
//   bool get isPlaying => _controller.value.isPlaying;
//   String get position => Utils.formatDuration(_controller.value.position);
//   String get duration => Utils.formatDuration(_controller.value.duration);

//   VideoPageProvider({@required this.searchItem}) {
//     if (searchItem.chapters?.length == 0 &&
//         SearchItemManager.isFavorite(searchItem.originTag, searchItem.url)) {
//       searchItem.chapters = SearchItemManager.getChapter(searchItem.id);
//     }
//     _titleText = "${searchItem.name} - ${searchItem.durChapter}";
//     _screenAxis = Axis.horizontal;
//     _disposed = false;
//     setHorizontal();
//     parseContent(null);
//   }

//   bool _isLoading;
//   bool get isLoading => _isLoading != false;
//   void parseContent(int chapterIndex) async {
//     if (chapterIndex != null &&
//         (_isLoading == true ||
//             chapterIndex < 0 ||
//             chapterIndex >= searchItem.chaptersCount ||
//             chapterIndex == searchItem.durChapterIndex)) {
//       return;
//     }
//     _isLoading = true;
//     _hint = null;
//     _controller?.removeListener(_listener);
//     loadingText.clear();
//     if (chapterIndex != null) {
//       searchItem.durChapterIndex = chapterIndex;
//       searchItem.durChapter = searchItem.chapters[chapterIndex].name;
//       searchItem.durContentIndex = 1;
//       _titleText = "${searchItem.name} - ${searchItem.durChapter}";
//     }
//     loadingText.add("开始解析...");
//     await controller?.pause();
//     notifyListeners();
//     searchItem.lastReadTime = DateTime.now().microsecondsSinceEpoch;
//     SearchItemManager.saveSearchItem();
//     if (_disposed) return;
//     try {
//       _content = await APIManager.getContent(searchItem.originTag,
//           searchItem.chapters[chapterIndex ?? searchItem.durChapterIndex].url);
//       if (_content.isEmpty) {
//         _content = null;
//         _isLoading = null;
//         loadingText.add("错误 内容为空！");
//         _controller?.dispose();
//         notifyListeners();
//         return;
//       }
//       if (_disposed) return;
//       loadingText.add("播放地址 ${_content[0].split("").join("\u200B")}");
//       loadingText.add("获取视频信息...");
//       notifyListeners();
//       _controller?.dispose();
//       if (_disposed) return;
//       _controller = VideoPlayerController.network(_content[0]);
//       notifyListeners();
//       AudioService.stop();
//       await _controller.initialize();
//       _controller.seekTo(Duration(milliseconds: searchItem.durContentIndex));
//       _controller.play();
//       Screen.keepOn(true);
//       _controller.addListener(_listener);
//       _controllerTime = DateTime.now();
//       _isLoading = false;
//       if (_disposed) _controller.dispose();
//     } catch (e, st) {
//       loadingText.add("错误 $e");
//       loadingText.addAll("$st".split("\n").take(5));
//       _isLoading = null;
//       notifyListeners();
//       _controller?.dispose();
//     }
//   }

//   DateTime _lastNotifyTime;
//   _listener() {
//     if (_lastNotifyTime == null ||
//         DateTime.now().difference(_lastNotifyTime).inMicroseconds > 1000) {
//       _lastNotifyTime = DateTime.now();
//       if (showController &&
//           DateTime.now().difference(_controllerTime).compareTo(_controllerDelay) >= 0) {
//         hideController();
//         _showChapter = false;
//       }
//       searchItem.durContentIndex = _controller.value.position.inMilliseconds;
//       searchItem.lastReadTime = DateTime.now().microsecondsSinceEpoch;
//       SearchItemManager.saveSearchItem();
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     if (Platform.isIOS) {
//       setVertical();
//     }
//     _disposed = true;
//     if (controller != null) {
//       searchItem.durContentIndex = _controller.value.position.inMilliseconds;
//       controller.removeListener(_listener);
//       controller.pause();
//       controller.dispose();
//     }
//     searchItem.lastReadTime = DateTime.now().microsecondsSinceEpoch;
//     SearchItemManager.saveSearchItem();
//     if (!Utils.isDesktop) {
//       Screen.keepOn(false);
//       if(Platform.isIOS)
//         Screen.setBrightness(Global.systemBrightness);
//       else
//         Screen.setBrightness(-1);
//     }
//     loadingText.clear();
//     resetRotation();
//     SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
//     super.dispose();
//   }

//   void resetRotation() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeRight,
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//   }

//   void setHorizontal() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeRight,
//       DeviceOrientation.landscapeLeft,
//     ]);
//   }

//   void setVertical() {
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//   }

//   void openDLNA(BuildContext context) {
//     if (_disposed || _content == null) return;
//     _controllerTime = DateTime.now();
//     DLNAUtil.instance.start(
//       context,
//       title: _titleText,
//       url: _content[0],
//       videoType: VideoObject.VIDEO_MP4,
//       onPlay: playOrPause,
//     );
//   }

//   void openInNew() {
//     if (_disposed || _content == null) return;
//     _controllerTime = DateTime.now();
//     launch(_content[0]);
//   }

//   Widget _hint;
//   Widget get hint => _hint;
//   DateTime _hintTime;
//   void autoHideHint() {
//     _hintTime = DateTime.now();
//     const _hintDelay = Duration(seconds: 2);
//     Future.delayed(_hintDelay, () {
//       if (DateTime.now().difference(_hintTime).compareTo(_hintDelay) >= 0) {
//         _hint = null;
//         notifyListeners();
//       }
//     });
//   }

//   void setHintText(String text) {
//     _hint = Text(
//       text,
//       textAlign: TextAlign.center,
//       style: const TextStyle(
//         color: Colors.white,
//         fontSize: 22,
//         height: 1.5,
//       ),
//     );
//     notifyListeners();
//     autoHideHint();
//   }

//   void _pause() async {
//     await Screen.keepOn(false);
//     await controller.pause();
//     setHintText("已暂停");
//   }

//   void _play() async {
//     setHintText("播放");
//     await Screen.keepOn(true);
//     await controller.play();
//   }

//   void playOrPause() {
//     if (_isLoading == null) {
//       parseContent(null);
//     }
//     if (_disposed || isLoading) return;
//     _controllerTime = DateTime.now();
//     if (isPlaying) {
//       _pause();
//     } else {
//       _play();
//     }
//   }

//   bool _showController;
//   bool get showController => _showController != false;
//   bool _showChapter;
//   bool get showChapter => _showChapter ?? false;
//   DateTime _controllerTime;
//   final _controllerDelay = Duration(seconds: 4);

//   void toggleControllerBar() {
//     if (showChapter == true) {
//       hideController();
//       toggleChapterList();
//       return;
//     }
//     if (showController) {
//       hideController();
//     } else {
//       displayController();
//     }
//     notifyListeners();
//   }

//   void toggleChapterList() {
//     if (showChapter) {
//       _showChapter = false;
//     } else {
//       hideController();
//       _showChapter = true;
//     }
//     notifyListeners();
//   }

//   void displayController() {
//     _showController = true;
//     SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
//     _controllerTime = DateTime.now();
//   }

//   void hideController() {
//     _showController = false;
//     SystemChrome.setEnabledSystemUIOverlays([]);
//   }

//   void zoom() {
//     // if (_disposed || isLoading) return;
//     _controllerTime = DateTime.now();
//     setHintText("暂无功能");
//   }

//   void loadChapter(int index) {
//     parseContent(index);
//   }

//   Axis _screenAxis;
//   Axis get screenAxis => _screenAxis;
//   void screenRotation() {
//     _controllerTime = DateTime.now();
//     if (_screenAxis == Axis.horizontal) {
//       setHintText("纵向");
//       _screenAxis = Axis.vertical;
//       setVertical();
//     } else {
//       setHintText("横向");
//       _screenAxis = Axis.horizontal;
//       setHorizontal();
//     }
//   }

//   /// 手势处理
//   double _dragStartPosition;
//   Duration _gesturePosition;
//   bool _draging;

//   void setHintTextWithIcon(num value, IconData icon) {
//     _hint = Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: Colors.white.withOpacity(0.7),
//               size: 18,
//             ),
//             SizedBox(width: 10),
//             Container(
//               width: 100,
//               child: LinearProgressIndicator(
//                 value: value,
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0x8FFF2020)),
//                 backgroundColor: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//         Text(
//           (value * 100).toStringAsFixed(0),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             height: 1.5,
//           ),
//         )
//       ],
//     );
//     notifyListeners();
//     autoHideHint();
//   }

//   void onHorizontalDragStart(DragStartDetails details) =>
//       _dragStartPosition = details.globalPosition.dx;

//   void onHorizontalDragEnd(DragEndDetails details) {
//     _controller.seekTo(_gesturePosition);
//   }

//   void onHorizontalDragUpdate(DragUpdateDetails details) {
//     final d = Duration(seconds: (details.globalPosition.dx - _dragStartPosition) ~/ 10);
//     _gesturePosition = _controller.value.position + d;
//     final prefix = d.compareTo(Duration.zero) < 0 ? "-" : "+";
//     setHintText(
//         "${Utils.formatDuration(_gesturePosition)} / $duration\n[ $prefix ${Utils.formatDuration(d)} ]");
//   }

//   void onVerticalDragStart(DragStartDetails details) =>
//       _dragStartPosition = details.globalPosition.dy;

//   void onVerticalDragUpdate(DragUpdateDetails details) async {
//     if (_draging == true) return;
//     _draging = true;
//     double number = (_dragStartPosition - details.globalPosition.dy) / 200;
//     if (details.globalPosition.dx < (_screenAxis == Axis.horizontal ? 400 : 200)) {
//       IconData icon = OMIcons.brightnessLow;
//       var brightness = await Screen.brightness;
//       if (brightness > 1) {
//         brightness = 0.5;
//       }
//       brightness += number;
//       if (brightness < 0) {
//         brightness = 0.01;
//       } else if (brightness > 1) {
//         brightness = 1.0;
//       }
//       if (brightness <= 0.25) {
//         icon = Icons.brightness_low;
//       } else if (brightness < 0.5) {
//         icon = Icons.brightness_medium;
//       } else {
//         icon = Icons.brightness_high;
//       }
//       setHintTextWithIcon(brightness, icon);
//       await Screen.setBrightness(brightness);
//     } else {
//       IconData icon = OMIcons.volumeMute;
//       var vol = _controller.value.volume + number;
//       if (vol <= 0) {
//         icon = OMIcons.volumeOff;
//         vol = 0.0;
//       } else if (vol < 0.2) {
//         icon = OMIcons.volumeMute;
//       } else if (vol < 0.7) {
//         icon = OMIcons.volumeDown;
//       } else {
//         icon = OMIcons.volumeUp;
//       }
//       if (vol > 1) {
//         vol = 1;
//       }
//       setHintTextWithIcon(vol, icon);
//       await _controller.setVolume(vol);
//     }

//     /// 手势调节正常运作核心代码就是这句了
//     _dragStartPosition = details.globalPosition.dy;
//     _draging = false;
//   }
// }
