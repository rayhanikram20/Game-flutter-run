import 'package:flutter/material.dart';

import 'game_models.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.score,
    required this.phase,
    required this.streak,
    required this.strikes,
    super.key,
  });

  final int score;
  final Phase phase;
  final int streak;
  final int strikes;

  static const _ink = Color(0xff1a1f4d);
  static const _orange = Color(0xffff7a1a);

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
      Phase.early => const Color(0xff159d56),
      Phase.mid => const Color(0xffe06a00),
      Phase.high => const Color(0xffd62828),
    };

    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _HudPill(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xfffff18a),
                                Color(0xffffb000),
                                Color(0xffe78a00),
                              ],
                            ),
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0xffffdb62), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _HudPill(
                    Text(
                      phaseText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    color: phaseColor,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HudPill(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        2,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            '♥',
                            style: TextStyle(
                              fontSize: 20,
                              color: index < strikes
                                  ? const Color(0xff8c93bd)
                                  : const Color(0xffff3b5c),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 70,
          left: 70,
          right: 70,
          child: Column(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: _ink,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffffe36b), _orange],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
              if (phase == Phase.high || streak >= 4)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _orange,
                    border: Border.all(color: _ink, width: 3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '🔥 PRO MODE: RINTANGAN GANDA!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  static const _sun = Color(0xffffc928);

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xaa141a5a), Color(0x22141a5a), Color(0xcc141a5a)],
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
                const _GameTitle('ENGLISH', 56, color: _sun),
                const _GameTitle('SPEED RUNNER', 44),
                const SizedBox(height: 18),
                const _TipCard(
                  '👆',
                  'Geser untuk lari',
                  'Kiri/kanan pindah jalur, atas lompat, bawah menunduk. Hindari kereta dan pagar!',
                ),
                const SizedBox(height: 10),
                const _TipCard(
                  '⭐',
                  'Jawab di Gerbang Kuis',
                  'Pilih jawaban Bahasa Inggris yang benar. Makin cepat larimu, makin singkat waktunya.',
                ),
                const SizedBox(height: 10),
                const _TipCard(
                  '❤️',
                  '2 nyawa',
                  'Salah jawab atau menabrak = nyawa berkurang. Habis = Game Over.',
                ),
                const SizedBox(height: 18),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat bank soal: $errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: CircularProgressIndicator(color: _sun),
                  )
                else if (questionCount == 0)
                  const Text(
                    'Belum ada soal. Tambahkan soal ke database untuk mulai bermain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                _GameButton(
                  errorMessage == null ? 'MAIN!' : 'COBA LAGI',
                  onPressed: errorMessage == null ? onStart : onRetry,
                  enabled:
                      !isLoading && (errorMessage != null || questionCount > 0),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Keyboard: ← → ↑ ↓ atau WASD · jawab dengan tombol 1 2 3',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

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

  static const _ink = Color(0xff1a1f4d);
  static const _blue = Color(0xff1e90ff);
  static const _green = Color(0xff2fd06b);
  static const _sun = Color(0xffffc928);
  static const _red = Color(0xffff4545);

  @override
  Widget build(BuildContext context) {
    final progress = (timeLeft / timeMax).clamp(0.0, 1.0);
    final levelName = switch (question.tier) {
      1 => 'Vocabulary',
      2 => 'Tenses & Verbs',
      _ => 'Grammar & Structure',
    };

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _blue,
                  border: Border.all(color: _ink, width: 3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Level ${question.tier}: $levelName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              question.text,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xffe4e8f5),
                      border: Border.all(color: _ink, width: 3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        color: progress > .5
                            ? _green
                            : progress > .25
                            ? _sun
                            : _red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${timeLeft.toStringAsFixed(1)}s',
                  style: const TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(
              options.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _QuizOption(
                  index: index,
                  text: options[index],
                  answer: question.answer,
                  feedback: feedback,
                  selected: selected,
                  onTap: () => onAnswer(index),
                ),
              ),
            ),
            if (feedback.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: feedback.contains('BENAR')
                      ? const Color(0xffb8f5cf)
                      : const Color(0xffffc9c9),
                  border: Border.all(color: _ink, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  feedback,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.score,
    required this.tier,
    required this.failedQuestions,
    required this.onRestart,
    super.key,
  });

  final int score;
  final int tier;
  final List<Question> failedQuestions;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xe61e0a32),
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _GameTitle('GAME OVER', 54),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _StatCard('Skor', '$score')),
            const SizedBox(width: 10),
            Expanded(child: _StatCard('Pencapaian', 'Level $tier')),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(maxHeight: 170),
          padding: const EdgeInsets.all(10),
          decoration: _cardDecoration,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pembahasan soal salah',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (failedQuestions.isEmpty)
                  const Text(
                    '\nKamu menabrak rintangan fisik di lintasan lari.',
                  )
                else
                  ...failedQuestions.indexed.map(
                    (entry) => _FailedQuestionCard(
                      number: entry.$1 + 1,
                      question: entry.$2,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _GameButton('MAIN LAGI!', onPressed: onRestart),
      ],
    ),
  );
}

