import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/common/route_generator.dart';
import 'package:flutter/services.dart';

import 'common/theme_helper.dart';
import 'stores/quiz_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await QuizStore.initPrefs();
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A1 test',
      theme: ThemeHelper.getThemeData(),
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
