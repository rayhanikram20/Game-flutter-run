enum GameState { start, running, quiz, gameOver }

enum Phase { early, mid, high }

enum ObstacleType { lowBar, highBar, train }

class Question {
  final int? id;
  final int tier;
  final String text;
  final List<String> options;
  final String answer;
  final String explanation;
  const Question(
    this.tier,
    this.text,
    this.options,
    this.answer,
    this.explanation, {
    this.id,
  });

  const Question.withId(
    this.id,
    this.tier,
    this.text,
    this.options,
    this.answer,
    this.explanation,
  );
}

class Obstacle {
  int lane;
  double z;
  final ObstacleType type;
  final int color;
  Obstacle(this.lane, this.z, this.type, this.color);
}
