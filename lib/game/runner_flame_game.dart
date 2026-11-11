import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'game_models.dart';
import 'game_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Flame Game
// ─────────────────────────────────────────────────────────────────────────────

class RunnerFlameGame extends FlameGame {
  RunnerFlameGame() {
    world.add(_bg);
    world.add(_track);
    world.add(_runner);
  }

  final _bg = _ParallaxBg();
  final _track = _RunnerTrack();
  late final _RunnerCharacter _runner;
  bool _hasGameSize = false;
  bool _cameraAligned = false;

  void Function(double dt)? onTick;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _runner = _RunnerCharacter();
    world.add(_runner);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_cameraAligned) {
      camera.viewfinder.anchor = Anchor.topLeft;
      _cameraAligned = true;
    }
    _hasGameSize = true;
    _track.size = size;
    _bg.size = size;
    _syncRunner();
  }

  @override
  void update(double dt) {
    super.update(dt);
    onTick?.call(dt);
  }

  void updateScene(GamePainter painter) {
    _track.painter = painter;
    _bg.scroll = painter.scroll;
    _syncRunner();
  }

  void spawnCoinBurst(Offset worldPos) {
    world.add(
      ParticleSystemComponent(
        position: Vector2(worldPos.dx, worldPos.dy),
        particle: Particle.generate(
          count: 10,
          lifespan: 0.6,
          generator: (i) {
            final angle = (i / 10) * math.pi * 2;
            final speed = 60.0 + math.Random().nextDouble() * 60;
            return AcceleratedParticle(
              speed: Vector2(
                math.cos(angle) * speed,
                math.sin(angle) * speed - 80,
              ),
              acceleration: Vector2(0, 200),
              child: CircleParticle(
                radius: 4 + math.Random().nextDouble() * 4,
                paint: Paint()
                  ..color = const Color(0xffffc928).withValues(alpha: 0.9),
              ),
            );
          },
        ),
      ),
    );
  }

  void triggerHitShake() {
    camera.viewfinder.add(
      SequenceEffect([
        MoveEffect.to(
          Vector2(6, -4),
          EffectController(duration: 0.05),
        ),
        MoveEffect.to(
          Vector2(-6, 4),
          EffectController(duration: 0.05),
        ),
        MoveEffect.to(
          Vector2(4, -2),
          EffectController(duration: 0.04),
        ),
        MoveEffect.to(
          Vector2(-2, 2),
          EffectController(duration: 0.04),
        ),
        MoveEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.05),
        ),
      ]),
    );
  }

  void _syncRunner() {
    final painter = _track.painter;
    if (painter == null || !_hasGameSize) return;

    final sz = size;
    final pos = painter.playerAnchor(ui.Size(sz.x, sz.y));
    _runner.position.setValues(pos.dx, pos.dy);

    final pose = painter.invincible
        ? _RunnerPose.hit
        : painter.crouch
        ? _RunnerPose.slide
        : painter.jumpY < 0
        ? _RunnerPose.jump
        : painter.running
        ? _RunnerPose.run
        : _RunnerPose.idle;

    _runner.setPose(pose);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Runner Character using SpriteAnimationGroupComponent
// ─────────────────────────────────────────────────────────────────────────────

class _RunnerCharacter extends SpriteAnimationGroupComponent<_RunnerPose>
    with HasGameReference<RunnerFlameGame> {
  _RunnerCharacter()
      : super(
          size: Vector2(72, 112),
          anchor: Anchor.bottomCenter,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load individual frame sprites (compatible with existing assets)
    final stand = await game.images.load('runner/runner_stand.png');
    final runA = await game.images.load('runner/runner_run_a.png');
    final runB = await game.images.load('runner/runner_run_b.png');
    final jump = await game.images.load('runner/runner_jump.png');
    final slide = await game.images.load('runner/runner_slide.png');
    final hit = await game.images.load('runner/runner_hit.png');

    animations = {
      _RunnerPose.idle: SpriteAnimation.spriteList(
        [Sprite(stand)],
        stepTime: 1.0,
      ),
      _RunnerPose.run: SpriteAnimation.spriteList(
        [Sprite(runA), Sprite(runB)],
        stepTime: 0.11,
      ),
      _RunnerPose.jump: SpriteAnimation.spriteList(
        [Sprite(jump)],
        stepTime: 1.0,
      ),
      _RunnerPose.slide: SpriteAnimation.spriteList(
        [Sprite(slide)],
        stepTime: 1.0,
      ),
      _RunnerPose.hit: SpriteAnimation.spriteList(
        [Sprite(stand), Sprite(hit)],
        stepTime: 0.12,
      ),
    };
    current = _RunnerPose.idle;
  }

  void setPose(_RunnerPose pose) {
    if (current == pose) return;
    current = pose;
    // Squash-and-stretch on jump start
    if (pose == _RunnerPose.jump) {
      add(
        ScaleEffect.to(
          Vector2(0.75, 1.3),
          EffectController(duration: 0.08),
        ),
      );
      add(
        ScaleEffect.to(
          Vector2(1.0, 1.0),
          EffectController(duration: 0.12, startDelay: 0.08),
        ),
      );
    }
    if (pose == _RunnerPose.slide) {
      size = Vector2(96, 72);
      anchor = Anchor.bottomCenter;
    } else {
      size = Vector2(72, 112);
      anchor = Anchor.bottomCenter;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parallax Background (3-layer)
// ─────────────────────────────────────────────────────────────────────────────

class _ParallaxBg extends PositionComponent
    with HasGameReference<RunnerFlameGame> {
  double scroll = 0;
  ui.Image? _sky, _city, _buildings;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sky = await game.images.load('world/bg_sky.png');
    _city = await game.images.load('world/bg_city.png');
    _buildings = await game.images.load('world/bg_buildings.png');
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final sz = ui.Size(size.x, size.y);
    final horizonY = sz.height * 0.33;

    // Layer 0: Sky (slow scroll – 0.1x)
    _drawTiledLayer(canvas, _sky, sz, 0, 0, sz.height * 0.5, speed: 0.1);

    // Layer 1: Distant city (0.3x speed)
    _drawTiledLayer(
      canvas,
      _city,
      sz,
      0,
      horizonY * 0.1,
      sz.height * 0.55,
      speed: 0.3,
    );

    // Layer 2: Close buildings (0.6x speed)
    _drawTiledLayer(
      canvas,
      _buildings,
      sz,
      0,
      horizonY * 0.35,
      sz.height * 0.5,
      speed: 0.6,
    );
  }

  void _drawTiledLayer(
    ui.Canvas canvas,
    ui.Image? img,
    ui.Size sz,
    double x,
    double y,
    double drawH, {
    required double speed,
  }) {
    if (img == null) return;
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
    final src = ui.Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    // Calculate horizontal offset for scrolling
    final offset = (scroll * speed * sz.width * 0.5) % sz.width;
    final drawW = sz.width + 2;
    // Draw twice for seamless tiling
    canvas.drawImageRect(
      img,
      src,
      ui.Rect.fromLTWH(-offset, y, drawW, drawH),
      paint,
    );
    canvas.drawImageRect(
      img,
      src,
      ui.Rect.fromLTWH(drawW - offset, y, drawW, drawH),
      paint,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track: paints road + obstacles + coins + gate using GamePainter
// ─────────────────────────────────────────────────────────────────────────────

class _RunnerTrack extends PositionComponent
    with HasGameReference<RunnerFlameGame> {
  GamePainter? painter;
  ui.Image? _coinSheet;
  ui.Image? _obstacleSheet;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _coinSheet = await game.images.load('world/coin_sheet.png');
    _obstacleSheet = await game.images.load('world/obstacles_sheet.png');
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final p = painter;
    if (p == null) return;
    final sz = ui.Size(size.x, size.y);
    // Core road geometry + gate
    p.paintRoad(canvas, sz);
    // Sprite-based obstacles & coins
    _drawObstacles(canvas, sz, p);
  }

  void _drawObstacles(ui.Canvas canvas, ui.Size s, GamePainter p) {
    final sorted = [...p.obstacles]..sort((a, b) => b.z.compareTo(a.z));
    for (final o in sorted) {
      if (o.type == ObstacleType.coin) {
        _drawCoinSprite(canvas, s, p, o);
      } else {
        _drawObstacleSprite(canvas, s, p, o);
      }
    }
  }

  void _drawCoinSprite(
    ui.Canvas canvas,
    ui.Size s,
    GamePainter p,
    Obstacle o,
  ) {
    final coin = _coinSheet;
    if (coin == null) {
      p.paintCoin(canvas, s, o);
      return;
    }
    final pos = p.pos(s, o.lane.toDouble(), o.z);
    final k = math.max(0.05, 1 - o.z);
    final w = 36.0 * k;

    // 8-frame coin spin – pick frame based on animation time + offset
    final frame = ((p.animationTime * 8 + o.z * 7) % 8).floor();
    final frameW = coin.width / 8;
    final src = ui.Rect.fromLTWH(frame * frameW, 0, frameW, coin.height.toDouble());
    final dst = ui.Rect.fromCenter(
      center: ui.Offset(pos.dx, pos.dy - 28 * k),
      width: w,
      height: w,
    );
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;

    // Glow halo
    canvas.drawCircle(
      ui.Offset(pos.dx, pos.dy - 28 * k),
      w * 0.65,
      Paint()..color = const Color(0x44ffc928),
    );
    canvas.drawImageRect(coin, src, dst, paint);
  }

  void _drawObstacleSprite(
    ui.Canvas canvas,
    ui.Size s,
    GamePainter p,
    Obstacle o,
  ) {
    final sheet = _obstacleSheet;
    if (sheet == null) {
      p.paintObstacle(canvas, s, o);
      return;
    }
    final pos = p.pos(s, o.lane.toDouble(), o.z);
    final k = math.max(0.05, 1 - o.z);
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;

    // obstacleSheet layout (from generated image – 3 rows):
    // row 0 (top ~27%): lowBar  
    // row 1 (middle ~46%): train
    // row 2 (bottom ~27%): highBar
    final sheetH = sheet.height.toDouble();
    final sheetW = sheet.width.toDouble();

    switch (o.type) {
      case ObstacleType.lowBar:
        final srcH = sheetH * 0.26;
        final src = ui.Rect.fromLTWH(0, 0, sheetW, srcH);
        final w = 90.0 * k, h = 28.0 * k;
        final dst = ui.Rect.fromCenter(
          center: ui.Offset(pos.dx, pos.dy - h * 0.5),
          width: w,
          height: h,
        );
        canvas.drawImageRect(sheet, src, dst, paint);
      case ObstacleType.highBar:
        final srcY = sheetH * 0.74;
        final srcH = sheetH * 0.26;
        final src = ui.Rect.fromLTWH(0, srcY, sheetW, srcH);
        final w = 90.0 * k, h = 28.0 * k;
        final dst = ui.Rect.fromCenter(
          center: ui.Offset(pos.dx, pos.dy - 68 * k),
          width: w,
          height: h,
        );
        canvas.drawImageRect(sheet, src, dst, paint);
      case ObstacleType.train:
        final srcY = sheetH * 0.26;
        final srcH = sheetH * 0.48;
        final src = ui.Rect.fromLTWH(0, srcY, sheetW, srcH);
        final w = 78.0 * k, h = 100.0 * k;
        final dst = ui.Rect.fromCenter(
          center: ui.Offset(pos.dx, pos.dy - h * 0.5),
          width: w,
          height: h,
        );
        canvas.drawImageRect(sheet, src, dst, paint);
      case ObstacleType.coin:
        break; // handled above
    }
  }
}

enum _RunnerPose { idle, run, jump, slide, hit }
