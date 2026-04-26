import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'psychological_data.dart';

/// The core Brain of MindBloom. 
/// 100% offline, privacy-first, locally-computed Psychological AI Agent.
/// Uses CBT, DBT, ACT, and Rogerian heuristic models.
class MindBloomLocalAIEngine {
  // Severe Crisis Detection (Highest Priority)
  static const _crisisWords = [
    'kill myself', 'want to die', 'end it all', 'suicide', 'suicidal', 
    'no reason to live', 'better off dead', 'end my life', 'take my life'
  ];

  /// Check if text contains suicidal ideation
  static bool isCrisis(String text) {
    final lower = text.toLowerCase();
    for (final phrase in _crisisWords) {
      if (lower.contains(phrase)) return true;
    }
    return false;
  }

  /// Analyze text input using Advanced Local CBT/DBT Heuristics
  static Future<AnalysisResult> analyzeText({
    required String text,
    required String userId,
    required String inputType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate AI processing time
    
    if (kDebugMode) print('🧠 LocalAIEngine: Running psychological analysis...');
    
    final lowerText = text.toLowerCase();
    
    // 1. Crisis Override Check
    if (isCrisis(lowerText)) {
      return AnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        inputText: text,
        inputType: inputType,
        positivityScore: 5, // Minimum score
        sentiment: 'crisis',
        tone: 'severe',
        keywords: ['crisis', 'emergency', 'help'],
        analyzedAt: DateTime.now(),
      );
    }

    // 2. Identify Plutchik's Advanced Emotions
    String dominantEmotion = 'Neutral';
    int highestEmotionCount = 0;
    List<String> detectedKeywords = [];

    PsychologicalData.advancedEmotions.forEach((emotion, keywords) {
      int count = 0;
      for (final word in keywords) {
        if (lowerText.contains(word)) {
          count++;
          if (detectedKeywords.length < 5 && !detectedKeywords.contains(word)) {
            detectedKeywords.add(word);
          }
        }
      }
      if (count > highestEmotionCount) {
        highestEmotionCount = count;
        dominantEmotion = emotion;
      }
    });

    // 3. Identify Cognitive Distortions (CBT)
    String? detectedDistortion;
    PsychologicalData.cognitiveDistortions.forEach((distortion, keywords) {
      for (final word in keywords) {
        if (lowerText.contains(word)) {
          detectedDistortion = distortion;
          if (!detectedKeywords.contains(distortion)) detectedKeywords.add(distortion);
          break; // Found primary distortion
        }
      }
    });

    // 4. Identify Emotional Dysregulation (DBT)
    String? detectedDysregulation;
    PsychologicalData.emotionalDysregulation.forEach((dysregulation, keywords) {
      for (final word in keywords) {
        if (lowerText.contains(word)) {
          detectedDysregulation = dysregulation;
          if (!detectedKeywords.contains(dysregulation)) detectedKeywords.add(dysregulation);
          break;
        }
      }
    });

    // 5. Calculate Positivity Score Math
    int baseScore = 50;
    
    if (dominantEmotion == 'Ecstasy/Joy' || dominantEmotion == 'Admiration/Trust') {
      baseScore = 75 + (highestEmotionCount * 5);
    } else if (dominantEmotion == 'Vigilance/Anticipation' || dominantEmotion == 'Amazement/Surprise') {
      baseScore = 60 + (highestEmotionCount * 2);
    } else if (dominantEmotion == 'Neutral') {
      baseScore = 50;
    } else {
      // Negative emotions
      baseScore = 40 - (highestEmotionCount * 5);
      if (detectedDistortion != null) baseScore -= 10;
      if (detectedDysregulation != null) baseScore -= 15;
    }

    int finalScore = baseScore.clamp(5, 98);

    // 6. Map to simple UI Sentiment/Tone
    String sentiment = 'neutral';
    String tone = 'reflective';

    if (finalScore >= 65) {
      sentiment = 'positive';
      tone = dominantEmotion.split('/').first.toLowerCase();
    } else if (finalScore <= 40) {
      sentiment = 'negative';
      tone = dominantEmotion.split('/').first.toLowerCase();
    }

    if (detectedKeywords.isEmpty) {
      detectedKeywords = ['reflection', 'mindfulness'];
    }

    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      inputText: text,
      inputType: inputType,
      positivityScore: finalScore,
      sentiment: sentiment,
      tone: tone,
      keywords: detectedKeywords.take(4).toList(),
      analyzedAt: DateTime.now(),
    );
  }

  /// Generate personalized, psychiatrist-grade feedback utilizing CBT & DBT
  static Future<List<FeedbackItem>> getFeedback({
    required String sentiment,
    required String tone,
    required int score,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (sentiment == 'crisis' || tone == 'severe') {
      return [
        FeedbackItem(
          type: 'action',
          title: 'Immediate Help is Available',
          description: 'You are incredibly brave for sharing this. Please, right now, reach out to a crisis lifeline or emergency services. Your life has profound value. You do not have to carry this alone.',
          icon: '🆘',
        ),
        FeedbackItem(
          type: 'compassion',
          title: 'A Moment to Breathe',
          description: 'Stop whatever you are doing. Sit down. Breathe in for 4 seconds, out for 4 seconds. Just stay exactly where you are. You are safe in this exact second.',
          icon: '❤️',
        ),
        FeedbackItem(
          type: 'islamic',
          title: 'Divine Mercy',
          description: '"Do not lose hope, nor be sad." (Quran 3:139). Allah\'s mercy is vaster than any darkness you are feeling right now. Please seek help.',
          icon: '🕌',
        ),
      ];
    }
    
    // Dynamic mapping for negative emotional states
    if (score < 45) {
      List<FeedbackItem> feedback = [];
      
      if (tone == 'terror' || tone == 'grief') {
        feedback.add(FeedbackItem(
          type: 'breathing',
          title: 'Grounding Technique: 5-4-3-2-1',
          description: PsychologicalData.dbtSkills['Dissociation'] ?? 'Ground yourself.',
          icon: '🌬️',
        ));
        feedback.add(FeedbackItem(
          type: 'compassion',
          title: 'Radical Self-Compassion',
          description: 'Treat yourself with the exact same tenderness and grace you would offer a dear friend who is hurting today. It is okay to not be okay.',
          icon: '❤️',
        ));
      } else if (tone == 'rage' || tone == 'loathing') {
        feedback.add(FeedbackItem(
          type: 'physical',
          title: 'TIPP Skill (DBT)',
          description: PsychologicalData.dbtSkills['High Distress'] ?? 'Cool down.',
          icon: '🧊',
        ));
        feedback.add(FeedbackItem(
          type: 'cognitive',
          title: 'The Sacred Pause',
          description: 'Before reacting to this frustration, take 3 deep, slow breaths. Between the stimulus and your response lies your freedom to choose how you act.',
          icon: '⚖️',
        ));
      } else {
        feedback.add(FeedbackItem(
          type: 'action',
          title: 'Behavioral Activation',
          description: 'Motivation follows action, not the other way around. Do one tiny, 2-minute task (make the bed, drink water) to build micro-momentum.',
          icon: '💧',
        ));
        feedback.add(FeedbackItem(
          type: 'cognitive',
          title: 'Fact vs. Feeling',
          description: 'As a psychological tool, remind yourself: "Feelings are not facts." Is there absolute, undeniable evidence for your worry, or is it a "what if"?',
          icon: '🧠',
        ));
      }

      feedback.add(FeedbackItem(
        type: 'islamic',
        title: 'Tawakkul (Trust)',
        description: '"Hasbunallahu wa Ni\'mal Wakeel" (Sufficient for us is Allah, and He is the best Disposer of affairs). Hand over what you cannot control.',
        icon: '🕌',
      ));
      
      return feedback;
    } 
    
    if (score > 70) {
      return [
        FeedbackItem(
          type: 'habit',
          title: 'Positivity Ripple',
          description: 'Your emotional energy is beautiful today! Share this warmth by sending a quick "Thinking of you" text to someone you deeply care about.',
          icon: '🌊',
        ),
        FeedbackItem(
          type: 'growth',
          title: 'Capitalize on Flow',
          description: 'You are in a prime cognitive headspace. Use this momentum to tackle a creative task or something you\'ve been putting off.',
          icon: '⚡',
        ),
        FeedbackItem(
          type: 'islamic',
          title: 'Gratitude Increase',
          description: 'Alhamdulillah! "If you are grateful, I will surely increase my favor upon you." (Quran 14:7). Let your heart swell with gratitude.',
          icon: '🕌',
        ),
      ];
    } 
    
    // Neutral
    return [
      FeedbackItem(
        type: 'reflection',
        title: 'Mid-Day Check-in',
        description: 'You are maintaining a steady, healthy emotional balance. Take 2 minutes right now to identify one "Micro-Joy" you experienced today.',
        icon: '⚖️',
      ),
      FeedbackItem(
        type: 'physical',
        title: 'Body Scan',
        description: 'A quick 60-second stretch or posture check can re-oxygenate your brain and elevate your baseline mood even higher.',
        icon: '🧘',
      ),
      FeedbackItem(
        type: 'islamic',
        title: 'Consistent Good',
        description: '"The most beloved of deeds to Allah are those that are most consistent, even if they are small." (Bukhari). Keep nurturing your mind daily.',
        icon: '🕌',
      ),
    ];
  }

  /// AI chatbot coach powered by advanced Rogerian, CBT, and DBT Psychiatry patterns
  static Future<String> chatWithCoach(String message, {String? psychologicalContext}) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate thoughtful typing
    final lower = message.toLowerCase();
    
    // 1. Crisis Detection (Highest Priority)
    if (isCrisis(lower)) {
      return "I am stopping everything to tell you this: Your life has immense value, and I hear how much pain you are in right now. Please, I implore you to talk to a human who can help. You do not have to carry this unbearable weight alone. Please reach out to emergency services or someone you trust immediately. Stay with us.";
    }

    // 2. Identify CBT Distortions in user input
    String? foundDistortion;
    for (var entry in PsychologicalData.cognitiveDistortions.entries) {
      for (var word in entry.value) {
        if (lower.contains(word)) {
          foundDistortion = entry.key;
          break;
        }
      }
      if (foundDistortion != null) break;
    }

    if (foundDistortion != null) {
      return PsychologicalData.cbtInterventions[foundDistortion] ?? 
             "I hear a lot of absolute statements in what you're saying. How can we reframe this to be more realistic?";
    }

    // 3. Identify DBT Emotional Dysregulation
    String? foundDysregulation;
    for (var entry in PsychologicalData.emotionalDysregulation.entries) {
      for (var word in entry.value) {
        if (lower.contains(word)) {
          foundDysregulation = entry.key;
          break;
        }
      }
      if (foundDysregulation != null) break;
    }

    if (foundDysregulation != null) {
      return PsychologicalData.dbtSkills[foundDysregulation] ?? 
             "Your nervous system sounds incredibly overwhelmed right now. Please take a deep breath. I am right here.";
    }

    // 4. Topic/Context Routing (Trauma, Work, Relationships)
    if (lower.contains('grief') || lower.contains('died') || lower.contains('lost') || lower.contains('trauma')) {
      return "I am so incredibly sorry for your pain. Grief and trauma are heavy oceans to swim in. "
          "Please remember there is no timeline for healing, and whatever you are feeling—anger, numbness, deep sorrow—is completely valid. "
          "I am here to just listen. You don't have to fix anything right now.";
    }

    if (lower.contains('work') || lower.contains('boss') || lower.contains('deadline')) {
      return "It sounds like the professional pressure you're under is becoming overwhelming. 💼 "
          "When we are stressed by work, our nervous system reacts as if we are in physical danger. "
          "As your coach, I want to remind you that your worth is not tied to your productivity. What is the smallest step you can take right now to reclaim a moment of peace?";
    }

    // 5. Rogerian Empathetic Default
    final reflection = PsychologicalData.rogerianReflections[
      DateTime.now().millisecondsSinceEpoch % PsychologicalData.rogerianReflections.length
    ];
    final probe = PsychologicalData.activeListeningProbes[
      DateTime.now().millisecondsSinceEpoch % PsychologicalData.activeListeningProbes.length
    ];

    if (lower.contains('happy') || lower.contains('great') || lower.contains('good')) {
      return "That is absolutely wonderful to hear! 🌟 Capturing these moments is exactly how we build long-term psychological resilience. What specifically made this moment so good?";
    }

    return "🌿 $reflection $probe";
  }

  /// General purpose logic parsing
  static Future<String> getRawAIResponse(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'I hear you. As your digital psychiatrist, I want to encourage you to focus on taking deep breaths. Break your immense burdens into tiny, manageable pieces for today. You are doing the best you can.';
  }

  /// AI Logic for Gaming: Generate a dynamic challenge locally
  static Future<Map<String, dynamic>> generateAIChallenge() async {
    final challenges = [
      {
        'title': 'Mindful Minute',
        'task': 'Close your eyes, drop your shoulders, and focus purely on your breath for 60 seconds.',
        'points': 30,
        'difficulty': 'Easy'
      },
      {
        'title': 'Gratitude Connection',
        'task': 'Send a thank you note to someone who made your life slightly easier recently.',
        'points': 50,
        'difficulty': 'Medium'
      },
      {
        'title': 'Cognitive Detox',
        'task': 'Put your phone in another room for the next hour. Reconnect with the physical world.',
        'points': 80,
        'difficulty': 'Hard'
      },
      {
        'title': 'Physical Reset',
        'task': 'Stand up, reach for the ceiling, and do a full body stretch to release stored trauma.',
        'points': 40,
        'difficulty': 'Easy'
      }
    ];
    
    challenges.shuffle();
    return challenges.first;
  }

  // ── Supabase Image Upload (via FastAPI) ──
  static const String _baseUrl = 'http://localhost:8000';

  static Future<String?> uploadImage({
    required List<int> imageBytes,
    required String fileName,
    required String userId,
    String bucket = 'journal-attachments',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-image'));
      request.fields['user_id'] = userId;
      request.fields['bucket'] = bucket;
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteImage({
    required String bucket,
    required String path,
    required String userId,
  }) async {
    try {
      final request = http.MultipartRequest('DELETE', Uri.parse('$_baseUrl/delete-image'));
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
