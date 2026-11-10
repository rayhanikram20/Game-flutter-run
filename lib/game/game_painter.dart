import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_models.dart';

class GamePainter extends CustomPainter {
  final double scroll, playerX, jumpY, gateZ, animationTime;
  final bool crouch, invincible, gate, running;
  final List<Obstacle> obstacles;
  final Phase phase;
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
    required this.phase,
  });
  static const ink = Color(0xff1a1f4d);
  Offset pos(Size s, double lane, double z) {
    final k = math.max(.05, 1 - z);
    return Offset(
      s.width / 2 + (lane - 1) * s.width * .28 * k,
      s.height * .3 + (s.height - 95 - s.height * .3) * k,
    );
  }

  @override
  void paint(Canvas c, Size s) {
    final vy = s.height * .32;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff26a5f8), Color(0xffa4e2ff)],
      ).createShader(Rect.fromLTWH(0, 0, s.width, vy));
    c.drawRect(Rect.fromLTWH(0, 0, s.width, vy), sky);
    _drawCloud(c, s, s.width * .64, s.height * .15, 1);
    _drawCloud(c, s, s.width * .14, s.height * .095, .62);
    _drawCity(c, s, vy);
    c.drawRect(
      Rect.fromLTWH(0, vy, s.width, s.height - vy),
      Paint()..color = const Color(0xffcdb999),
    );
    final road = Path()
      ..moveTo(s.width * .49, vy)
      ..lineTo(s.width * 1.02, s.height)
      ..lineTo(-s.width * .02, s.height)
      ..close();
    c.drawPath(road, Paint()..color = const Color(0xff8f7f6e));
    _drawSideBuildings(c, s, vy);
    for (var i = 0; i < 22; i++) {
      final z = ((i * .065 - scroll) % 1.45 + 1.45) % 1.45 - .3;
      final a = pos(s, -.55, z), b = pos(s, 2.55, z);
      c.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xff5d422f)
          ..strokeWidth = math.max(2, 12 * (1 - z)),
      );
      c.drawLine(
        a.translate(0, -2),
        b.translate(0, -2),
        Paint()
          ..color = const Color(0x668d765f)
          ..strokeWidth = math.max(1, 2 * (1 - z)),
      );
    }
    const railBottom = [.09, .24, .44, .58, .78, .92];
    for (var i = 0; i < railBottom.length; i++) {
      final bottom = Offset(s.width * railBottom[i], s.height + 5);
      final top = Offset(s.width * (.48 + i * .008), vy + 8);
      c.drawLine(
        top,
        bottom,
        Paint()
          ..color = ink
          ..strokeWidth = 5,
      );
      c.drawLine(
        top,
        bottom,
        Paint()
          ..color = const Color(0xffe6eaf4)
          ..strokeWidth = 2.5,
      );
      c.drawLine(
        top.translate(-2, 0),
        bottom.translate(-2, 0),
        Paint()
          ..color = const Color(0xff8c9bb2)
          ..strokeWidth = 1,
      );
    }
    if (gate) _gate(c, s, gateZ);
    final sorted = [...obstacles]..sort((a, b) => b.z.compareTo(a.z));
    for (final o in sorted) {
      _obstacle(c, s, o);
    }
    if (!(invincible &&
        DateTime.now().millisecondsSinceEpoch ~/ 120 % 2 == 0)) {
      _player(c, s);
    }
  }

  void _drawCloud(Canvas c, Size s, double x, double y, double scale) {
    final cloud = Paint()..color = const Color(0xddffffff);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: 48 * scale,
        height: 42 * scale,
      ),
      cloud,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x - 27 * scale, y + 7 * scale),
        width: 42 * scale,
        height: 34 * scale,
      ),
      cloud,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x + 27 * scale, y + 7 * scale),
        width: 42 * scale,
        height: 34 * scale,
      ),
      cloud,
    );
  }

  void _drawCity(Canvas c, Size s, double horizon) {
    for (var i = -2; i < 10; i++) {
      final x = i * .18 * s.width;
      final width = s.width * (.12 + (i.abs() % 3) * .015);
      final height = s.height * (.07 + ((i * 7).abs() % 6) * .014);
      final top = horizon - height;
      final building = Rect.fromLTWH(x, top, width, height);
      c.drawRect(
        building.shift(Offset(s.width * .008, 0)),
        Paint()..color = const Color(0x223d78a3),
      );
      c.drawRect(building, Paint()..color = const Color(0x665c9fca));
      c.drawRect(
        Rect.fromLTWH(x, top, width, s.height * .008),
        Paint()..color = const Color(0x5586c5e8),
      );
      final windowPaint = Paint()..color = const Color(0x335278a2);
      for (var row = 0; row < 3; row++) {
        final windowY = top + s.height * (.018 + row * .022);
        if (windowY + s.height * .008 < horizon) {
          c.drawRect(
            Rect.fromLTWH(
              x + width * .18,
              windowY,
              width * .16,
              s.height * .008,
            ),
            windowPaint,
          );
          c.drawRect(
            Rect.fromLTWH(
              x + width * .58,
              windowY,
              width * .16,
              s.height * .008,
            ),
            windowPaint,
          );
        }
      }
    }
  }

  void _drawSideBuildings(Canvas c, Size s, double horizon) {
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
    c.drawPath(leftWall, Paint()..color = const Color(0xffb9a17f));
    c.drawPath(rightWall, Paint()..color = const Color(0xffb9a17f));

    Path polygon(List<Offset> points) {
      final path = Path()
        ..moveTo(points.first.dx * s.width, points.first.dy * s.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * s.width, point.dy * s.height);
      }
      return path..close();
    }

    final panels = <(List<Offset>, Color)>[
      (
        [
          const Offset(0, .19),
          const Offset(.09, .21),
          const Offset(.09, .69),
          const Offset(0, .80),
        ],
        const Color(0xffffd260),
      ),
      (
        [
          const Offset(.09, .28),
          const Offset(.26, .30),
          const Offset(.27, .55),
          const Offset(.09, .71),
        ],
        const Color(0xffed7198),
      ),
      (
        [
          const Offset(.26, .30),
          const Offset(.43, .30),
          const Offset(.43, .39),
          const Offset(.26, .56),
        ],
        const Color(0xfff3a24e),
      ),
      (
        [
          const Offset(.43, .28),
          const Offset(.47, .30),
          const Offset(.47, .36),
          const Offset(.43, .34),
        ],
        const Color(0xffffc928),
      ),
      (
        [
          const Offset(1, .19),
          const Offset(.91, .21),
          const Offset(.91, .69),
          const Offset(1, .80),
        ],
        const Color(0xffb48cdb),
      ),
      (
        [
          const Offset(.91, .28),
          const Offset(.74, .30),
          const Offset(.73, .55),
          const Offset(.91, .71),
        ],
        const Color(0xff79cd85),
      ),
      (
        [
          const Offset(.74, .30),
          const Offset(.57, .30),
          const Offset(.57, .39),
          const Offset(.74, .56),
        ],
        const Color(0xff68afe8),
      ),
      (
        [
          const Offset(.57, .28),
          const Offset(.53, .30),
          const Offset(.53, .36),
          const Offset(.57, .34),
        ],
        const Color(0xffbd83d4),
      ),
    ];
    for (final (points, color) in panels) {
      final shape = polygon(points);
      c.drawPath(shape, Paint()..color = color);
      c.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ink,
      );
    }

    final travel = (scroll * 1.4) % .18;
    final motion = Paint()
      ..color = const Color(0x44764f32)
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
        motion.strokeWidth = math.max(3, s.width * (.012 + .026 * depth));
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

    final leftWindow = polygon([
      const Offset(.14, .43),
      const Offset(.20, .41),
      const Offset(.20, .46),
      const Offset(.14, .48),
    ]);
    final rightWindow = polygon([
      const Offset(.86, .43),
      const Offset(.80, .41),
      const Offset(.80, .46),
      const Offset(.86, .48),
    ]);
    c.drawPath(leftWindow, Paint()..color = const Color(0xfff23b83));
    c.drawPath(rightWindow, Paint()..color = const Color(0xff22c878));
    final windowBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;
    c.drawPath(leftWindow, windowBorder);
    c.drawPath(rightWindow, windowBorder);
    c.drawPath(
      leftWall,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    c.drawPath(
      rightWall,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
  }

  void _gate(Canvas c, Size s, double z) {
    final a = pos(s, -.62, z),
        b = pos(s, 2.62, z),
        k = math.max(.05, 1 - z),
        h = 130 * k;
    c.drawRect(
      Rect.fromLTWH(a.dx - 5, a.dy - h, 10, h),
      Paint()..color = const Color(0xffffc928),
    );
    c.drawRect(
      Rect.fromLTWH(b.dx - 5, b.dy - h, 10, h),
      Paint()..color = const Color(0xffffc928),
    );
    c.drawRect(
      Rect.fromLTWH(a.dx, a.dy - h, b.dx - a.dx, 40 * k),
      Paint()..color = const Color(0xffff3d8b),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '★ ENGLISH QUIZ ★',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: math.max(8, 19 * k),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2, a.dy - h + 8 * k));
  }

  void _obstacle(Canvas c, Size s, Obstacle o) {
    final p = pos(s, o.lane.toDouble(), o.z),
        k = math.max(.05, 1 - o.z),
        w = 74 * k;
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
      c.drawRRect(r, Paint()..color = colors[o.color]);
      c.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * k
          ..color = ink,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(p.dx, p.dy - 65 * k),
            width: w * .68,
            height: 25 * k,
          ),
          Radius.circular(4 * k),
        ),
        Paint()..color = const Color(0xffbfe9ff),
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

  void _player(Canvas c, Size s) {
    final runPhase = animationTime * 12;
    final stride = running ? math.sin(runPhase) : 0.0;
    final forward = running ? math.sin(runPhase).abs() : 0.0;
    final ground = pos(s, playerX, 0);
    final bob = running ? math.sin(runPhase * 2).abs() * 4 : 0.0;
    final p = ground + Offset(0, jumpY - bob + (jumpY == 0 ? forward * 2 : 0));

    c.drawOval(
      Rect.fromCenter(
        center: Offset(ground.dx, ground.dy - 2),
        width: 30 + forward * 7,
        height: 7 + forward * 1.5,
      ),
      Paint()..color = const Color(0x660d1538),
    );
    c.save();
    c.translate(p.dx, p.dy);
    final bodyScale = 1 + forward * .065;
    c.scale(bodyScale, bodyScale);
    c.rotate(-.035 - stride * .025);
    if (crouch) c.scale(1.15, .62);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = ink;
    void rr(Color color, double x, double y, double w, double h, double r) {
      final q = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      );
      c.drawRRect(q, Paint()..color = color);
      c.drawRRect(q, stroke);
    }

    final legSwing = running ? stride * .72 : 0.0;
    for (var side = 0; side < 2; side++) {
      final direction = side == 0 ? 1.0 : -1.0;
      c.save();
      c.translate(side == 0 ? -7 : 7, -18);
      c.rotate(legSwing * direction);
      rr(const Color(0xff2b3a8c), -5, 0, 10, 18, 4);
      rr(Colors.white, -6, 14, 12, 6, 3);
      c.restore();
    }
    rr(const Color(0xff1e90ff), -16, -46, 32, 32, 10);
    rr(const Color(0xffff7a1a), -10, -42, 20, 22, 6);
    final armSwing = running ? stride * .62 : 0.0;
    for (var side = 0; side < 2; side++) {
      final direction = side == 0 ? 1.0 : -1.0;
      c.save();
      c.translate(side == 0 ? -13 : 13, -40);
      c.rotate(armSwing * direction);
      rr(const Color(0xff1e90ff), side == 0 ? -9 : 1, 0, 8, 20, 4);
      c.restore();
    }
    c.drawCircle(
      const Offset(0, -58),
      13,
      Paint()..color = const Color(0xfff2b886),
    );
    c.drawCircle(const Offset(0, -58), 13, stroke);
    final cap = Path()
      ..moveTo(-13, -60)
      ..quadraticBezierTo(0, -76, 13, -60)
      ..close();
    c.drawPath(cap, Paint()..color = const Color(0xffff4545));
    c.drawPath(cap, stroke);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}
