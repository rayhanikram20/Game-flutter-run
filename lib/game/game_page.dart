import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_models.dart';
import 'game_painter.dart';
import 'runner_flame_game.dart';
import 'game_widgets.dart';
import 'data/question_repository.dart';

class GamePage extends StatefulWidget {
  const GamePage({this.repository, super.key});

  final QuestionSource? repository;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const ink = Color(0xff0a0620), blue = Color(0xff00e5ff);
  late final RunnerFlameGame flameGame;
  late final QuestionSource repository;
  final rng = math.Random();
  List<Question> questionBank = [];
  bool questionsLoading = true;
  String? questionLoadError;
  GameState state = GameState.start;
  Phase phase = Phase.early;
  int score = 0, tier = 1, strikes = 0, streak = 0;
  int coins = 0;
  double speed = .007, baseSpeed = .007, distance = 0, quizAt = .35, scroll = 0;
  double playerX = 1, jumpY = 0, vy = 0, animationTime = 0;
  int lane = 1;
  double crouchTimer = 0, invTimer = 0;
  final obstacles = <Obstacle>[];
  final failed = <Question>[];
  bool gate = false;
  Question? current;
  List<String> options = [];
  double timeLeft = 20, timeMax = 20;
  Timer? quizTimer;
  String feedback = '';
  int selected = -1;
  late final GamePainter scenePainter;
  double _uiRefreshElapsed = 0;
  bool _uiUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? QuestionRepository();
    flameGame = RunnerFlameGame()..onTick = _frame;
    scenePainter = GamePainter(
      scroll: scroll,
      playerX: playerX,
      animationTime: animationTime,
      running: false,
      jumpY: jumpY,
      crouch: false,
      invincible: false,
      obstacles: obstacles,
      gate: false,
      gateZ: 1,
    );
    flameGame.updateScene(scenePainter);
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
    super.dispose();
  }

  void _frame(double dt) {
    if (!mounted) return;
    if (state == GameState.running) {
      final frames = (dt * 60).clamp(0.0, 3.0);
      animationTime += dt;
      playerX += (lane - playerX) * (1 - math.pow(.75, frames)).toDouble();
      if (jumpY < 0 || vy < 0) {
        jumpY += vy * frames;
        vy += .85 * frames;
        if (jumpY >= 0) {
          jumpY = 0;
          vy = 0;
        }
      }
      crouchTimer = math.max(0, crouchTimer - dt).toDouble();
      invTimer = math.max(0, invTimer - dt).toDouble();
      speed += .0000015 * frames;
      distance += speed * frames;
      scroll += speed * 1.8 * frames;
      final pro = phase == Phase.high || streak >= 4;
      final hazardCount = obstacles
          .where((obstacle) => obstacle.type != ObstacleType.coin)
          .length;
      if (rng.nextDouble() < (pro ? .025 : .012) * frames &&
          hazardCount < (pro ? 4 : 2)) {
        _spawn();
      }
      final activeCoins = obstacles
          .where((obstacle) => obstacle.type == ObstacleType.coin)
          .length;
      if (activeCoins < 3 && rng.nextDouble() < .003 * frames) {
        _spawnCoins();
      }
      if (distance >= quizAt && !gate) gate = true;
      for (final o in List<Obstacle>.from(obstacles)) {
        o.z -= speed * 1.8 * frames;
        if (o.z <= .12 && o.z >= 0 && (playerX - o.lane).abs() < .45) {
          if (o.type == ObstacleType.coin) {
            coins++;
            score += 25;
            _playSound('coin_pickup.ogg');
            // Trigger coin burst particle at coin position
            final sz = flameGame.size;
            final coinPos = scenePainter.pos(
              ui.Size(sz.x, sz.y),
              o.lane.toDouble(),
              o.z,
            );
            flameGame.spawnCoinBurst(coinPos);
            obstacles.remove(o);
            continue;
          }
          if (invTimer > 0) continue;
          var hit = true;
          if (o.type == ObstacleType.lowBar && jumpY < -22) hit = false;
          if (o.type == ObstacleType.highBar && crouchTimer > 0) hit = false;
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
      _syncScene();
      _requestUiRefresh(dt);
    } else if (state == GameState.start) {
      scroll = (scroll + .6 * dt) % 1;
      _syncScene();
      _requestUiRefresh(dt);
    }
  }

  void _syncScene() {
    scenePainter
      ..scroll = scroll
      ..playerX = playerX
      ..animationTime = animationTime
      ..running = state == GameState.running
      ..jumpY = jumpY
      ..crouch = crouchTimer > 0
      ..invincible = invTimer > 0
      ..gate = gate
      ..gateZ = 1 - ((distance - quizAt).clamp(0, 1) * 1.8);
    flameGame.updateScene(scenePainter);
  }

  void _requestUiRefresh(double dt) {
    _uiRefreshElapsed += dt;
    if (_uiRefreshElapsed < 1 / 30 || _uiUpdateScheduled) return;

    _uiRefreshElapsed = 0;
    _uiUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uiUpdateScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _start() {
    if (questionsLoading || questionLoadError != null || questionBank.isEmpty) {
      return;
    }
    _playSound('ui_click.ogg');
    quizTimer?.cancel();
    setState(() {
      state = GameState.running;
      phase = Phase.early;
      score = 0;
      coins = 0;
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
      crouchTimer = 0;
      invTimer = 0;
      obstacles.clear();
      failed.clear();
      gate = false;
      feedback = '';
      selected = -1;
    });
    _syncScene();
  }

  void _left() {
    if (state == GameState.running && lane > 0) {
      setState(() => lane--);
      _syncScene();
    }
  }

  void _right() {
    if (state == GameState.running && lane < 2) {
      setState(() => lane++);
      _syncScene();
    }
  }

  void _jump() {
    if (state == GameState.running && jumpY == 0) {
      _playSound('jump.ogg');
      setState(() {
        vy = -14;
        crouchTimer = 0;
      });
      _syncScene();
    }
  }

  void _slide() {
    if (state == GameState.running) {
      setState(() {
        crouchTimer = .58;
        if (jumpY < 0) vy += 7;
      });
      _syncScene();
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

  void _spawnCoins() {
    final availableLanes = List.generate(3, (index) => index)
        .where(
          (candidate) => !obstacles.any(
            (obstacle) =>
                obstacle.type != ObstacleType.coin &&
                obstacle.lane == candidate &&
                obstacle.z > .2 &&
                obstacle.z < 1.5,
          ),
        )
        .toList();
    if (availableLanes.isEmpty) return;

    final coinLane = availableLanes[rng.nextInt(availableLanes.length)];
    for (var index = 0; index < 3; index++) {
      obstacles.add(Obstacle(coinLane, 1 + index * .12, ObstacleType.coin, 0));
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
      _playSound('quiz_correct.ogg');
      streak++;
      final gain = tier * 100 + (timeLeft * 10).round();
      score += gain;
      feedback = '✨ BENAR! Combo: ${streak}x';
      _phaseUp();
    } else {
      _playSound('quiz_wrong.ogg');
      streak = 0;
      feedback = '❌ SALAH! Jawaban: ${current!.answer}';
      _strike(current);
    }
    setState(() {});
    _syncScene();
    Future.delayed(const Duration(milliseconds: 1100), _resume);
  }

  void _timeout() {
    if (state != GameState.quiz) return;
    streak = 0;
    feedback = '⏱ WAKTU HABIS! Jawaban: ${current!.answer}';
    _strike(current);
    setState(() {});
    _syncScene();
    Future.delayed(const Duration(milliseconds: 1100), _resume);
  }

  void _resume() {
    if (!mounted || strikes >= 2) return;
    setState(() {
      state = GameState.running;
      quizAt = distance + .35 + rng.nextDouble() * .15;
    });
    _syncScene();
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
    if (invTimer > 0) return;
    if (q == null) _playSound('runner_crash.ogg');
    strikes++;
    streak = 0;
    flameGame.triggerHitShake();
    if (q != null && !failed.contains(q)) failed.add(q);
    if (strikes >= 2) {
      quizTimer?.cancel();
      state = GameState.gameOver;
    } else {
      invTimer = 1.5;
      speed = math.max(baseSpeed, speed * .85);
    }
  }

  void _playSound(String file) {
    unawaited(_playSoundAsync(file));
  }

  Future<void> _playSoundAsync(String file) async {
    try {
      await FlameAudio.play(file, volume: .7);
    } catch (error) {
      debugPrint('Game audio "$file" could not be played: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050310),
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
                    border: Border.all(color: blue.withValues(alpha: .6), width: 2),
                    color: ink,
                    boxShadow: [
                      BoxShadow(
                        color: blue.withValues(alpha: .3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
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
                        Positioned.fill(child: GameWidget(game: flameGame)),
                        if (state == GameState.running ||
                            state == GameState.quiz)
                          GameHud(
                            score: score,
                            phase: phase,
                            streak: streak,
                            strikes: strikes,
                            coins: coins,
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
                            coins: coins,
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
