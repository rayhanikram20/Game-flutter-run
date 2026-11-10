# English Speed Runner

Game belajar Bahasa Inggris berbasis Flutter dengan bank soal SQLite.

## Database soal

- `questions` menyimpan tingkat kesulitan, teks soal, jawaban benar, dan penjelasan.
- `question_options` menyimpan pilihan jawaban dalam urutan tampilnya.
- Soal awal di-seed saat database pertama kali dibuat.
- `QuestionRepository` menyediakan baca, filter tier, tambah, ubah, dan hapus soal.
- Game memuat soal secara asinkron sebelum tombol mulai aktif; selama permainan,
  soal yang sudah dimuat dipakai dari memori.

Contoh menambahkan soal:

```dart
await repository.insertQuestion(
  const Question(
    1,
    'What is the opposite of "hot"?',
    ['Cold', 'Warm', 'Dry'],
    'Cold',
    '"Cold" is the opposite of "hot".',
  ),
);
```

SQLite memakai `sqflite` pada Android/iOS, FFI pada Windows/Linux, dan
SQLite WASM dengan penyimpanan IndexedDB pada web. Aset WASM dan worker sudah
disiapkan di `web/`; jalankan ulang perintah ini setelah memperbarui paket web:

```powershell
dart run sqflite_common_ffi_web:setup
```

## Pengujian

```powershell
flutter test
flutter analyze
```
"# Game-flutter-run" 
