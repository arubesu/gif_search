import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:flutter/material.dart';
import 'package:gif_search/pages/home_page.dart';

Future main() async {
  await DotEnv.load(fileName: ".env");
  runApp(
      MaterialApp(home: HomePage(), theme: ThemeData(hintColor: Colors.white)));
}
