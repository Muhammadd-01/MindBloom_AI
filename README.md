# MindBloom - Behavioral AI & Positivity Companion

MindBloom is a cutting-edge mobile application designed to foster mental well-being, behavioral change, and emotional intelligence through the power of Advanced AI and reflective journaling.

## 🌟 Vision
To empower individuals with a daily companion that transforms raw emotional data into actionable insights, promoting a positive mindset and personal growth.

---

## 🚀 Key Features

### 1. Neural Reflection Engine
Captures your thoughts through **text journaling** or **voice recordings**. Our advanced AI models (Google Gemini) analyze yours entries in real-time to identify:
- **Sentiment Analysis**: Understanding the underlying emotion (Positive, Refective, or Difficult).
- **Tone Detection**: Identifying how you sound (Empathetic, Analytical, Optimistic, etc.).
- **Positivity Score**: A numerical representation of your daily emotional state.

### 2. Smart Insights Dashboard
A personalized command center that visualizes your growth:
- **Daily Performance**: Real-time positivity scores and emotional breakdowns.
- **Weekly & Monthly Trends**: Interactive charts showing your emotional journey over time.
- **Activity Streaks**: Gamified mechanics (Levels and Streaks) to encourage consistent reflection.

### 3. AI Behavioral Coach
An empathetic, AI-powered coach that provides personalized feedback and suggestions based on your specific entries. It offers:
- **Cognitive Reframing**: Helping you look at difficult situations from a growth perspective.
- **Islamic-Centered Guidance**: Optional culturally-nuanced support for spiritual well-being.
- **Daily Prompts**: Context-aware questions to trigger deep reflection.

### 4. Interactive Report Cards
Each reflection generates a detailed "Report" including:
- **Emotional Summary**: A concise breakdown of your entry's impact.
- **Behavioral Tips**: Practical steps to improve your mood or maintain positivity.
- **AI-Driven Suggestions**: 3-4 specific actions you can take TODAY.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform performance)
- **State Management**: [Riverpod 2.4.x](https://riverpod.dev/) (Predictable and testable state)
- **Backend/Auth**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Hosting)
- **Cloud Storage**: [Supabase](https://supabase.com/) (High-performance media storage for avatars and journal attachments)
- **Intelligence**: [Google Gemini Pro](https://deepmind.google/technologies/gemini/) (Large Language Model for emotional analysis)
- **Security**: Environment variables (dotenv) and Biometric Authentication.

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
- **Media Privacy**: Images are stored in private Supabase buckets with authenticated access.
- **Environment Safety**: Sensitive API keys and Supabase credentials are obfuscated via `.env` files and never exposed to version control.

---

## 📖 How to Run

1.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Configuration**:
    - Create a `.env` file in the root directory.
    - Add `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GEMINI_API_KEY`.
3.  **Run Application**:
    ```bash
    flutter run
    ```

---

*MindBloom — Grow your mind, change your world.*
