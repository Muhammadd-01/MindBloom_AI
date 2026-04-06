import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

/// Service for communicating with MindBloom and Backend
class ApiService {
  static const String _baseUrl = 'http://localhost:8000';
  
  // ── Gemini Configuration ──
  static final String _geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _geminiKey,
  );

  /// Analyze text input using Real Gemini AI for presentation
  static Future<AnalysisResult> analyzeText({
    required String text,
    required String userId,
    required String inputType,
  }) async {
    try {
      if (kDebugMode) print('🚀 ApiService: Starting Real MindBloom AI Analysis...');
      
      final prompt = '''
        Analyze the following user input for a behavioral positivity app.
        Input: "$text"
        
        Return a JSON object with:
        "positivityScore": (integer 1-100),
        "sentiment": ("positive", "neutral", "negative"),
        "tone": ("calm", "stressed", "joyful", "reflective", "anxious", "motivated", "sad"),
        "keywords": (list of 3 key emotional words),
        "summary": (one sentence analysis)
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        // Find JSON in response (Gemini sometimes adds markdown blocks)
        final jsonStr = response.text!.substring(
          response.text!.indexOf('{'),
          response.text!.lastIndexOf('}') + 1,
        );
        final data = jsonDecode(jsonStr);
        
        if (kDebugMode) print('✅ MindBloom Analysis Success: ${data['sentiment']}');

        return AnalysisResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          inputText: text,
          inputType: inputType,
          positivityScore: data['positivityScore'] ?? 50,
          sentiment: data['sentiment'] ?? 'neutral',
          tone: data['tone'] ?? 'calm',
          keywords: List<String>.from(data['keywords'] ?? []),
          analyzedAt: DateTime.now(),
        );
      }
      throw Exception('Gemini returned empty response');
    } catch (e) {
      if (kDebugMode) print('⚠️ MindBloom AI Error: $e. Falling back to Smart Simulation.');
      // Fallback: simulate analysis locally for demo stability
      return _simulateAnalysis(text, userId, inputType);
    }
  }

  /// Get smart feedback based on analysis (Gemini implementation)
  static Future<List<FeedbackItem>> getFeedback({
    required String sentiment,
    required String tone,
    required int score,
  }) async {
    try {
      final prompt = 'Generate 3 psychological positivity tips for a person who is feeling $sentiment and $tone with a positivity score of $score. Include one Islamic wisdom (Quran/Hadith) if relevant. Return JSON list of {type, title, description, icon}.';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final jsonStr = response.text!.substring(
          response.text!.indexOf('['),
          response.text!.lastIndexOf(']') + 1,
        );
        final List<dynamic> data = jsonDecode(jsonStr);
        return data.map((item) => FeedbackItem(
          type: item['type'] ?? 'reflection',
          title: item['title'] ?? 'Positivity Note',
          description: item['description'] ?? '',
          icon: item['icon'] ?? '💡',
        )).toList();
      }
      throw Exception();
    } catch (e) {
      return _simulateFeedback(sentiment, score);
    }
  }

  /// AI chatbot coach powered by MindBloom
  static Future<String> chatWithCoach(String message) async {
    try {
      final prompt = 'You are MindBloom Coach. Be empathetic, Islamic-centered where appropriate, and focus on behavioral change. User says: "$message"';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _simulateChatResponse(message);
    } catch (e) {
      return _simulateChatResponse(message);
    }
  }

  /// AI Logic for Gaming: Generate a dynamic challenge
  static Future<Map<String, dynamic>> generateAIChallenge() async {
    try {
      const prompt = 'Create a "Positivity Micro-Challenge" for a user. Return JSON: {title, task, points, difficulty}. Example: {title: "Gratitude Text", task: "Send a thank you note to someone", points: 50, difficulty: "Easy"}';
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonStr = response.text!.substring(
          response.text!.indexOf('{'),
          response.text!.lastIndexOf('}') + 1,
        );
      return jsonDecode(jsonStr);
    } catch (e) {
      return {
        'title': 'Mindful Minute',
        'task': 'Close your eyes and focus on your breath for 60 seconds.',
        'points': 30,
        'difficulty': 'Easy'
      };
    }
  }

  // ── Local Simulation (Offline / Demo Mode) ──
  // These stay as robust fallbacks for the presentation

  /// Simulate NLP analysis locally using simple heuristics
  static AnalysisResult _simulateAnalysis(
    String text,
    String userId,
    String inputType,
  ) {
    final lowerText = text.toLowerCase();
    
    // ── Sentiment Keywords ──
    final positiveWords = [
      'happy', 'great', 'good', 'love', 'blessed', 'grateful', 'joy', 'peace', 'smile',
      'alhamdulillah', 'mashallah', 'success', 'strong', 'excited', 'wonderful',
    ];
    final negativeWords = [
      'sad', 'bad', 'angry', 'hate', 'stressed', 'anxious', 'worried', 'tired', 'pain',
      'frustrated', 'upset', 'lonely', 'awful', 'worst', 'fear',
    ];

    // ── Contextual Keywords ──
    final contextKeywords = {
      'work': ['office', 'boss', 'meeting', 'deadline', 'job', 'career', 'project', 'work'],
      'health': ['sleep', 'tired', 'sick', 'pain', 'workout', 'energy', 'health', 'eating'],
      'social': ['family', 'friend', 'partner', 'parents', 'wife', 'husband', 'children', 'talk'],
      'academic': ['study', 'exam', 'college', 'school', 'test', 'result', 'grade', 'learn'],
      'spiritual': ['prayer', 'allah', 'mosque', 'spirit', 'faith', 'soul', 'god'],
    };

    int posCount = 0;
    int negCount = 0;
    List<String> detectedKeywords = [];
    String detectedContext = 'general';

    // Sentiment check
    for (final word in positiveWords) {
      if (lowerText.contains(word)) posCount++;
    }
    for (final word in negativeWords) {
      if (lowerText.contains(word)) negCount++;
    }

    // Context check
    for (final entry in contextKeywords.entries) {
      for (final word in entry.value) {
        if (lowerText.contains(word)) {
          detectedContext = entry.key;
          detectedKeywords.add(word);
          break;
        }
      }
    }

    // Calculate score (0-100)
    int score;
    String sentiment;
    String tone;

    if (posCount > negCount) {
      score = 65 + (posCount * 5).clamp(0, 30);
      sentiment = 'positive';
      tone = posCount > 3 ? 'joyful' : 'calm';
    } else if (negCount > posCount) {
      score = 35 - (negCount * 5).clamp(0, 30);
      sentiment = 'negative';
      tone = negCount > 3 ? 'stressed' : 'reflective';
    } else {
      score = 50;
      sentiment = 'neutral';
      tone = 'observational';
    }

    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      inputText: text,
      inputType: inputType,
      positivityScore: score.clamp(5, 98),
      sentiment: sentiment,
      tone: tone,
      keywords: detectedKeywords.isEmpty ? ['awareness'] : detectedKeywords.take(5).toList(),
      analyzedAt: DateTime.now(),
    );
  }

  /// Simulate feedback locally with Context Awareness
  static List<FeedbackItem> _simulateFeedback(String sentiment, int score) {
    if (score < 40) {
      return [
        FeedbackItem(
          type: 'breathing',
          title: 'Immediate Relief: 4-7-8 Breathing',
          description: 'It sounds like things are heavy. Try inhaling for 4s, holding for 7s, and exhaling for 8s to reset your nervous system.',
          icon: '🌬️',
        ),
        FeedbackItem(
          type: 'islamic',
          title: 'Divine Promise',
          description: 'Allah knows your struggle. "So truly where there is hardship, there is also ease." (94:5)',
          quranVerse: '"Verily, with every difficulty there is relief." (94:5)',
          icon: '🕌',
        ),
        FeedbackItem(
          type: 'action',
          title: 'Tiny Win Strategy',
          description: 'When overwhelmed, focus on one small 2-minute task. Completing it will trigger a small dopamine hit to help you keep going.',
          icon: '🎯',
        ),
      ];
    } else if (score > 70) {
      return [
        FeedbackItem(
          type: 'habit',
          title: 'Positivity Ripple',
          description: 'Your energy is high! Send a quick "Thank You" text to someone you care about to amplify this feeling.',
          icon: '🌊',
        ),
        FeedbackItem(
          type: 'growth',
          title: 'Flow State Optimization',
          description: 'You are in a great headspace. Use this momentum to tackle your most creative or challenging task of the day.',
          icon: '⚡',
        ),
        FeedbackItem(
          type: 'islamic',
          title: 'Gratitude Increase',
          description: 'Alhamdulillah! "If you are grateful, I will surely increase my favor upon you." (14:7)',
          icon: '🕌',
        ),
      ];
    } else {
      return [
        FeedbackItem(
          type: 'reflection',
          title: 'Mid-Day Check-in',
          description: 'You are maintaining a steady balance. Take 2 minutes to identify one "Micro-Joy" you experienced today.',
          icon: '⚖️',
        ),
        FeedbackItem(
          type: 'physical',
          title: 'Stretching Break',
          description: 'A 60-second stretch can re-oxygenate your brain and improve your neutral baseline into a positive one.',
          icon: '🧘',
        ),
        FeedbackItem(
          type: 'islamic',
          title: 'Prophetic Wisdom',
          description: '"Even a smile is charity." Keep your heart light as you move through your day.',
          icon: '🕌',
        ),
      ];
    }
  }

  /// Simulate AI chatbot response with Keyword Sensitivity
  static String _simulateChatResponse(String message) {
    final lower = message.toLowerCase();
    
    if (lower.contains('work') || lower.contains('office') || lower.contains('deadline')) {
      return "I hear you on the work front. 💼 Deadlines can be incredibly draining. "
          "Try to break your next hour into 25-minute 'Focus Cycles'. It makes the 'mountain' feel like 'steps'. "
          "You've handled busy periods before—you've got this!";
    }
    
    if (lower.contains('study') || lower.contains('exam') || lower.contains('test')) {
      return "Exam season is tough! 📚 Remember that your worth isn't defined by a single score. "
          "Focus on consistent effort, and don't forget to stay hydrated. "
          "Would you like me to suggest a quick focus-boosting breathing exercise?";
    }

    if (lower.contains('tired') || lower.contains('sleep') || lower.contains('exhausted')) {
      return "Exhaustion is your body's way of asking for a reset. 🔋 "
          "Try to step away from screens for 15 minutes before you actually sleep. "
          "Rest is a productive activity—don't feel guilty for taking it!";
    }

    if (lower.contains('family') || lower.contains('friend') || lower.contains('love')) {
      return "Connections are the backbone of our positivity. 🤝 "
          "Even if things are complex, focusing on a single positive shared memory can shift your perspective. "
          "How can I help you navigate this relationship today?";
    }

    if (lower.contains('stressed') || lower.contains('anxious')) {
      return "I understand you're feeling stressed. 🧘 Try this: List 3 things you CAN control right now, and 3 things you CANNOT. "
          "Focus only on the first list. You'll feel much more centered. "
          "I'm right here with you.";
    }

    if (lower.contains('happy') || lower.contains('great') || lower.contains('good')) {
      return "That's wonderful to hear! 🌟 Capture this feeling. "
          "What exactly made this moment good? Identifying the specific 'trigger' helps you recreate it later. "
          "Keep that momentum going!";
    }

    return "Thank you for sharing your thoughts with me. 🌿 "
        "Every reflection makes our AI smarter at understanding your unique positivity patterns. "
        "Would you like to talk more about your day, or shall we try a quick mood-boosting exercise?";
  }

  // ── Supabase Image Upload (via FastAPI) ──

  /// Upload an image to Supabase Storage via FastAPI and get back the public URL.
  /// The URL is then stored in Firestore (e.g., user.photoUrl or analysis.imageUrl).
  ///
  /// [imageBytes] - raw bytes of the image file
  /// [fileName] - original filename (e.g., 'photo.jpg')
  /// [userId] - Firebase Auth UID (used as folder name in Supabase)
  /// [bucket] - 'profile-images' or 'journal-attachments'
  static Future<String?> uploadImage({
    required List<int> imageBytes,
    required String fileName,
    required String userId,
    String bucket = 'journal-attachments',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload-image'),
      );

      request.fields['user_id'] = userId;
      request.fields['bucket'] = bucket;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String; // Public Supabase URL
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      // Return null on failure — caller should handle gracefully
      return null;
    }
  }

  /// Delete an image from Supabase Storage via FastAPI.
  static Future<bool> deleteImage({
    required String bucket,
    required String path,
    required String userId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'DELETE',
        Uri.parse('$_baseUrl/delete-image'),
      );

      request.fields['bucket'] = bucket;
      request.fields['path'] = path;
      request.fields['user_id'] = userId;

      final streamedResponse = await request.send();
      return streamedResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

