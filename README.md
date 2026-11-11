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

## Engine dan aset game

Renderer dan animasi runner memakai Flame; logika soal dan input tetap berada
di Flutter. Efek suara memakai Flame Audio. Paket aset yang digunakan:

- [Kenney Platformer Pack Redux (GitHub mirror)](https://github.com/itsgreggreg/platformer-pack-redux):
  animasi karakter, CC0; lisensi disertakan.
- [Kenney Background Elements Remastered](https://kenney.nl/assets/background-elements-redux):
  awan dan pohon, CC0.
- [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds):
  efek UI, koin, dan tabrakan, CC0.
- [Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka):
  font game, SIL Open Font License.

Asset diunduh melalui CLI dan hanya file yang dipakai yang dibundel. Salinan
lisensi ada di `assets/licenses/`.
"# Game-flutter-run" 
