import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../global.dart';

class UIImageItem extends StatelessWidget {
  final String cover;
  final double width;
  final double height;

  UIImageItem({
    this.cover,
    this.width,
    this.height,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _width = width ?? MediaQuery.of(context).size.width;
    final _height = height ?? MediaQuery.of(context).size.height;
    if (cover == null) {
      return Image.asset(
        Global.waitingPath,
        fit: BoxFit.cover,
      );
    }
    String _cover = cover;
    Map<String, String> headers = Map<String, String>();
    final ss = _cover.split('@headers');
    if (ss.length > 1) {
      _cover = ss[0];
      headers = (jsonDecode(ss[1]) as Map).map((k, v) => MapEntry('$k', '$v'));
    }
    return ClipRRect(
        //borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(width/2, height/10)),
        child: Stack(
      children: [
        FadeInImage(
          placeholder: AssetImage(Global.waitingPath),
          image: NetworkImage(
            "$_cover",
            headers: headers,
          ),
          fit: BoxFit.cover,
          width: _width,
          height: _height,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
          child: new Container(
            color: Colors.black.withOpacity(0.1),
            width: _width,
            height: _height,
          ),
        ),
      ],
    ));
  }
}
