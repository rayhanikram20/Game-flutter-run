import '../game_models.dart';

const initialQuestions = <Question>[
  Question(
    1,
    "Apa arti dari kata 'Apple'?",
    ['Apel', 'Pisang', 'Jeruk'],
    'Apel',
    "'Apple' dalam bahasa Indonesia berarti buah Apel.",
  ),
  Question(
    1,
    "Kata yang berarti 'Berlari' adalah...",
    ['Run', 'Walk', 'Sleep'],
    'Run',
    "'Run' artinya berlari, sedangkan 'Walk' berjalan dan 'Sleep' tidur.",
  ),
  Question(
    1,
    "Lawan kata dari 'Big' (Besar) adalah...",
    ['Small', 'Tall', 'Heavy'],
    'Small',
    "'Small' artinya kecil, merupakan lawan kata dari 'Big'.",
  ),
  Question(
    1,
    "Apa bahasa Inggris dari 'Kucing'?",
    ['Cat', 'Dog', 'Bird'],
    'Cat',
    "'Cat' artinya kucing.",
  ),
  Question(
    2,
    'She ___ to school every day.',
    ['goes', 'go', 'went'],
    'goes',
    "Untuk subjek 'She' dalam Simple Present Tense menggunakan kata kerja 'goes'.",
  ),
  Question(
    2,
    'They ___ playing football now.',
    ['are', 'is', 'am'],
    'are',
    "Subjek jamak 'They' pada Present Continuous menggunakan to be 'are'.",
  ),
  Question(
    2,
    'I ___ an apple yesterday.',
    ['ate', 'eat', 'eaten'],
    'ate',
    "'Yesterday' menunjukkan Simple Past Tense. V2 dari eat adalah ate.",
  ),
  Question(
    3,
    'If I have enough money, I ___ a new book.',
    ['will buy', 'bought', 'would buy'],
    'will buy',
    'Conditional Type 1: If + Present Tense, Simple Future.',
  ),
  Question(
    3,
    'Choose the correct sentence:',
    [
      'He does not like coffee.',
      'He do not like coffee.',
      'He not likes coffee.',
    ],
    'He does not like coffee.',
    "Subjek 'He' menggunakan 'does not' untuk bentuk negatif.",
  ),
];
