import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:url_launcher/url_launcher.dart' show canLaunch, launch;

main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'example_app',
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<MatchText> pareText() {
    return [
      MatchText(
        type: ParsedType.EMAIL,
        style: TextStyle(
          color: Colors.red,
          fontSize: 15,
        ),
        onTap: (url) {
          print('tap $url');
        },
      ),
      MatchText(
        pattern: r"\B@+([\w]+)\b",
        style: TextStyle(
          color: Colors.amber,
          fontSize: 15,
        ),
        renderText: ({required String str, required String pattern}) {
          Map<String, String> map = Map<String, String>();
          RegExp customRegExp = RegExp(pattern);
          Match match = customRegExp.firstMatch(str) as Match;
          map['display'] = match.group(1)!;
          map['value'] = match.group(2)!;
          return map;
        },
        onTap: (url) {
          print('tap $url');
        },
      ),
      MatchText(
        pattern: r"\B#+([\w]+)\b", // a custom pattern to match
        style: TextStyle(
          color: Colors.green,
          fontSize: 15,
        ), // custom style to be applied to this matched text
        onTap: (url) {
          print('tap $url');
        }, // callback funtion when the text is tapped on
      ),
    ];
  }

  String longText =
      "Our fun and flirty embroidered dress with godet skirt detail is a great choice for a mother of the bride, guest of #wedding, or special occasion. As a midi length #dress with 3/4 illusion #sleeves and illusion neckline it provides great coverage while not being stifling.❤️❤❤";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AppBar Title"),
      ),
      body: ParsedText(
        trimLines: 3,
        parse: pareText(),
        text: longText,
        alignment: TextAlign.start,
        overflow: TextOverflow.clip,
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
