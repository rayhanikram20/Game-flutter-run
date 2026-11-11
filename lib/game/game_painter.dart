import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_models.dart';

/// GamePainter is now a pure **data/position model** – no Canvas drawing except
/// for the road geometry, gate banner, and fallback shapes used when sprites
/// aren't yet loaded. All background scenery is handled by _ParallaxBg in
/// runner_flame_game.dart.
class GamePainter {
  double scroll, playerX, jumpY, gateZ, animationTime;
  bool crouch, invincible, gate, running;
  final List<Obstacle> obstacles;

  GamePainter({
    required this.scroll,
    required this.playerX,
    required this.animationTime,
    required this.running,
    required this.jumpY,
    required this.crouch,
    required this.invincible,
    required this.obstacles,
    required this.gate,
    required this.gateZ,
  });

  static const ink = Color(0xff1a1f4d);

  // ── Coordinate helpers ───────────────────────────────────────────────────

  Offset playerAnchor(Size size) => pos(size, playerX, 0) + Offset(0, jumpY);

  Offset pos(Size s, double lane, double z) {
    final k = math.max(.05, 1 - z);
    return Offset(
      s.width / 2 + (lane - 1) * s.width * .28 * k,
      s.height * .3 + (s.height - 95 - s.height * .3) * k,
    );
  }

  // ── Road-only paint (called by _RunnerTrack) ─────────────────────────────

