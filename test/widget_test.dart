// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:englisggame/game/data/question_repository.dart';
import 'package:englisggame/game/data/seed_questions.dart';
import 'package:englisggame/game/game_models.dart';
import 'package:englisggame/main.dart';

void main() {
  testWidgets('shows the start screen and starts the game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      EnglishSpeedRunnerApp(questionRepository: _MemoryQuestionSource()),
    );
    await tester.pump();

    expect(find.text('SPEED RUNNER'), findsOneWidget);
    expect(find.text('MAIN!'), findsOneWidget);

    await tester.ensureVisible(find.text('MAIN!'));
    await tester.tap(find.text('MAIN!'));
    await tester.pump();

    expect(find.text('EARLY 0/5'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tapAt(const Offset(220, 200));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
  });
}

class _MemoryQuestionSource implements QuestionSource {
  @override
  Future<List<Question>> getQuestions({int? maxTier}) async => initialQuestions
      .where((question) => maxTier == null || question.tier <= maxTier)
      .toList();
}
