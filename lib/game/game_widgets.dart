import 'package:flutter/material.dart';

import 'game_models.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.score,
    required this.phase,
    required this.streak,
    required this.strikes,
    required this.coins,
    super.key,
  });

  final int score;
  final Phase phase;
  final int streak;
  final int strikes;
  final int coins;


  @override
  Widget build(BuildContext context) {
    final needed = phase == Phase.early ? 5 : 10;
    final progress = phase == Phase.high
        ? 1.0
        : (streak / needed).clamp(0.0, 1.0);
    final phaseText = phase == Phase.high
        ? 'HIGH SPEED'
        : '${phase.name.toUpperCase()} $streak/$needed';
    final phaseColor = switch (phase) {
      Phase.early => const Color(0xff00e5a0),
      Phase.mid   => const Color(0xffff8c00),
      Phase.high  => const Color(0xffff2255),
    };
    final phaseGlow = switch (phase) {
      Phase.early => const Color(0x4400e5a0),
      Phase.mid   => const Color(0x44ff8c00),
      Phase.high  => const Color(0x44ff2255),
    };

    return Stack(
      children: [
        // ── Top bar ──────────────────────────────────────────────────────
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              // Score + coins
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _NeonPill(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coin icon
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xfffff18a),
                                Color(0xffffb000),
                                Color(0xffe78a00),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffffc928).withValues(alpha: .6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Color(0xff7a4000),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xffffc928),
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '×$coins',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xffffc928),
                          ),
                        ),
                      ],
                    ),
                    glowColor: const Color(0x4400e5ff),
                  ),
                ),
              ),
              // Phase pill
              Expanded(
                child: Center(
                  child: _NeonPill(
                    Text(
                      phaseText,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    color: phaseColor,
                    glowColor: phaseGlow,
                  ),
                ),
              ),
              // Lives
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _NeonPill(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        2,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            i < strikes ? Icons.favorite_border : Icons.favorite,
                            color: i < strikes
                                ? const Color(0xff555577)
                                : const Color(0xffff2255),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    glowColor: const Color(0x44ff2255),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Streak progress bar ──────────────────────────────────────────
        Positioned(
          top: 65,
          left: 60,
          right: 60,
          child: Column(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0x661a1f4d),
                  border: Border.all(color: Colors.white.withValues(alpha:.3), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [phaseColor, phaseGlow.withValues(alpha: 1.0)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withValues(alpha: .7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (phase == Phase.high || streak >= 4)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffff2255), Color(0xffff8c00)],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha:.5), width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffff2255).withValues(alpha: .5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🔥 PRO MODE: RINTANGAN GANDA!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Start Overlay
// ─────────────────────────────────────────────────────────────────────────────

class GameStartOverlay extends StatelessWidget {
  const GameStartOverlay({
    required this.onStart,
    required this.onRetry,
    required this.isLoading,
    required this.errorMessage,
    required this.questionCount,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onRetry;
  final bool isLoading;
  final String? errorMessage;
  final int questionCount;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xdd0a0620),
          const Color(0x880a0620),
          const Color(0xdd0a0620),
        ],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Neon title
                _NeonTitle('ENGLISH', 58),
                _NeonTitle('SPEED RUNNER', 42),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff00e5ff).withValues(alpha:.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BELAJAR BAHASA INGGRIS SAMBIL LARI!',
                    style: TextStyle(
                      color: Color(0xff00e5ff),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _CyberpunkTip(
                  Icons.swipe,
                  'Geser untuk Lari',
                  'Kiri/kanan pindah jalur · Atas lompat · Bawah menunduk',
                  const Color(0xff00e5ff),
                ),
                const SizedBox(height: 8),
                _CyberpunkTip(
                  Icons.star,
                  'Jawab di Gerbang Kuis',
                  'Pilih jawaban yang benar. Makin cepat larimu, makin singkat waktunya.',
                  const Color(0xffff00aa),
                ),
                const SizedBox(height: 8),
                _CyberpunkTip(
                  Icons.favorite,
                  '2 Nyawa',
                  'Salah jawab atau menabrak = nyawa berkurang. Habis = Game Over!',
                  const Color(0xffff2255),
                ),
                const SizedBox(height: 20),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat soal: $errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xffff4466)),
                    ),
                  )
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: CircularProgressIndicator(color: Color(0xff00e5ff)),
                  )
                else if (questionCount == 0)
                  const Text(
                    'Belum ada soal. Tambahkan soal ke database dulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                _NeonButton(
                  errorMessage == null ? '▶  MULAI!' : 'COBA LAGI',
                  onPressed: errorMessage == null ? onStart : onRetry,
                  enabled: !isLoading && (errorMessage != null || questionCount > 0),
                ),
                const SizedBox(height: 10),
                Text(
                  'Keyboard: ← → ↑ ↓ atau WASD · Jawab: 1 2 3',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz Overlay
// ─────────────────────────────────────────────────────────────────────────────

class GameQuizOverlay extends StatelessWidget {
  const GameQuizOverlay({
    required this.question,
    required this.options,
    required this.timeLeft,
    required this.timeMax,
    required this.feedback,
    required this.selected,
    required this.onAnswer,
    super.key,
  });

  final Question question;
  final List<String> options;
  final double timeLeft;
  final double timeMax;
  final String feedback;
  final int selected;
  final ValueChanged<int> onAnswer;

  static const _cyan = Color(0xff00e5ff);
  static const _pink = Color(0xffff00aa);
  static const _green = Color(0xff00e5a0);
  static const _red = Color(0xffff2255);

  @override
  Widget build(BuildContext context) {
    final progress = (timeLeft / timeMax).clamp(0.0, 1.0);
    final levelName = switch (question.tier) {
      1 => '📚 Vocabulary',
      2 => '⚡ Tenses & Verbs',
      _ => '🧠 Grammar & Structure',
    };

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xf0080514),
          border: Border.all(color: _cyan.withValues(alpha: .6), width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: .2),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Level badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0055ff), Color(0xff00e5ff)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        levelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Timer countdown
                    Text(
                      '${timeLeft.toStringAsFixed(1)}s',
                      style: TextStyle(
                        color: progress > .5 ? _green : progress > .25 ? const Color(0xffff8c00) : _red,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: (progress > .5 ? _green : _red).withValues(alpha: .8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Question text
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                // Timer bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: progress > .5
                              ? [_green, _cyan]
                              : progress > .25
                              ? [const Color(0xffff8c00), _pink]
                              : [_red, _pink],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: (progress > .5 ? _cyan : _red).withValues(alpha: .6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  options.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NeonQuizOption(
                      index: i,
                      text: options[i],
                      answer: question.answer,
                      feedback: feedback,
                      selected: selected,
                      onTap: () => onAnswer(i),
                    ),
                  ),
                ),
                if (feedback.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: feedback.contains('BENAR')
                          ? _green.withValues(alpha: .15)
                          : _red.withValues(alpha: .15),
                      border: Border.all(
                        color: feedback.contains('BENAR') ? _green : _red,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      feedback,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: feedback.contains('BENAR') ? _green : _red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Over Overlay
// ─────────────────────────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.score,
    required this.coins,
    required this.tier,
    required this.failedQuestions,
    required this.onRestart,
    super.key,
  });

  final int score;
  final int coins;
  final int tier;
  final List<Question> failedQuestions;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xf5080514), Color(0xee100820)],
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // "GAME OVER" neon
        _NeonTitle('GAME OVER', 52, color: const Color(0xffff2255)),
        const SizedBox(height: 4),
        const Text(
          'Lari kamu berakhir...',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        // Stats
        Row(
          children: [
            Expanded(child: _NeonStatCard('Skor', '$score', const Color(0xff00e5ff))),
            const SizedBox(width: 8),
            Expanded(child: _NeonStatCard('Koin', '$coins', const Color(0xffffc928))),
            const SizedBox(width: 8),
            Expanded(child: _NeonStatCard('Level', '$tier', const Color(0xffff00aa))),
          ],
        ),
        const SizedBox(height: 14),
        // Failed questions
        Container(
          constraints: const BoxConstraints(maxHeight: 165),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .04),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pembahasan Soal Salah',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (failedQuestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Kamu menabrak rintangan fisik di lintasan lari.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    )
                  else
                    ...failedQuestions.indexed.map(
                      (entry) => _FailedCard(
                        number: entry.$1 + 1,
                        question: entry.$2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _NeonButton('↺  MAIN LAGI!', onPressed: onRestart),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NeonPill extends StatelessWidget {
  const _NeonPill(
    this.child, {
    this.color = const Color(0x99080514),
    this.glowColor = const Color(0x4400e5ff),
  });

  final Widget child;
  final Color color;
  final Color glowColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Colors.white.withValues(alpha: .25), width: 1.5),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(color: glowColor, blurRadius: 10, spreadRadius: 1),
      ],
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: child,
    ),
  );
}

