# FeelU: AI + Braille-Vibration Communication for Deaf-Blind Users

## 📘 Overview

**FeelU** is an innovative Android app designed to empower **deaf-blind individuals** with real-time communication and environmental awareness through:

- 🧠 **On-device AI**: Image and speech recognition without internet
- 🔡 **Braille Input**: Piano-style 6-dot entry
- 📳 **Haptic Output**: Vibration-based Braille you can feel

[User Guide](./USER_GUIDE.md)  
[Vibro-Braille System Details](./VIBRO_BRAILLE_GUIDE.md)
[Development Guide](./DEVELOPMENT.md)

## 🧩 Core Features

- 🎹 **Braille Input**: Two-step, piano-style 6-dot keyboard
- 📳 **Vibro-Braille Output**: Custom dual-phase vibration patterns for Braille characters
- 📷 **AI Camera Mode**: Detects and describes nearby objects via Braille vibration
- 🗣️ **Speech-to-Braille**: Converts nearby speech into tactile Braille output
- 🤖 **Q&A Mode**: Enter questions via Braille; receive answers via vibration
- 📄 **Fullscreen Braille Reader**: Slide/tap to read long responses
- ✋ **Gesture Navigation**: Simple 3-finger swipes to switch modes

## 🚀 Quick Start

1. **Install and launch** the [APK](https://github.com/nullhtp/feelu/releases)
2. On first run, the app auto-initializes:
   - On-device AI (no cloud required)
   - Vibration + audio models
3. Rotate device to **landscape** (auto-locked)
4. Starts in **Braille Input** mode

## 🧭 Mode Navigation

| Mode | Gesture | Purpose |
|------|---------|---------|
| **Braille Input** | Default | Enter text in Braille |
| **Camera Mode** | Swipe **left** | Recognize surroundings |
| **Speech Mode** | Swipe **right** | Transcribe speech to Braille |
| **Q&A Mode** | Swipe **up** | Ask AI questions via Braille |
| **Text-to-Speech** | Swipe **down** | Speak your input aloud |
| **Fullscreen Reader** | Auto-opens | Read full responses via swipe/tap |

## 📳 How Vibro-Braille Works

Each Braille character (6-dot) is split into two 3-dot phases, encoded as binary and rendered as distinct vibration sequences.

### 🔢 Encoding Example

| Character | Dots | Binary | Vibration Pattern |
|-----------|------|--------|-------------------|
| A         | 1    | 100000 | Weak pulse, pause |
| B         | 1–2  | 110000 | Medium pulse, pause |
| C         | 1–4  | 100100 | Weak pulse, Weak pulse |

### 🌀 Two-Phase Output

1. **Phase 1**: Dots 1–2–3 → Pattern A  
2. **Pause**: 200ms  
3. **Phase 2**: Dots 4–5–6 → Pattern B

📘 [View Full Vibration Encoding Spec](./VIBRO_BRAILLE_GUIDE.md)

## 🤖 AI Capabilities

| Function | Description |
|----------|-------------|
| **Camera Recognition** | Describes all visible objects via Braille |
| **Speech Recognition** | Condenses speech into key ideas |
| **Q&A Mode** | Answers natural language queries from Braille input |
| **Text Expansion** | Converts keywords into full, coherent responses |
| **100% Offline** | No internet or server dependencies after setup |

## 🛠️ Requirements

| Category | Detail |
|----------|--------|
| Device | Android with vibration motor, microphone, and camera |
| Storage | 2–4 GB free for local models |
| Permissions | Camera, mic, vibration, storage, TTS, STT, screen lock |
| Setup | One-time internet required for model download |

✅ Fully tested on Pixel 7

## 🧪 Troubleshooting

| Problem | Solution |
|---------|----------|
| App won’t start | Verify permissions and model initialization |
| No vibration | Check system vibration settings |
| Braille input issues | Ensure correct 1st/2nd half tap sequence |
| Poor speech recognition | Reduce noise, speak clearly |
| Camera not working | Ensure permissions and lighting are OK |

📖 [More Help in User Guide →](./USER_GUIDE.md#troubleshooting)

## 🔮 Future Features

- 🔤 Multilingual Braille support
- ⏱ Rhythmic punctuation patterns
- 😃 Emoji-to-vibration encoding
- 💍 Wearables: Ring or band-style haptic devices
- 🌐 Pattern sharing between users
- 🤖 AI assistant with Android device control
- 📸 Live camera chat interface
- 🕓 Conversation history
- 🎛 Swipe-based virtual input screen

## 🤝 Contribute

We welcome contributors passionate about accessibility:

1. Fork the repository
2. Read [Development guide](./DEVELOPMENT.md)
2. Open issues or feature requests
3. Submit pull requests for review

Together, let’s make communication universal.