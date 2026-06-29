# Speak12

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

> **Sentence-first English learning app for Turkish speakers.**  
> Instead of memorizing isolated words, Speak12 teaches you real sentences — so you learn grammar, vocabulary, and context all at once.

---

## Philosophy

Most language apps teach words. Speak12 teaches **sentences**.

When you learn *"Can you help me, please?"* — you've already learned vocabulary, grammar structure, and when to use it. That's 3x the value of memorizing the word "help" alone.

---

## Features

- **Sentence-first learning** — 200 to 1000+ curated sentences per level
- **3 learning modes** — Flashcard, Quiz, and Spaced Repetition (SRS)
- **Smart review system** — SRS algorithm reminds you before you forget
- **Daily streak tracking** — stay consistent, build a habit
- **Daily goal** — set your own pace (e.g. 10 sentences/day)
- **Pronunciation audio** — hear every sentence spoken aloud
- **Progress statistics** — track your growth over time
- **Daily reminders** — push notifications to keep you on track
- **Dark mode** — easy on the eyes
- **Fully offline** — no internet required after install

---

## Levels & Sentence Counts

| Level | Description | Sentences |
|-------|-------------|-----------|
| A1 | Complete beginner | ~200 |
| A2 | Elementary | ~300 |
| B1 | Intermediate | ~500 |
| B2 | Upper-Intermediate | ~700 |
| C1 | Advanced | ~900 |
| C2 | Near-native | ~1000+ |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Local Database | Isar |
| Audio | just_audio |
| Notifications | flutter_local_notifications |
| Animations | flutter_animate |

---

## Project Structure

```
lib/
├── main.dart
├── screens/
│   ├── onboarding/       # Level selection, daily goal setup
│   ├── home/             # Dashboard, streak, quick start
│   ├── learn/            # Flashcard learning screen
│   ├── quiz/             # 4-choice quiz screen
│   ├── stats/            # Progress & streak calendar
│   └── settings/         # Notifications, theme, goals
├── models/
│   ├── sentence.dart     # Sentence data model
│   └── user_progress.dart
├── data/
│   ├── a1_sentences.dart
│   ├── a2_sentences.dart
│   └── ...
├── providers/            # Riverpod state providers
└── widgets/              # Shared reusable widgets
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.x`
- Dart SDK `^3.x`
- Android Studio or VS Code with Flutter extension

### Run the app

```bash
git clone https://github.com/mrezan12/speak12.git
cd speak12
flutter pub get
flutter run
```

---

## Branching Strategy

This project follows a Gitflow-inspired workflow:

```
main          ← Stable, production-ready code
  └── develop ← Integration branch
        └── feature/T02-folder-structure
        └── feature/T03-add-packages
        └── feature/T04-theme-system
        ...
```

- All feature work happens in task branches (`feature/TXX-description`)
- Task branches are merged into `develop`
- `develop` is merged into `main` at the end of each phase

---

## Roadmap

### Phase 1 — Foundation
- [x] T01: GitHub repo setup
- [ ] T02: Folder structure
- [ ] T03: Add packages (Riverpod, Isar, etc.)
- [ ] T04: Theme & color system

### Phase 2 — Data Layer
- [ ] T05: Data models (Sentence, UserProgress)
- [ ] T06: A1 sentence data (~200 sentences)
- [ ] T07: A2 sentence data (~300 sentences)
- [ ] T08: B1 sentence data (~500 sentences)
- [ ] T09: Database layer (Isar)

### Phase 3 — Screens
- [ ] T10: Onboarding screen
- [ ] T11: Home screen
- [ ] T12: Flashcard screen
- [ ] T13: Quiz screen
- [ ] T14: Sentence detail screen
- [ ] T15: Stats screen
- [ ] T16: Settings screen

### Phase 4 — Features
- [ ] T17: Spaced Repetition system
- [ ] T18: Audio integration
- [ ] T19: Daily notifications
- [ ] T20: Animations

### Phase 5 — Release
- [ ] T21: App icon & splash screen
- [ ] T22: Play Store preparation

---

## License

This project is licensed under the MIT License.
