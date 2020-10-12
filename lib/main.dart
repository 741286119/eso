import 'dart:io';
import 'package:eso/ui/edit/local_cupertion_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:eso/page/first_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'model/profile.dart';
import 'model/history_manager.dart';
import 'page/home_page.dart';

void main() {
  runApp(MyApp());
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //debugPaintSizeEnabled = true;
    return FutureBuilder<bool>(
      future: Global.init(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            title: Global.appName,
            home: FirstPage(),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<Profile>.value(
              value: Profile(),
            ),
            Provider<HistoryManager>.value(
              value: HistoryManager(),
            ),
          ],
          child: Consumer<Profile>(
            builder: (BuildContext context, Profile profile, Widget widget) {
              return OKToast(
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontFamily: profile.fontFamily,
                  ),
                  backgroundColor: Colors.black.withOpacity(0.8),
                  radius: 20.0,
                  textPadding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: MaterialApp(
                    theme: profile.getTheme(profile.fontFamily, isDarkMode: false),
                    darkTheme: profile.getTheme(profile.fontFamily, isDarkMode: true),
                    title: Global.appName,
                    localizationsDelegates: [
                      LocalizationsCupertinoDelegate.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    locale: Locale('zh', 'CH'),
                    supportedLocales: [Locale('zh', 'CH')],
                    home: HomePage(),
                  ));
            },
          ),
        );
      },
    );
  }
}
