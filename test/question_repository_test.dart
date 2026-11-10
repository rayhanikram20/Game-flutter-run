import 'package:englisggame/game/data/question_repository.dart';
import 'package:englisggame/game/game_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late QuestionRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    repository = QuestionRepository(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await repository.close();
  });

  test('creates the schema and seeds the initial question bank', () async {
    final questions = await repository.getQuestions();

    expect(questions, hasLength(9));
    expect(questions.first.id, isNotNull);
    expect(questions.first.options, ['Apel', 'Pisang', 'Jeruk']);
    expect(questions.first.answer, 'Apel');
    expect(questions.first.explanation, contains('Apple'));
  });

  test('filters questions by maximum tier', () async {
    final questions = await repository.getQuestions(maxTier: 1);

    expect(questions, hasLength(4));
    expect(questions.every((question) => question.tier == 1), isTrue);
  });

  test('supports adding, updating, and deleting questions', () async {
    final id = await repository.insertQuestion(
      const Question(
        1,
        'Test question?',
        ['Correct', 'Incorrect'],
        'Correct',
        'Test explanation.',
      ),
    );

    final inserted = (await repository.getQuestions()).singleWhere(
      (question) => question.id == id,
    );
    expect(inserted.options, ['Correct', 'Incorrect']);

    await repository.updateQuestion(
      Question.withId(
        id,
        2,
        'Updated question?',
        const ['Right', 'Wrong'],
        'Right',
        'Updated explanation.',
      ),
    );
    final updated = (await repository.getQuestions()).singleWhere(
      (question) => question.id == id,
    );
    expect(updated.tier, 2);
    expect(updated.answer, 'Right');
    expect(updated.explanation, 'Updated explanation.');
    expect(updated.options, ['Right', 'Wrong']);

    await repository.deleteQuestion(id);
    expect(
      (await repository.getQuestions()).any((question) => question.id == id),
      isFalse,
    );
  });
}
