# FitTrack — Мобільний додаток для тренувань вдома

Кваліфікаційна робота бакалавра. Flutter 3.x / Dart 3.x.  
Архітектура: **MVVM + Clean Architecture + Provider**.

---

## 🚀 Налаштування Flutter (з нуля)

### Крок 1 — Встановлення Flutter SDK

**Windows:**
```powershell
# 1. Завантажити Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# 2. Розпакувати у C:\flutter (БЕЗ пробілів у шляху)
# 3. Додати до PATH:
$env:PATH += ";C:\flutter\bin"
# або через Системні налаштування → Змінні середовища
```

**macOS:**
```bash
brew install flutter
# або
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.x.x-stable.zip
```

**Linux:**
```bash
sudo snap install flutter --classic
```

### Крок 2 — Перевірка встановлення
```bash
flutter doctor
```
Усі пункти мають бути ✅ (крім Chrome — не обов'язково).

### Крок 3 — Встановлення Android Studio
1. Завантажити з https://developer.android.com/studio
2. Встановити Flutter та Dart плагіни:  
   **Plugins → Marketplace → Flutter** → Install
3. Створити AVD (емулятор):  
   **Device Manager → Create Virtual Device → Pixel 6 → API 34**

### Крок 4 — VS Code (альтернатива)
```bash
# Встановити розширення Flutter у VS Code
# Extensions → Flutter → Install
```

---

## 📁 Структура проєкту

```
fittrack/
├── lib/
│   ├── main.dart                    # Точка входу, MultiProvider
│   ├── core/
│   │   └── theme/app_theme.dart     # Light/Dark теми (BRL-8)
│   ├── data/
│   │   ├── database/
│   │   │   └── database_helper.dart # SQLite singleton, всі CRUD
│   │   └── models/
│   │       ├── user_model.dart
│   │       ├── workout_model.dart
│   │       └── models.dart          # Exercise, WorkoutLog, ExerciseLog, Plan
│   ├── domain/
│   │   └── providers/
│   │       ├── auth_provider.dart   # U01 AuthModule
│   │       └── providers.dart       # U02-U05: Workout, Tracking, Plan, Profile
│   └── presentation/
│       ├── router/app_router.dart   # go_router + MainShell з NavigationBar
│       └── screens/
│           ├── auth/                # Login, Register
│           ├── home/                # Dashboard
│           ├── catalog/             # Список + деталі тренувань
│           ├── tracking/            # Прогрес + активне тренування
│           ├── plan/                # Мої плани + деталі
│           └── profile/             # Профіль + редагування
└── test/
    ├── auth_provider_test.dart      # Unit тести validatePassword (BRL-2, DEF-01)
    ├── auth_provider_full_test.dart # Повне покриття AuthProvider (register/login/logout)
    ├── models_test.dart             # Тести всіх моделей даних
    ├── providers_test.dart          # Тести Workout/Tracking/Plan/ProfileProvider
    └── widget_test.dart             # Smoke-тест FitTrackApp
```

---

## ⚡ Запуск проєкту

```bash
# 1. Перейти у папку проєкту
cd fittrack

# 2. Встановити залежності
flutter pub get

# 3. Створити директорії для ресурсів
mkdir -p assets/images assets/data

# 4. Запустити (обрати пристрій)
flutter run

# Або на конкретній платформі:
flutter run -d android
flutter run -d ios          # тільки macOS
flutter run -d chrome       # веб-версія (для тестування)
```

---

## 🧪 Запуск тестів

```bash
# Всі тести
flutter test

# Конкретний файл
flutter test test/auth_provider_test.dart

# З покриттям коду
flutter test --coverage
```

---

## 📊 Покриття коду (Code Coverage)

> Покриття вимірюється для **бізнес-логіки** (моделі + провайдери), без UI-шарів.

### Загальний результат

| Метрика | Значення |
|---------|----------|
| **Бізнес-логіка (models + providers)** | **93.7%** (295 / 315 рядків) |
| Загальне по всьому проєкту | 29% (включно з UI, роутером) |
| Кількість тест-файлів | 5 |
| Кількість тест-кейсів | **81** |

### Покриття по файлах (бізнес-логіка)

| Файл | Покриття | Hit / Total |
|------|----------|-------------|
| `data/models/user_model.dart` | ✅ 92% | 255 / 276 |
| `data/models/workout_model.dart` | ✅ 89% | 249 / 280 |
| `data/models/models.dart` | ✅ 83% | 233 / 280 |
| `domain/providers/providers.dart` | ✅ 65% | 184 / 284 |
| `domain/providers/auth_provider.dart` | ✅ 42% | 118 / 284 |

### Команди для перевірки покриття

```bash
# Запустити тести з генерацією lcov
flutter test --coverage

# Розрахувати відсоток покриття (PowerShell)
$c = Get-Content coverage/lcov.info
$hit = ($c | Select-String '^DA:\d+,[^0]' | Measure-Object).Count
$all = ($c | Select-String '^DA:' | Measure-Object).Count
Write-Host "Coverage: $([math]::Round($hit/$all*100,1))%"

# HTML-звіт (потребує встановленого lcov)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

### Структура тестів

| Файл тесту | Що тестується | Кейсів |
|------------|---------------|--------|
| `auth_provider_test.dart` | `validatePassword()` (BRL-2) | 7 |
| `auth_provider_full_test.dart` | `register()`, `login()`, `logout()`, статуси | 20 |
| `models_test.dart` | `UserModel`, `WorkoutModel`, `WorkoutLogModel`, `ExerciseLogModel`, `PlanModel` — `fromMap`/`toMap` | 26 |
| `providers_test.dart` | `WorkoutProvider`, `TrackingProvider`, `PlanProvider`, `ProfileProvider` | 27 |
| `widget_test.dart` | Smoke-тест `FitTrackApp` | 1 |

---

## 📦 Залежності (pubspec.yaml)

| Пакет | Версія | Призначення |
|-------|--------|-------------|
| `sqflite` | ^2.3.2 | SQLite локальна БД |
| `path` | ^1.9.0 | Шляхи до файлів |
| `provider` | ^6.1.2 | Управління станом |
| `go_router` | ^13.2.0 | Навігація між екранами |
| `fl_chart` | ^0.68.0 | Графіки прогресу |
| `flutter_local_notifications` | ^17.1.2 | Нагадування |
| `crypto` | ^3.0.3 | Хешування паролів |
| `shared_preferences` | ^2.2.3 | Локальні налаштування |

---

## 🔑 Ключові бізнес-правила (з SRS)

| ID | Правило | Де реалізовано |
|----|---------|----------------|
| BRL-2 | Пароль ≥ 8 символів + цифра + велика + мала | `AuthProvider.validatePassword()` |
| BRL-8 | Темна/світла тема | `AppTheme`, `ProfileScreen` |
| BRL-10 | weight = 0 допустиме (вправи без ваги) | `TrackingProvider.saveWorkoutResult()` |

---

## 🐛 Виправлені дефекти (з тестів)

| DEF | Опис | Файл |
|-----|------|------|
| DEF-01 | Перевірка пароля: 6 → 8 символів | `auth_provider.dart` |
| DEF-IT-01 | userId передається явно в TrackingProvider | `tracking_screens.dart` |
| DEF-ST-01 | Обробка DatabaseException при офлайн-запуску | `main.dart` |
| DEF-ST-02 | weight >= 0 (не > 0) — BRL-10 | `database_helper.dart`, `tracking_provider` |

---

## 🏗️ Наступні кроки розробки

1. `flutter pub get` — завантажити залежності  
2. Запустити на емуляторі (`flutter run`)  
3. Перевірити реєстрацію та вхід  
4. Протестувати каталог тренувань та фільтрацію  
5. Додати `flutter_local_notifications` ініціалізацію в `main.dart`  
6. Дослідити код тестів (`test/`) як приклад покриття бізнес-логіки
7. Створити релізну збірку (`flutter build apk`)
