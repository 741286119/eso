import 'package:eso/utils/flutter_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../global.dart';
import '../../model/profile.dart';

class ColorLensPage extends StatelessWidget {
  const ColorLensPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = Global.colors.keys.toList();
    final colors = Global.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text('调色板'),
      ),
      body: Consumer<Profile>(
        builder: (BuildContext context, Profile profile, Widget widget) {
          return ListView.builder(
            itemCount: keys.length * 2 + 2,
            itemBuilder: (BuildContext context, int index) {
              if (index % 2 == 1) {
                return Divider();
              }
              if (index == 0) {
                return _buildCustomColor();
              }
              String colorName = keys[index ~/ 2 - 1];
              return _buildColorListTile(colorName, Color(colors[colorName]));
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomColor() {
    return Consumer<Profile>(
      builder: (BuildContext context, Profile profile, Widget widget) {
        final color = Color(profile.customColor);
        return Column(
          children: <Widget>[
            _buildColorListTile('自定义', color),
            ListTile(
              leading: _buildColorContainer(Colors.red.withOpacity(color.red / 255)),
              title: _buildSeekBar(
                Colors.red,
                color.red,
                (value) => profile.customColorRed = value,
              ),
            ),
            ListTile(
              leading: _buildColorContainer(Colors.green.withOpacity(color.green / 255)),
              title: _buildSeekBar(
                Colors.green,
                color.green,
                (value) => profile.customColorGreen = value,
              ),
            ),
            ListTile(
              leading: _buildColorContainer(Colors.blue.withOpacity(color.blue / 255)),
              title: _buildSeekBar(
                Colors.blue,
                color.blue,
                (value) => profile.customColorBlue = value,
              ),
            ),
          ],
        );
      },
    );
  }

  Container _buildSeekBar(Color color, int value, void Function(int) valueChanged) {
    return Container(
      height: 46,
      child: FlutterSlider(
        values: [value.toDouble()],
        max: 255,
        min: 0,
        onDragging: (handlerIndex, lowerValue, upperValue) =>
            valueChanged((lowerValue as double).toInt()),
        trackBar: FlutterSliderTrackBar(
          inactiveTrackBar: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.4),
          ),
          activeTrackBar: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
        ),
        hatchMark: FlutterSliderHatchMark(
          labelsDistanceFromTrackBar: 24,
          linesDistanceFromTrackBar: -4,
          linesAlignment: FlutterSliderHatchMarkAlignment.left,
          displayLines: true,
          density: 0.16,
          smallLine: FlutterSliderSizedBox(
              height: 6, width: 1, decoration: BoxDecoration(color: color)),
          bigLine: FlutterSliderSizedBox(
              height: 8, width: 2, decoration: BoxDecoration(color: color)),
          labels: [
            FlutterSliderHatchMarkLabel(
              percent: 0,
              label: Text('0', style: TextStyle(fontSize: 12)),
            ),
            FlutterSliderHatchMarkLabel(
              percent: 5 / 16 * 100,
              label: Text('50', style: TextStyle(fontSize: 12)),
            ),
            FlutterSliderHatchMarkLabel(
              percent: 10 / 16 * 100,
              label: Text('A0', style: TextStyle(fontSize: 12)),
            ),
            FlutterSliderHatchMarkLabel(
              percent: 15 / 16 * 100,
              label: Text('F0', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        handlerWidth: 6,
        handlerHeight: 14,
        handler: FlutterSliderHandler(
          decoration: BoxDecoration(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color,
              border: Border.all(color: color.withOpacity(0.65), width: 1),
            ),
          ),
        ),
        tooltip: FlutterSliderTooltip(
          disableAnimation: true,
          custom: (value) => Container(
            padding: EdgeInsets.all(8),
            color: color,
            child: Text("0x" +
                (value as double).toInt().toRadixString(16).toUpperCase() +
                " | " +
                (value as double).toStringAsFixed(0)),
          ),
          positionOffset: FlutterSliderTooltipPositionOffset(left: -20, right: -20),
        ),
      ),
    );
  }

  Widget _buildColorListTile(String colorName, Color color) {
    return Consumer<Profile>(
      builder: (BuildContext context, Profile profile, Widget widget) {
        return ListTile(
          leading: _buildColorContainer(color),
          trailing: colorName == profile.colorName
              ? Icon(Icons.done, size: 32, color: color)
              : null,
          title: Text(colorName),
          onTap: () => profile.colorName = colorName,
        );
      },
    );
  }

  Container _buildColorContainer(Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      height: 32,
      width: 32,
    );
  }
}
