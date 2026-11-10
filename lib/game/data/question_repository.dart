import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../game_models.dart';
import 'seed_questions.dart';

abstract interface class QuestionSource {
  Future<List<Question>> getQuestions({int? maxTier});
}

class QuestionRepository implements QuestionSource {
  QuestionRepository({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;

  static const _databaseName = 'english_speed_runner.db';
  static const _databaseVersion = 1;

  final DatabaseFactory _factory;
  final String? databasePath;
  Database? _database;
  Future<Database>? _opening;

  @override
  Future<List<Question>> getQuestions({int? maxTier}) async {
    final db = await _openDatabase();
    final rows = await db.rawQuery('''
      SELECT q.id, q.tier, q.text, q.answer, q.explanation,
             o.text AS option_text
      FROM questions q
      LEFT JOIN question_options o ON o.question_id = q.id
      ${maxTier == null ? '' : 'WHERE q.tier <= ?'}
      ORDER BY q.id, o.position
      ''', maxTier == null ? null : [maxTier]);

    final questionsById = <int, _QuestionBuilder>{};
    for (final row in rows) {
      final id = row['id']! as int;
      final builder = questionsById.putIfAbsent(
        id,
        () => _QuestionBuilder(
          id: id,
          tier: row['tier']! as int,
          text: row['text']! as String,
          answer: row['answer']! as String,
          explanation: row['explanation']! as String,
        ),
      );
      final option = row['option_text'] as String?;
      if (option != null) builder.options.add(option);
    }

    return questionsById.values.map((question) => question.build()).toList();
  }

  Future<int> insertQuestion(Question question) async {
    _validate(question);
    final db = await _openDatabase();
    return db.transaction((transaction) async {
      final id = await transaction.insert('questions', {
        'tier': question.tier,
        'text': question.text,
        'answer': question.answer,
        'explanation': question.explanation,
      });
      await _insertOptions(transaction, id, question);
      return id;
    });
  }

  Future<void> updateQuestion(Question question) async {
    _validate(question);
    final id = question.id;
    if (id == null) {
      throw ArgumentError.value(
        question,
        'question',
        'Question must have an ID',
      );
    }

    final db = await _openDatabase();
    await db.transaction((transaction) async {
      final updated = await transaction.update(
        'questions',
        {
          'tier': question.tier,
          'text': question.text,
          'answer': question.answer,
          'explanation': question.explanation,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        throw StateError('Question $id does not exist');
      }
      await transaction.delete(
        'question_options',
        where: 'question_id = ?',
        whereArgs: [id],
      );
      await _insertOptions(transaction, id, question);
    });
  }

  Future<void> deleteQuestion(int id) async {
    final db = await _openDatabase();
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _opening = null;
    if (db != null) await db.close();
  }

  Future<Database> _openDatabase() {
    final database = _database;
    if (database != null) return Future.value(database);
    final opening = _opening ??= _createDatabase();
    return opening.catchError((Object error, StackTrace stackTrace) {
      _opening = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<Database> _createDatabase() async {
    final dbPath =
        databasePath ?? p.join(await getDatabasesPath(), _databaseName);
    final db = await _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: (database, version) async {
          await _createSchema(database);
          await _seedQuestions(database);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 1) {
            await _createSchema(database);
            await _seedQuestions(database);
          }
        },
      ),
    );
    _database = db;
    return db;
  }

  Future<void> _createSchema(DatabaseExecutor database) async {
    await database.execute('''
            CREATE TABLE questions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tier INTEGER NOT NULL CHECK (tier > 0),
              text TEXT NOT NULL,
              answer TEXT NOT NULL,
              explanation TEXT NOT NULL
            )
          ''');
    await database.execute('''
            CREATE TABLE question_options (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              question_id INTEGER NOT NULL,
              text TEXT NOT NULL,
              position INTEGER NOT NULL,
              FOREIGN KEY (question_id) REFERENCES questions (id)
                ON DELETE CASCADE
            )
          ''');
    await database.execute(
      'CREATE INDEX questions_tier_idx ON questions (tier)',
    );
    await database.execute(
      'CREATE INDEX question_options_question_idx '
      'ON question_options (question_id, position)',
    );
  }

  Future<void> _seedQuestions(DatabaseExecutor database) async {
    for (final question in initialQuestions) {
      final id = await database.insert('questions', {
        'tier': question.tier,
        'text': question.text,
        'answer': question.answer,
        'explanation': question.explanation,
      });
      await _insertOptions(database, id, question);
    }
  }

  Future<void> _insertOptions(
    DatabaseExecutor database,
    int questionId,
    Question question,
  ) async {
    for (var index = 0; index < question.options.length; index++) {
      await database.insert('question_options', {
        'question_id': questionId,
        'text': question.options[index],
        'position': index,
      });
    }
  }

  void _validate(Question question) {
    if (question.tier <= 0) {
      throw ArgumentError.value(
        question.tier,
        'tier',
        'Must be greater than 0',
      );
    }
    if (question.text.trim().isEmpty || question.explanation.trim().isEmpty) {
      throw ArgumentError('Question text and explanation must not be empty');
    }
    if (question.options.isEmpty ||
        !question.options.contains(question.answer)) {
      throw ArgumentError('The correct answer must be included in the options');
    }
  }
}

class _QuestionBuilder {
  _QuestionBuilder({
    required this.id,
    required this.tier,
    required this.text,
    required this.answer,
    required this.explanation,
  });

  final int id;
  final int tier;
  final String text;
  final String answer;
  final String explanation;
  final options = <String>[];

  Question build() => Question.withId(
    id,
    tier,
    text,
    List.unmodifiable(options),
    answer,
    explanation,
  );
}