  /// Draws only the 3D road perspective, rail markings, and gate.
  /// Background scenery is handled by _ParallaxBg.
  void paintRoad(Canvas c, Size s) {
    final vy = s.height * .32;

    // Ground fill below horizon
    c.drawRect(
      Rect.fromLTWH(0, vy, s.width, s.height - vy),
      Paint()..color = const Color(0xff1a1424),
    );

    // Road trapezoid
    final road = Path()
      ..moveTo(s.width * .49, vy)
      ..lineTo(s.width * 1.02, s.height)
      ..lineTo(-s.width * .02, s.height)
      ..close();
    c.drawPath(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff2a1e3a), Color(0xff0d0d1a)],
        ).createShader(Rect.fromLTWH(0, vy, s.width, s.height - vy)),
    );

    // Neon lane dividers (3 lanes × 2 rails each)
    for (var lane = 0; lane < 3; lane++) {
      for (final offset in [-.32, .32]) {
        final top = pos(s, lane + offset, .98).translate(0, 7);
        final bottom = pos(s, lane + offset, 0).translate(0, 5);

        // Outer glow
        c.drawLine(
          top,
          bottom,
          Paint()
            ..color = const Color(0x3300e5ff)
            ..strokeWidth = 14
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // Core line
        c.drawLine(
          top,
          bottom,
          Paint()
            ..color = const Color(0xff00e5ff)
            ..strokeWidth = 2.5,
        );
      }
    }

    // Animated road stripes scrolling toward viewer
    final travel = (scroll * 1.6) % 1.0;
    final stripePaint = Paint()
      ..color = const Color(0x55ffffff)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 20; i++) {
      final z = ((i * .07 - travel) % 1.4 + 1.4) % 1.4 - .3;
      if (z < 0 || z > 1) continue;
      final a = pos(s, .01, z), b = pos(s, 1.99, z);
      c.drawLine(a, b, stripePaint..strokeWidth = math.max(1.0, 8 * (1 - z)));
    }

    // Side walls with neon panels
    _drawNeonSideWalls(c, s, vy);

    if (gate) _gate(c, s, gateZ);
  }

  // ── Neon side walls ──────────────────────────────────────────────────────

  void _drawNeonSideWalls(Canvas c, Size s, double horizon) {
    final leftWall = Path()
      ..moveTo(0, horizon * .6)
      ..lineTo(s.width * .49, horizon)
      ..lineTo(s.width * .07, s.height)
      ..lineTo(0, s.height)
      ..close();
    final rightWall = Path()
      ..moveTo(s.width, horizon * .6)
      ..lineTo(s.width * .51, horizon)
      ..lineTo(s.width * .93, s.height)
      ..lineTo(s.width, s.height)
      ..close();

    // Dark wall base
    c.drawPath(leftWall, Paint()..color = const Color(0xff120a1f));
    c.drawPath(rightWall, Paint()..color = const Color(0xff120a1f));

    Path polygon(List<Offset> points) {
      final path = Path()
        ..moveTo(points.first.dx * s.width, points.first.dy * s.height);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx * s.width, p.dy * s.height);
      }
      return path..close();
    }

    // Neon panels – cyberpunk color palette
    final panels = <(List<Offset>, Color)>[
      (
        [
          const Offset(0, .19),
          const Offset(.09, .21),
          const Offset(.09, .69),
          const Offset(0, .80),
        ],
        const Color(0xffff00aa),
      ),
      (
        [
          const Offset(.09, .28),
          const Offset(.26, .30),
          const Offset(.27, .55),
          const Offset(.09, .71),
        ],
        const Color(0xff00e5ff),
      ),
      (
        [
          const Offset(.26, .30),
          const Offset(.43, .30),
          const Offset(.43, .39),
          const Offset(.26, .56),
        ],
        const Color(0xff9b59ff),
      ),
      (
        [
          const Offset(1, .19),
          const Offset(.91, .21),
          const Offset(.91, .69),
          const Offset(1, .80),
        ],
        const Color(0xff00ff88),
      ),
      (
        [
          const Offset(.91, .28),
          const Offset(.74, .30),
          const Offset(.73, .55),
          const Offset(.91, .71),
        ],
        const Color(0xffff6600),
      ),
      (
        [
          const Offset(.74, .30),
          const Offset(.57, .30),
          const Offset(.57, .39),
          const Offset(.74, .56),
        ],
        const Color(0xfff0ff00),
      ),
    ];

    // Animated scroll motion on walls
    final travel = (scroll * 1.4) % .18;
    final motion = Paint()
      ..color = const Color(0x3300e5ff)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    for (var side = 0; side < 2; side++) {
      c.save();
      c.clipPath(side == 0 ? leftWall : rightWall);
      for (var i = 0; i < 6; i++) {
        final depth = (i * .18 + travel) % 1;
        final y = horizon + (s.height - horizon) * depth;
        final innerX = side == 0
            ? s.width * (.49 - .42 * depth)
            : s.width * (.51 + .42 * depth);
        motion.strokeWidth = math.max(2, s.width * (.01 + .022 * depth));
        if (side == 0) {
          c.drawLine(
            Offset(-s.width * .06, y),
            Offset(innerX, y - s.height * .13 * (1 - depth)),
            motion,
          );
        } else {
          c.drawLine(
            Offset(s.width * 1.06, y),
            Offset(innerX, y - s.height * .13 * (1 - depth)),
            motion,
          );
        }
      }
      c.restore();
    }

    for (final (points, color) in panels) {
      final shape = polygon(points);
      // Glow effect
      c.drawPath(
        shape,
        Paint()
          ..color = color.withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Solid fill (semi-transparent)
      c.drawPath(shape, Paint()..color = color.withValues(alpha: .55));
      // Neon border
      c.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = color,
      );
    }

    // Wall outlines
    final wallBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0x8800e5ff);
    c.drawPath(leftWall, wallBorder);
    c.drawPath(rightWall, wallBorder);
  }

  // ── Gate banner ──────────────────────────────────────────────────────────

  void _gate(Canvas c, Size s, double z) {
    final a = pos(s, -.62, z),
        b = pos(s, 2.62, z),
        k = math.max(.05, 1 - z),
        h = 130 * k;

    // Posts
    final postPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xff00e5ff), const Color(0xff0055ff)],
      ).createShader(
        Rect.fromLTWH(a.dx - 5, a.dy - h, 10, h),
      );
    c.drawRect(Rect.fromLTWH(a.dx - 7 * k, a.dy - h, 14 * k, h), postPaint);
    c.drawRect(Rect.fromLTWH(b.dx - 7 * k, b.dy - h, 14 * k, h), postPaint);

    // Banner
    final bannerRect = Rect.fromLTWH(a.dx, a.dy - h, b.dx - a.dx, 44 * k);
    c.drawRect(
      bannerRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff9b00ff), Color(0xff00e5ff)],
        ).createShader(bannerRect),
    );

    // Glow on banner
    c.drawRect(
      bannerRect,
      Paint()
        ..color = const Color(0x4400e5ff)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '★ ENGLISH QUIZ ★',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: math.max(8, 20 * k),
          shadows: const [Shadow(color: Color(0xff00e5ff), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2, a.dy - h + 10 * k));
  }

  // ── Fallback sprite painters (used if sprite not loaded yet) ────────────

  void paintCoin(Canvas c, Size s, Obstacle o) {
    final p = pos(s, o.lane.toDouble(), o.z);
    final k = math.max(.05, 1 - o.z);
    final center = Offset(p.dx, p.dy - 25 * k);
    final radius = math.max(5.0, 17 * k);
    final squeeze = math.max(
      .22,
      math.cos(animationTime * 5 + o.z * 7).abs(),
    );
    c.drawCircle(
      center.translate(0, radius * .14),
      radius * 1.22,
      Paint()..color = const Color(0x55ffb000),
    );
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(squeeze, 1);
    c.drawCircle(Offset.zero, radius, Paint()..color = const Color(0xffffc928));
    c.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, 3 * k)
        ..color = ink,
    );
    c.restore();
  }

  void paintObstacle(Canvas c, Size s, Obstacle o) {
    final p = pos(s, o.lane.toDouble(), o.z);
    final k = math.max(.05, 1 - o.z);
    final w = 74 * k;

    if (o.type == ObstacleType.train) {
      final colors = [
        const Color(0xffff7a1a),
        const Color(0xff1e90ff),
        const Color(0xff2fd06b),
      ];
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(p.dx, p.dy - 46 * k),
          width: w,
          height: 92 * k,
        ),
        Radius.circular(7 * k),
      );
      c.drawRRect(r, Paint()..color = colors[o.color % 3]);
      c.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * k
          ..color = ink,
      );
    } else if (o.type == ObstacleType.lowBar) {
      final r = Rect.fromCenter(
        center: Offset(p.dx, p.dy - 14 * k),
        width: w,
        height: 28 * k,
      );
      c.drawRect(r, Paint()..color = Colors.white);
      for (var i = 0; i < 3; i++) {
        c.drawRect(
          Rect.fromLTWH(r.left + i * w / 3, r.top, w / 6, r.height),
          Paint()..color = const Color(0xffff4545),
        );
      }
      c.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * k
          ..color = ink,
      );
    } else {
      final top = p.dy - 70 * k;
      c.drawRect(
        Rect.fromLTWH(p.dx - w / 2, top, w, 26 * k),
        Paint()..color = const Color(0xffffc928),
      );
      c.drawRect(
        Rect.fromLTWH(p.dx - w / 2, top, 8 * k, 70 * k),
        Paint()..color = const Color(0xff8b94b8),
      );
      c.drawRect(
        Rect.fromLTWH(p.dx + w / 2 - 8 * k, top, 8 * k, 70 * k),
        Paint()..color = const Color(0xff8b94b8),
      );
    }
  }
}
