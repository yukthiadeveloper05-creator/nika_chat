# Nika Chat 🤖✨

A premium AI chat assistant mobile app built with **Flutter** — featuring a sleek, modern UI with dark/light mode, real-time message persistence via **Supabase**, and a polished conversational experience across Android, iOS, and Web.

---

## 🚀 Features

- 💬 **AI Chat Interface** — Clean, intuitive chat UI powered by the "Nika" assistant
- 🌗 **Dark & Light Mode** — Fully themed with smooth toggle support
- ☁️ **Supabase Backend** — Messages and chats are persisted in real-time to a PostgreSQL database
- ✏️ **Edit Messages** — Tap to edit any sent message inline
- 😄 **Emoji Reactions** — React to any message with emoji
- 📤 **Share Conversations** — Export and share your chat history
- ⌨️ **Typing Indicator** — Animated indicator while Nika is "thinking"
- 🎨 **Premium Design** — Glassmorphism, gradient bubbles, Google Fonts (Inter), micro-animations

---

## 🛠️ Tech Stack

| Technology | Role |
|---|---|
| Flutter (Dart) | Cross-platform UI framework |
| Supabase | Backend-as-a-Service (auth, database) |
| Provider | State management |
| Google Fonts | Typography (Inter) |
| flutter_markdown | Markdown rendering in responses |
| share_plus | Share conversation export |

---

## 📁 Project Structure

```
lib/
├── main.dart
└── src/
    ├── models/          # Data models (ChatMessage)
    ├── providers/       # Theme state management
    ├── screens/         # App screens (Home, Chat, Profile, Help)
    ├── services/        # Supabase API service
    ├── theme/           # Design system & tokens
    └── widgets/         # Reusable UI components
```

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK `^3.7.2`
- A [Supabase](https://supabase.com) project with `messages` and `chats` tables

### Run Locally

```bash
flutter pub get
flutter run
```

---

## 📄 License

This project is private and not published to pub.dev.
