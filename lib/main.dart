import 'package:flutter/material.dart';

import 'game/data/database_factory.dart';
import 'game/data/question_repository.dart';
import 'game/game_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabaseFactory();
  runApp(EnglishSpeedRunnerApp(questionRepository: QuestionRepository()));
}

class EnglishSpeedRunnerApp extends StatelessWidget {
  const EnglishSpeedRunnerApp({this.questionRepository, super.key});

  final QuestionSource? questionRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'English Speed Runner',
    theme: ThemeData(fontFamily: 'Fredoka', useMaterial3: false),
    home: GamePage(repository: questionRepository),
  );
}
