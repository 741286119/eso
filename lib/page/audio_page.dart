import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:eso/database/search_item.dart';
import 'package:eso/database/search_item_manager.dart';
import 'package:eso/evnts/audio_state_event.dart';
import 'package:eso/model/audio_page_controller.dart';
import 'package:eso/model/audio_service.dart';
import 'package:eso/model/profile.dart';
import 'package:eso/ui/ui_chapter_select.dart';
import 'package:eso/ui/widgets/animation_rotate_view.dart';
import 'package:eso/utils.dart';
import 'package:eso/utils/flutter_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../fonticons_icons.dart';
import '../global.dart';

class AudioPage extends StatefulWidget {
  final SearchItem searchItem;

  const AudioPage({
    this.searchItem,
    Key key,
  }) : super(key: key);

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  Widget _audioPage;
  AudioPageController __provider;
  SearchItem searchItem;
  StreamSubscription stream;

  @override
  void initState() {
    searchItem = widget.searchItem;
    super.initState();

    stream = eventBus.on<AudioStateEvent>().listen((event) {
      if (event.state == AudioPlayerState.PLAYING && searchItem != event.item) {
        searchItem = event.item;
        if (__provider != null) __provider.update();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_audioPage == null) {
      _audioPage = _buildPage();
    }
    return _audioPage;
  }

  @override
  void dispose() {
    __provider?.dispose();
    stream?.cancel();
    super.dispose();
  }

  Widget _buildPage() {
    return ChangeNotifierProvider<AudioPageController>.value(
      value: AudioPageController(searchItem: searchItem),
      child: Consumer<AudioPageController>(
        builder: (BuildContext context, AudioPageController provider, _) {
          __provider = provider;
          final chapter = searchItem.chapters[searchItem.durChapterIndex];
          return Scaffold(
            body: GestureDetector(
              child: Container(
                height: double.infinity,
                width: double.infinity,
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Image.network(
                        Utils.empty(chapter.cover) ? defaultImage : chapter.cover,
                        fit: BoxFit.cover,
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withAlpha(30)),
                    ),
                    SafeArea(
                      child: Column(
                        children: <Widget>[
                          _buildAppBar(provider, chapter.name, chapter.time),
                          Expanded(
                            child: Center(
                                child: SizedBox(
                              width: 300,
                              height: 300,
                              child: AnimationRotateView(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Utils.empty(chapter.cover)
                                        ? Colors.black26
                                        : null,
                                    image: Utils.empty(chapter.cover)
                                        ? null
                                        : DecorationImage(
                                            image: NetworkImage(chapter.cover ?? ''),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: Utils.empty(chapter.cover)
                                      ? Icon(Icons.audiotrack,
                                          color: Colors.white30, size: 200)
                                      : null,
                                ),
                              ),
                            )),
                          ),
                          SizedBox(height: 50),
                          _buildProgressBar(provider),
                          SizedBox(height: 10),
                          _buildBottomController(provider),
                          SizedBox(height: 25),
                        ],
                      ),
                    ),
                    SafeArea(
                        child: Center(
                      child: Container(
                        height: 300,
                        alignment: Alignment.bottomCenter,
                        child: DefaultTextStyle(
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontFamily: Profile.fontFamily,
                              height: 1.75),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(chapter.name, style: TextStyle(fontSize: 15)),
                              Text(Utils.link(searchItem.origin, searchItem.name,
                                      divider: ' | ')
                                  .link(searchItem.chapter)
                                  .value),
                            ],
                          ),
                        ),
                      ),
                    )),
                    provider.showChapter
                        ? UIChapterSelect(
                            searchItem: searchItem,
                            color: Colors.black38,
                            fontColor: Colors.white70,
                            border: BorderSide(
                                color: Colors.white10, width: Global.borderSize),
                            heightScale: 0.5,
                            loadChapter: provider.loadChapter)
                        : Container(),
                  ],
                ),
              ),
              onTap: () {
                if (provider.showChapter == true) provider.showChapter = false;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPageController provider, String name, String author) {
    final _iconTheme = Theme.of(context).primaryIconTheme;
    final _textTheme = Theme.of(context).primaryTextTheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      brightness: Brightness.dark,
      iconTheme: _iconTheme.copyWith(color: Colors.white70),
      textTheme: _textTheme.copyWith(
          headline6: _textTheme.headline6.copyWith(color: Colors.white70)),
      actionsIconTheme: _iconTheme.copyWith(color: Colors.white70),
      actions: [
        StatefulBuilder(
          builder: (context, _state) {
            bool isFav =
                SearchItemManager.isFavorite(searchItem.originTag, searchItem.url);
            return IconButton(
              icon: isFav ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
              iconSize: 21,
              tooltip: isFav ? "取消收藏" : "加入收藏",
              onPressed: () async {
                await SearchItemManager.toggleFavorite(searchItem);
                _state(() => null);
              },
            );
          },
        ),
        IconButton(
          icon: Icon(FIcons.share_2),
          tooltip: "分享",
          onPressed: provider.share,
        )
      ],
      titleSpacing: 0,
      title: author == null || author.isEmpty
          ? Text(
              '$name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '$author',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar(AudioPageController provider) {
    return Row(
      children: <Widget>[
        Container(
          alignment: Alignment.centerRight,
          child:
              Text(provider.positionDurationText, style: TextStyle(color: Colors.white)),
          width: 52,
        ),
        Expanded(
          child: FlutterSlider(
            values: [provider.postionSeconds.toDouble()],
            max: provider.seconds.toDouble(),
            min: 0,
            onDragging: (handlerIndex, lowerValue, upperValue) =>
                provider.seekSeconds((lowerValue as double).toInt()),
            handlerHeight: 12,
            handlerWidth: 12,
            handler: FlutterSliderHandler(
              child: Container(
                width: 12,
                height: 12,
                alignment: Alignment.center,
                child: Icon(Icons.audiotrack, color: Colors.red, size: 8),
              ),
            ),
            trackBar: FlutterSliderTrackBar(
              inactiveTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white54,
              ),
              activeTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white70,
              ),
            ),
            tooltip: FlutterSliderTooltip(
              disableAnimation: true,
              custom: (value) => Container(
                color: Colors.black12,
                padding: EdgeInsets.all(4),
                child: Text(
                  Utils.formatDuration(Duration(seconds: (value as double).toInt())),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              positionOffset:
                  FlutterSliderTooltipPositionOffset(left: -10, right: -10, top: -10),
            ),
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          child: Text(provider.durationText, style: TextStyle(color: Colors.white)),
          width: 52,
        ),
      ],
    );
  }

  // Widget _buildProgressBar(AudioPageController provider) {
  //   return Row(
  //     children: <Widget>[
  //       Container(
  //         alignment: Alignment.centerRight,
  //         child:
  //             Text(provider.positionDurationText, style: TextStyle(color: Colors.white)),
  //         width: 52,
  //       ),
  //       Expanded(
  //         child: StatefulBuilder(
  //           builder: (context, _state) {
  //             return SliderTheme(
  //               data: SliderThemeData(
  //                 trackHeight: 3,
  //                 thumbColor: Colors.white,
  //                 thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
  //                 activeTrackColor: Colors.white70,
  //                 inactiveTrackColor: Colors.white38,
  //                 disabledThumbColor: Colors.grey,
  //                 trackShape: RectangularSliderTrackShape()
  //               ),
  //               child: Slider(
  //                 value: provider.postionSeconds.toDouble(),
  //                 min: 0,
  //                 max: provider.seconds.toDouble(),
  //                 divisions: provider.seconds <= 0 ? null : provider.seconds,
  //                 onChanged: (v) {
  //                   provider.seekSeconds(v.toInt());
  //                   _state(() => null);
  //                 },
  //                 label: "${provider.positionDurationText}",
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       Container(
  //         alignment: Alignment.centerLeft,
  //         child: Text(provider.durationText, style: TextStyle(color: Colors.white)),
  //         width: 52,
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBottomController(AudioPageController provider) {
    final _repeatMode = provider.repeatMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(
            _repeatMode == AudioService.REPEAT_FAVORITE
                ? Icons.restore
                : _repeatMode == AudioService.REPEAT_ALL
                    ? Icons.repeat
                    : _repeatMode == AudioService.REPEAT_ONE
                        ? Icons.repeat_one
                        : Icons.label_outline,
            color: Colors.white,
          ),
          iconSize: 26,
          tooltip: AudioService.getRepeatName(_repeatMode),
          padding: EdgeInsets.zero,
          onPressed: provider.switchRepeatMode,
        ),
        InkWell(
          child: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 26,
          ),
          onTap: provider.playPrev,
        ),
        InkWell(
          child: Icon(
            provider.state == AudioPlayerState.PLAYING
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: Colors.white,
            size: 42,
          ),
          onTap: provider.playOrPause,
        ),
        InkWell(
          child: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 26,
          ),
          onTap: provider.playNext,
        ),
        IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          iconSize: 26,
          tooltip: "播放列表",
          onPressed: () => provider.showChapter = !provider.showChapter,
        ),
      ],
    );
  }

  final String defaultImage = _defaultBackgroundImage[
      Random().nextInt(_defaultBackgroundImage.length * 3) %
          _defaultBackgroundImage.length];

  static const List<String> _defaultBackgroundImage = <String>[
    'https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=1862395032,4159614935&fm=26&gp=0.jpg',
    'https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=320821615,459299112&fm=26&gp=0.jpg',
    'https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=3709840964,4011199584&fm=26&gp=0.jpg',
    'https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=159400530,2390750984&fm=26&gp=0.jpg',
    'https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2942281081,4061453531&fm=26&gp=0.jpg',
    'https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=3708202986,3174435156&fm=11&gp=0.jpg',
    'https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=2516210555,70809240&fm=26&gp=0.jpg',
    'https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=3096080338,1387947480&fm=11&gp=0.jpg',
    'https://ss1.bdstatic.com/70cFuXSh_Q1YnxGkpoWK1HF6hhy/it/u=884602971,918446192&fm=11&gp=0.jpg',
    'https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=2623678637,572331041&fm=26&gp=0.jpg',
    'https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=2585876590,437169879&fm=11&gp=0.jpg',
    'https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=1086362054,1110846781&fm=11&gp=0.jpg',
    'https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=2900641615,456703263&fm=26&gp=0.jpg',
  ];
}
