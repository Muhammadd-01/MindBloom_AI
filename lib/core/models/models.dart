// Data models for the MindBloom AI app

enum SubscriptionTier {
  seedling('Seedling', 3),  // Free: 3/day
  bloom('Bloom', 15),     // Plus: 15/day
  forest('Forest', 9999);  // Elite: Unlimited

  final String label;
  final int dailyLimit;
  const SubscriptionTier(this.label, this.dailyLimit);

  static SubscriptionTier fromString(String? value) {
    return SubscriptionTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionTier.seedling,
    );
  }
}

// ── User Model ──
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final SubscriptionTier subscriptionTier;
  final int streak;
  final int level;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.subscriptionTier = SubscriptionTier.seedling,
    this.streak = 0,
    this.level = 1,
    this.totalPoints = 0,
    required this.createdAt,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'subscriptionTier': subscriptionTier.name,
    'streak': streak,
    'level': level,
    'totalPoints': totalPoints,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    displayName: map['displayName'] ?? '',
    photoUrl: map['photoUrl'] ?? '',
    subscriptionTier: SubscriptionTier.fromString(map['subscriptionTier']),
    streak: map['streak'] ?? 0,
    level: map['level'] ?? 1,
    totalPoints: map['totalPoints'] ?? 0,
    createdAt: DateTime.parse(map['createdAt']),
    lastActiveAt: DateTime.parse(map['lastActiveAt']),
  );

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    SubscriptionTier? subscriptionTier,
    int? streak,
    int? level,
    int? totalPoints,
    DateTime? lastActiveAt,
  }) => UserModel(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    streak: streak ?? this.streak,
    level: level ?? this.level,
    totalPoints: totalPoints ?? this.totalPoints,
    createdAt: createdAt,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
  );
}

// ── Analysis Result Model ──
class AnalysisResult {
  final String id;
  final String userId;
  final String inputText;
  final String inputType; // 'voice', 'journal', 'mood'
  final int positivityScore;
  final String sentiment; // 'positive', 'neutral', 'negative'
  final String tone; // 'calm', 'stress', 'anger', 'motivation', 'joy', 'sadness'
  final List<String> keywords;
  final String? imageUrl;
  final DateTime analyzedAt;

  const AnalysisResult({
    required this.id,
    required this.userId,
    required this.inputText,
    required this.inputType,
    required this.positivityScore,
    required this.sentiment,
    required this.tone,
    this.keywords = const [],
    this.imageUrl,
    required this.analyzedAt,
  });

  AnalysisResult copyWith({
    String? id,
    String? userId,
    String? inputText,
    String? inputType,
    int? positivityScore,
    String? sentiment,
    String? tone,
    List<String>? keywords,
    String? imageUrl,
    DateTime? analyzedAt,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      inputText: inputText ?? this.inputText,
      inputType: inputType ?? this.inputType,
      positivityScore: positivityScore ?? this.positivityScore,
      sentiment: sentiment ?? this.sentiment,
      tone: tone ?? this.tone,
      keywords: keywords ?? this.keywords,
      imageUrl: imageUrl ?? this.imageUrl,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'inputText': inputText,
    'inputType': inputType,
    'positivityScore': positivityScore,
    'sentiment': sentiment,
    'tone': tone,
    'keywords': keywords,
    'imageUrl': imageUrl,
    'analyzedAt': analyzedAt.toIso8601String(),
  };

  factory AnalysisResult.fromMap(Map<String, dynamic> map) => AnalysisResult(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    inputText: map['inputText'] ?? '',
    inputType: map['inputType'] ?? 'journal',
    positivityScore: map['positivityScore'] ?? 0,
    sentiment: map['sentiment'] ?? 'neutral',
    tone: map['tone'] ?? 'calm',
    keywords: List<String>.from(map['keywords'] ?? []),
    imageUrl: map['imageUrl'],
    analyzedAt: DateTime.parse(map['analyzedAt']),
  );
}

// ── Daily Report Model ──
class DailyReport {
  final String id;
  final String userId;
  final DateTime date;
  final int averageScore;
  final String dominantSentiment;
  final String dominantTone;
  final int entriesCount;
  final List<String> suggestions;
  final List<AnalysisResult> analyses;

  const DailyReport({
    required this.id,
    required this.userId,
    required this.date,
    required this.averageScore,
    required this.dominantSentiment,
    required this.dominantTone,
    this.entriesCount = 0,
    this.suggestions = const [],
    this.analyses = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'averageScore': averageScore,
    'dominantSentiment': dominantSentiment,
    'dominantTone': dominantTone,
    'entriesCount': entriesCount,
    'suggestions': suggestions,
  };

  factory DailyReport.fromMap(Map<String, dynamic> map) => DailyReport(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    date: DateTime.parse(map['date']),
    averageScore: map['averageScore'] ?? 0,
    dominantSentiment: map['dominantSentiment'] ?? 'neutral',
    dominantTone: map['dominantTone'] ?? 'calm',
    entriesCount: map['entriesCount'] ?? 0,
    suggestions: List<String>.from(map['suggestions'] ?? []),
  );
}

// ── Insight Model (for charts) ──
class InsightData {
  final DateTime date;
  final int score;
  final String sentiment;

  const InsightData({
    required this.date,
    required this.score,
    required this.sentiment,
  });
}

// ── Feedback Model ──
class FeedbackItem {
  final String type; // 'breathing', 'reflection', 'islamic', 'habit'
  final String title;
  final String description;
  final String? quranVerse;
  final String? hadith;
  final String icon;

  const FeedbackItem({
    required this.type,
    required this.title,
    required this.description,
    this.quranVerse,
    this.hadith,
    this.icon = '💡',
  });
}

// ── App Review/Feedback Model ──
class AppReview {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const AppReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppReview.fromMap(Map<String, dynamic> map) => AppReview(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    userName: map['userName'] ?? 'Anonymous',
    userPhoto: map['userPhoto'],
    rating: (map['rating'] ?? 0).toDouble(),
    comment: map['comment'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );
}

// ── Mood Enum ──
enum MoodType {
  veryHappy('😄', 'Very Happy', 95),
  happy('😊', 'Happy', 80),
  neutral('😐', 'Neutral', 50),
  sad('😔', 'Sad', 30),
  verySad('😢', 'Very Sad', 10),
  angry('😠', 'Angry', 15),
  anxious('😰', 'Anxious', 25),
  grateful('🙏', 'Grateful', 90),
  motivated('💪', 'Motivated', 85);

  final String emoji;
  final String label;
  final int baseScore;

  const MoodType(this.emoji, this.label, this.baseScore);
}