class _NeonTitle extends StatelessWidget {
  const _NeonTitle(this.text, this.size, {this.color = Colors.white});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'Fredoka',
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      shadows: [
        Shadow(color: color.withValues(alpha: .8), blurRadius: 20),
        Shadow(color: color.withValues(alpha: .4), blurRadius: 40),
        const Shadow(color: Color(0xff0a0620), offset: Offset(-2, 2)),
      ],
    ),
  );
}

class _CyberpunkTip extends StatelessWidget {
  const _CyberpunkTip(this.icon, this.title, this.desc, this.accentColor);

  final IconData icon;
  final String title;
  final String desc;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .04),
      border: Border.all(color: accentColor.withValues(alpha: .4), width: 1.5),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: accentColor.withValues(alpha: .1), blurRadius: 10),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NeonQuizOption extends StatelessWidget {
  const _NeonQuizOption({
    required this.index,
    required this.text,
    required this.answer,
    required this.feedback,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String text;
  final String answer;
  final String feedback;
  final int selected;
  final VoidCallback onTap;

  static const _colors = [
    Color(0xffff8c00),
    Color(0xff00aaff),
    Color(0xff00e5a0),
  ];

  @override
  Widget build(BuildContext context) {
    final correct = feedback.isNotEmpty && text == answer;
    final wrong = feedback.isNotEmpty && selected == index && !correct;
    final accent = correct
        ? const Color(0xff00e5a0)
        : wrong
        ? const Color(0xffff2255)
        : _colors[index % 3];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: feedback.isEmpty ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: correct || wrong ? .2 : .07),
            border: Border.all(color: accent.withValues(alpha: .7), width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (correct || wrong)
                BoxShadow(color: accent.withValues(alpha: .4), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .25),
                  border: Border.all(color: accent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ABC'[index % 3],
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (correct) const Icon(Icons.check_circle, color: Color(0xff00e5a0), size: 20),
              if (wrong) const Icon(Icons.cancel, color: Color(0xffff2255), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonStatCard extends StatelessWidget {
  const _NeonStatCard(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .2), blurRadius: 12),
      ],
    ),
    child: Column(
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: .7), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: [Shadow(color: color.withValues(alpha: .6), blurRadius: 10)],
          ),
        ),
      ],
    ),
  );
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({required this.number, required this.question});

  final int number;
  final Question question;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0x22ff2255),
      border: Border.all(color: const Color(0x55ff2255)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$number. ${question.text}\n✓ ${question.answer}\n${question.explanation}',
      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
    ),
  );
}

class _NeonButton extends StatelessWidget {
  const _NeonButton(this.text, {required this.onPressed, this.enabled = true});

  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xff9b00ff), Color(0xff00e5ff)],
                )
              : const LinearGradient(
                  colors: [Color(0xff333355), Color(0xff222244)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xff9b00ff).withValues(alpha: .5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: enabled ? Colors.white : Colors.white38,
            letterSpacing: 1,
          ),
        ),
      ),
    ),
  );
}
