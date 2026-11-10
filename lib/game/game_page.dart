import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_models.dart';
import 'game_painter.dart';
import 'game_widgets.dart';
import 'data/question_repository.dart';

class GamePage extends StatefulWidget {
  const GamePage({this.repository, super.key});

  final QuestionSource? repository;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  static const ink = Color(0xff1a1f4d), blue = Color(0xff1e90ff);
  late final AnimationController ticker;
  late final QuestionSource repository;
  final rng = math.Random();
  List<Question> questionBank = [];
  bool questionsLoading = true;
  String? questionLoadError;
  GameState state = GameState.start;
  Phase phase = Phase.early;
  int score = 0, tier = 1, strikes = 0, streak = 0;
  double speed = .007, baseSpeed = .007, distance = 0, quizAt = .35, scroll = 0;
  double playerX = 1, jumpY = 0, vy = 0, animationTime = 0;
  int lane = 1, crouchTicks = 0, invTicks = 0;
  final obstacles = <Obstacle>[];
  final failed = <Question>[];
  bool gate = false;
  Question? current;
  List<String> options = [];
  double timeLeft = 20, timeMax = 20;
  Timer? quizTimer;
  String feedback = '';
  int selected = -1;
  Offset? pointerStart;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? QuestionRepository();
    ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_frame)
      ..repeat();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      questionsLoading = true;
      questionLoadError = null;
    });
    try {
      final loadedQuestions = await repository.getQuestions();
      if (!mounted) return;
      setState(() {
        questionBank = loadedQuestions;
        questionsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        questionLoadError = error.toString();
        questionsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    quizTimer?.cancel();
    ticker.dispose();
    super.dispose();
  }

  void _frame() {
    if (!mounted) return;
    if (state == GameState.running) {
      animationTime += 1 / 60;
      playerX += (lane - playerX) * .25;
      if (jumpY < 0 || vy < 0) {
        jumpY += vy;
        vy += .85;
        if (jumpY >= 0) {
          jumpY = 0;
          vy = 0;
        }
      }
      if (crouchTicks > 0) crouchTicks--;
      if (invTicks > 0) invTicks--;
      speed += .0000015;
      distance += speed;
      scroll += speed * 1.8;
      final pro = phase == Phase.high || streak >= 4;
      if (rng.nextDouble() < (pro ? .025 : .012) &&
          obstacles.length < (pro ? 4 : 2)) {
        _spawn();
      }
      if (distance >= quizAt && !gate) gate = true;
      for (final o in List<Obstacle>.from(obstacles)) {
        o.z -= speed * 1.8;
        if (o.z <= .12 &&
            o.z >= 0 &&
            (playerX - o.lane).abs() < .45 &&
            invTicks == 0) {
          var hit = true;
          if (o.type == ObstacleType.lowBar && jumpY < -22) hit = false;
          if (o.type == ObstacleType.highBar && crouchTicks > 0) hit = false;
          if (hit) {
            _strike();
            obstacles.remove(o);
          }
        }
      }
      obstacles.removeWhere((o) => o.z < -.1);
      if (gate) {
        final gateZ = 1 - ((distance - quizAt).clamp(0, 1) * 1.8);
        if (gateZ <= .08) {
          gate = false;
          _openQuiz();
        }
      }
    } else if (state == GameState.start) {
      scroll += .01;
    }
    setState(() {});
  }

  void _start() {
    if (questionsLoading || questionLoadError != null || questionBank.isEmpty) {
      return;
    }
    quizTimer?.cancel();
    setState(() {
      state = GameState.running;
      phase = Phase.early;
      score = 0;
      tier = 1;
      strikes = 0;
      streak = 0;
      speed = baseSpeed = .007;
      distance = 0;
      quizAt = .35;
      scroll = 0;
      lane = 1;
      playerX = 1;
      jumpY = 0;
      vy = 0;
      crouchTicks = 0;
      invTicks = 0;
      obstacles.clear();
      failed.clear();
      gate = false;
      feedback = '';
      selected = -1;
    });
  }

  void _left() {
    if (state == GameState.running && lane > 0) setState(() => lane--);
  }

  void _right() {
    if (state == GameState.running && lane < 2) setState(() => lane++);
  }

  void _jump() {
    if (state == GameState.running && jumpY == 0) {
      setState(() {
        vy = -14;
        crouchTicks = 0;
      });
    }
  }

  void _slide() {
    if (state == GameState.running) {
      setState(() {
        crouchTicks = 35;
        if (jumpY < 0) vy += 7;
      });
    }
  }

  void _spawn() {
    final r = rng.nextDouble();
    final type = r < .35
        ? ObstacleType.lowBar
        : r < .7
        ? ObstacleType.highBar
        : ObstacleType.train;
    if ((score >= 400 || streak >= 3) && rng.nextDouble() < .45) {
      final safe = rng.nextInt(3);
      for (var l = 0; l < 3; l++) {
        if (l != safe) {
          obstacles.add(Obstacle(l, 1, type, rng.nextInt(3)));
        }
      }
    } else {
      obstacles.add(Obstacle(rng.nextInt(3), 1, type, rng.nextInt(3)));
    }
  }

  void _openQuiz() {
    state = GameState.quiz;
    timeMax = phase == Phase.early
        ? 20
        : phase == Phase.mid
        ? 14
        : 10;
    timeLeft = timeMax;
    final pool = questionBank.where((q) => q.tier <= tier).toList();
    if (pool.isEmpty) pool.addAll(questionBank);
    current = pool[rng.nextInt(pool.length)];
    options = [...current!.options]..shuffle(rng);
    feedback = '';
    selected = -1;
    quizTimer?.cancel();
    quizTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || state != GameState.quiz) {
        t.cancel();
        return;
      }
      setState(() => timeLeft -= .1);
      if (timeLeft <= 0) {
        timeLeft = 0;
        t.cancel();
        _timeout();
      }
    });
  }

  void _answer(int i) {
    if (state != GameState.quiz || feedback.isNotEmpty) return;
    quizTimer?.cancel();
    selected = i;
    if (options[i] == current!.answer) {
      streak++;
      final gain = tier * 100 + (timeLeft * 10).round();
      score += gain;
      feedback = '✨ BENAR! Combo: ${streak}x';
      _phaseUp();
    } else {
      streak = 0;
      feedback = '❌ SALAH! Jawaban: ${current!.answer}';
      _strike(current);
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1100), _resume);
  }

  void _timeout() {
    if (state != GameState.quiz) return;
    streak = 0;
    feedback = '⏱ WAKTU HABIS! Jawaban: ${current!.answer}';
    _strike(current);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1100), _resume);
  }

  void _resume() {
    if (!mounted || strikes >= 2) return;
    setState(() {
      state = GameState.running;
      quizAt = distance + .35 + rng.nextDouble() * .15;
    });
  }

  void _phaseUp() {
    if (streak >= 10 && phase != Phase.high) {
      phase = Phase.high;
      tier = 3;
      baseSpeed = speed = .016;
    } else if (streak >= 5 && phase == Phase.early) {
      phase = Phase.mid;
      tier = 2;
      baseSpeed = speed = .011;
    }
  }

  void _strike([Question? q]) {
    if (invTicks > 0) return;
    strikes++;
    streak = 0;
    if (q != null && !failed.contains(q)) failed.add(q);
    if (strikes >= 2) {
      quizTimer?.cancel();
      state = GameState.gameOver;
    } else {
      invTicks = 90;
      speed = math.max(baseSpeed, speed * .85);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff171a45),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430, maxHeight: 860),
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, e) {
                if (e is KeyDownEvent) {
                  final k = e.logicalKey;
                  if (k == LogicalKeyboardKey.arrowLeft ||
                      k == LogicalKeyboardKey.keyA) {
                    _left();
                  }
                  if (k == LogicalKeyboardKey.arrowRight ||
                      k == LogicalKeyboardKey.keyD) {
                    _right();
                  }
                  if (k == LogicalKeyboardKey.arrowUp ||
                      k == LogicalKeyboardKey.keyW ||
                      k == LogicalKeyboardKey.space) {
                    _jump();
                  }
                  if (k == LogicalKeyboardKey.arrowDown ||
                      k == LogicalKeyboardKey.keyS) {
                    _slide();
                  }
                  if (state == GameState.quiz) {
                    if (k == LogicalKeyboardKey.digit1) _answer(0);
                    if (k == LogicalKeyboardKey.digit2) _answer(1);
                    if (k == LogicalKeyboardKey.digit3) _answer(2);
                  }
                }
                return KeyEventResult.handled;
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  MediaQuery.sizeOf(context).width > 440 ? 26 : 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ink, width: 4),
                    color: blue,
                  ),
                  child: GestureDetector(
                    onPanStart: (d) => pointerStart = d.globalPosition,
                    onPanEnd: (d) {
                      final v = d.velocity.pixelsPerSecond;
                      if (v.distance < 100) return;
                      if (v.dx.abs() > v.dy.abs()) {
                        v.dx > 0 ? _right() : _left();
                      } else {
                        v.dy < 0 ? _jump() : _slide();
                      }
                    },
                    onTapUp: (d) {
                      if (state != GameState.running) return;
                      final width = math.min(
                        MediaQuery.sizeOf(context).width,
                        430.0,
                      );
                      final height = math.min(
                        MediaQuery.sizeOf(context).height,
                        860.0,
                      );
                      if (d.localPosition.dx < width / 3) {
                        _left();
                      } else if (d.localPosition.dx > width * 2 / 3) {
                        _right();
                      } else if (d.localPosition.dy < height / 2) {
                        _jump();
                      } else {
                        _slide();
                      }
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GamePainter(
                              scroll: scroll,
                              playerX: playerX,
                              animationTime: animationTime,
                              running: state == GameState.running,
                              jumpY: jumpY,
                              crouch: crouchTicks > 0,
                              invincible: invTicks > 0,
                              obstacles: obstacles,
                              gate: gate,
                              gateZ:
                                  1 - ((distance - quizAt).clamp(0, 1) * 1.8),
                              phase: phase,
                            ),
                          ),
                        ),
                        if (state == GameState.running ||
                            state == GameState.quiz)
                          GameHud(
                            score: score,
                            phase: phase,
                            streak: streak,
                            strikes: strikes,
                          ),
                        if (state == GameState.start)
                          GameStartOverlay(
                            onStart: _start,
                            onRetry: _loadQuestions,
                            isLoading: questionsLoading,
                            errorMessage: questionLoadError,
                            questionCount: questionBank.length,
                          ),
                        if (state == GameState.quiz)
                          GameQuizOverlay(
                            question: current!,
                            options: options,
                            timeLeft: timeLeft,
                            timeMax: timeMax,
                            feedback: feedback,
                            selected: selected,
                            onAnswer: _answer,
                          ),
                        if (state == GameState.gameOver)
                          GameOverOverlay(
                            score: score,
                            tier: tier,
                            failedQuestions: failed,
                            onRestart: _start,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
