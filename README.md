# MindBloom - Behavioral AI & Positivity Companion

MindBloom is a cutting-edge mobile application designed to foster mental well-being, behavioral change, and emotional intelligence through the power of Advanced AI and reflective journaling. It serves as an offline-capable, clinically-informed empathetic digital psychiatrist.

## 🌟 Vision
To empower individuals with a daily companion that transforms raw emotional data into actionable insights, promoting a positive mindset and personal growth using established psychological frameworks.

---

## 🚀 Key Features

### 1. Neural Reflection Engine
Captures your thoughts through **text journaling** or **voice recordings**. Our advanced local AI expert system and cloud AI models analyze your entries in real-time to identify:
- **Sentiment Analysis**: Understanding the underlying emotion (Positive, Reflective, or Difficult).
- **Tone Detection**: Identifying how you sound using Plutchik emotional frameworks.
- **Positivity Score**: A numerical representation of your daily emotional state.

### 2. Clinical Expert System
MindBloom integrates a local psychological "Expert System" utilizing:
- **CBT (Cognitive Behavioral Therapy)** & **DBT (Dialectical Behavior Therapy)** frameworks to perform precise sentiment analysis on journals, voice notes, and chat.
- **Guardian Mode (Beta)**: Localized sentiment monitoring designed to proactively detect and intervene during emotional distress or high anxiety, all handled privately on-device without exposing your data to third-party listeners.

### 3. Smart Insights Dashboard
A personalized command center that visualizes your growth:
- **Daily Performance**: Real-time positivity scores and emotional breakdowns.
- **Weekly & Monthly Trends**: Interactive charts showing your emotional journey over time.
- **Activity Streaks**: Gamified mechanics (Levels and Streaks) to encourage consistent reflection.

### 4. AI Behavioral Coach
An empathetic, AI-powered coach that provides personalized feedback and suggestions based on your specific entries. It offers:
- **Cognitive Reframing**: Helping you look at difficult situations from a growth perspective.
- **Islamic-Centered Guidance**: Optional culturally-nuanced support for spiritual well-being.
- **Interactive Report Cards**: Detailed breakdown of emotional impact and AI-driven daily actions.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform performance)
- **State Management**: [Riverpod 2.6.x](https://riverpod.dev/) (Predictable and testable state)
- **Backend/Auth**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Hosting)
- **Intelligence**: 
  - Local Expert AI System (Offline CBT/DBT frameworks)
  - Cloud AI (Large Language Model for emotional analysis)
- **Security**: Environment variables (dotenv) and Biometric Authentication. Local-first Guardian processing.

---

## 💎 Premium Ecosystem (Tiers)

MindBloom uses a multi-tier subscription model to ensure sustainability and quality:

1.  **Seedling (Free)**: 3 Reflections per day. Essential sentiment analysis.
2.  **Bloom (Pro)**: 15 Reflections per day. Advanced tone detection.
3.  **Forest (Elite)**: Unlimited reflections. Full AI Coach access. Voice-to-text integration.

> [!TIP]
> **Presentation Note**: We have implemented a "Gold Pass" logic for the presentation account `GeniusAISquad@gmail.com`. This account automatically unlocks the **Forest (Elite)** tier to demonstrate the app's full capabilities without restrictions.

---

## 🔒 Security & Privacy

- **Data Encryption**: All personal reflections are stored securely in Firestore with strict RLS (Row Level Security).
- **Offline-First Guardian**: Distress monitoring and initial NLP sentiment analysis are processed locally on-device, ensuring absolute privacy for sensitive mental health states.
- **Environment Safety**: Sensitive API keys are obfuscated via `.env` files and never exposed to version control.

---

## 📖 How to Run

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Configuration**:
    - Create a `.env` file in the root directory.
    - Add relevant API keys and configuration for Firebase.
3.  **Run Application**:
    ```bash
    flutter run
    ```

---

*MindBloom — Grow your mind, change your world.*