class _HudPill extends StatelessWidget {
  const _HudPill(this.child, {this.color = const Color(0xdd1a1f4d)});

  final Widget child;
  final Color color;

  static const _ink = Color(0xff1a1f4d);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Colors.white, width: 3),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: _ink.withValues(alpha: .5),
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: child,
    ),
  );
}

class _GameTitle extends StatelessWidget {
  const _GameTitle(this.text, this.size, {this.color = Colors.white});

  final String text;
  final double size;
  final Color color;

  static const _ink = Color(0xff1a1f4d);

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'LuckiestGuy',
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      shadows: const [
        Shadow(color: _ink, offset: Offset(-2, -2)),
        Shadow(color: _ink, offset: Offset(2, 2)),
        Shadow(color: _ink, offset: Offset(0, 5)),
      ],
    ),
  );
}

class _TipCard extends StatelessWidget {
  const _TipCard(this.icon, this.title, this.description);

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: _cardDecoration,
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$title\n$description',
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
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

  static const _ink = Color(0xff1a1f4d);
  static const _orange = Color(0xffff7a1a);
  static const _blue = Color(0xff1e90ff);
  static const _green = Color(0xff2fd06b);

  @override
  Widget build(BuildContext context) {
    final correct = feedback.isNotEmpty && text == answer;
    final wrong = feedback.isNotEmpty && selected == index && !correct;
    final colors = [_orange, _blue, _green];
    final background = correct
        ? const Color(0xffb8f5cf)
        : wrong
        ? const Color(0xffffc9c9)
        : Colors.white;
    final borderColor = correct
        ? const Color(0xff12803c)
        : wrong
        ? const Color(0xffb01919)
        : _ink;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors[index],
                  border: Border.all(color: _ink, width: 3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ABC'[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: _ink.withValues(alpha: .45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);

  final String label;
  final String value;

  static const _ink = Color(0xff1a1f4d);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: _cardDecoration,
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _ink.withValues(alpha: .6),
            fontWeight: FontWeight.bold,
          ),
        ),
        _GameTitle(value, 28),
      ],
    ),
  );
}

class _FailedQuestionCard extends StatelessWidget {
  const _FailedQuestionCard({required this.number, required this.question});

  final int number;
  final Question question;

  static const _ink = Color(0xff1a1f4d);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xfffff7dc),
      border: Border.all(color: _ink, width: 3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      '$number. ${question.text}\n✓ Jawaban benar: ${question.answer}\n${question.explanation}',
      style: const TextStyle(fontSize: 12, height: 1.3),
    ),
  );
}

class _GameButton extends StatelessWidget {
  const _GameButton(this.text, {required this.onPressed, this.enabled = true});

  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  static const _ink = Color(0xff1a1f4d);
  static const _orange = Color(0xffff7a1a);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _ink, width: 4),
        ),
        elevation: 10,
        shadowColor: _ink,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

BoxDecoration get _cardDecoration => BoxDecoration(
  color: Colors.white,
  border: Border.all(color: const Color(0xff1a1f4d), width: 4),
  borderRadius: BorderRadius.circular(22),
  boxShadow: const [BoxShadow(color: Color(0xff1a1f4d), offset: Offset(0, 6))],
);
