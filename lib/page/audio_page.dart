import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:eso/database/search_item.dart';
import 'package:eso/model/audio_page_controller.dart';
import 'package:eso/model/audio_service.dart';
import 'package:eso/ui/ui_chapter_select.dart';
import 'package:eso/utils.dart';
import 'package:eso/utils/flutter_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class AudioPage extends StatefulWidget {
  final SearchItem searchItem;

  const AudioPage({
    this.searchItem,
    Key key,
  }) : super(key: key);

  @override
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> with SingleTickerProviderStateMixin {
  Widget _audioPage;
  AudioPageController __provider;
  AnimationController controller;

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
    super.dispose();
  }

  Widget _buildPage() {
    controller = AnimationController(duration: const Duration(seconds: 30), vsync: this);
    //动画开始、结束、向前移动或向后移动时会调用StatusListener
    controller.forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //动画从 controller.forward() 正向执行 结束时会回调此方法
        print("status is completed");
        //重置起点
        controller.reset();
        //开启
        controller.forward();
      } else if (status == AnimationStatus.dismissed) {
        //动画从 controller.reverse() 反向执行 结束时会回调此方法
        print("status is dismissed");
      } else if (status == AnimationStatus.forward) {
        print("status is forward");
        //执行 controller.forward() 会回调此状态
      } else if (status == AnimationStatus.reverse) {
        //执行 controller.reverse() 会回调此状态
        print("status is reverse");
      }
    });
    return ChangeNotifierProvider<AudioPageController>.value(
      value: AudioPageController(searchItem: widget.searchItem, controller: controller),
      child: Consumer<AudioPageController>(
        builder: (BuildContext context, AudioPageController provider, _) {
          __provider = provider;
          final chapter = widget.searchItem.chapters[widget.searchItem.durChapterIndex];
          return Scaffold(
            body: Container(
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
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: _buildTopRow(provider, chapter.name, chapter.time),
                        ),
                        Expanded(
                          child: Container(
                            child: Center(
                              child: RotationTransition(
                                //设置动画的旋转中心
                                alignment: Alignment.center,
                                //动画控制器
                                turns: controller,
                                child: Container(
                                  height: 300,
                                  width: 300,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Utils.empty(chapter.cover) ? Colors.black26 : null,
                                    image: Utils.empty(chapter.cover) ? null : DecorationImage(
                                      image: NetworkImage(chapter.cover ?? ''),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Utils.empty(chapter.cover) ? Icon(Icons.audiotrack, color: Colors.white30, size: 200) : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildProgressBar(provider),
                        SizedBox(height: 10),
                        _buildBottomController(provider),
                        SizedBox(height: 25),
                      ],
                    ),
                  ),
                  provider.showChapter
                      ? UIChapterSelect(
                          searchItem: widget.searchItem,
                          loadChapter: provider.loadChapter)
                      : Container(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopRow(AudioPageController provider, String name, String author) {
    return Row(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: BackButton(color: Colors.white70),
        ),
        SizedBox(
          width: 6,
        ),
        Expanded(
          child: Column(
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
        ),
        SizedBox(
          width: 10,
        ),
        InkWell(
          child: Icon(
            Icons.share,
            color: Colors.white70,
            size: 20,
          ),
          onTap: provider.share,
        ),
      ],
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
                child: Icon(Icons.audiotrack, color: Colors.green, size: 12),
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
            tooltip: FlutterSliderTooltip(disabled: true),
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

  Widget _buildBottomController(AudioPageController provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        InkWell(
          child: Icon(
            provider.repeatMode == AudioService.REPEAT_ALL
                ? Icons.repeat
                : provider.repeatMode == AudioService.REPEAT_ONE
                    ? Icons.repeat_one
                    : Icons.label_outline,
            color: Colors.white,
            size: 26,
          ),
          onTap: provider.switchRepeatMode,
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
        InkWell(
          child: Icon(
            Icons.menu,
            color: Colors.white,
            size: 26,
          ),
          onTap: () => provider.showChapter = !provider.showChapter,
        ),
      ],
    );
  }


  final String defaultImage = _defaultBackgroundImage[Random().nextInt(_defaultBackgroundImage.length * 3) % _defaultBackgroundImage.length];

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
