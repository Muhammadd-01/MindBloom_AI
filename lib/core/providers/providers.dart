import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';

// ── Auth State ──

/// Tracks if the user is logged in via Firebase
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoggedIn;
  final UserModel? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  /// Initial check for existing session
  void _init() {
    _auth.authStateChanges().listen((auth.User? firebaseUser) async {
      if (firebaseUser == null) {
        state = state.copyWith(isLoggedIn: false, isInitialized: true, isLoading: false);
      } else {
        await _fetchAndSetUser(firebaseUser);
      }
    });
  }

  /// Fetch user profile from Firestore and update state
  Future<void> _fetchAndSetUser(auth.User firebaseUser) async {
    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      
      if (doc.exists) {
        final userModel = UserModel.fromMap({
          ...doc.data()!,
          'uid': firebaseUser.uid,
        });
        state = state.copyWith(isLoggedIn: true, user: userModel, isInitialized: true, isLoading: false);
      } else {
        // Fallback for new users if sync failed during signup
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        state = state.copyWith(isLoggedIn: true, user: newUser, isInitialized: true, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isInitialized: true, isLoading: false);
    }
  }

  /// Register a new user with Email/Password
  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // Save to Firestore
      await _db.collection('users').doc(user.uid).set(user.toMap());

      state = state.copyWith(isLoggedIn: true, user: user, isInitialized: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Login with email/password
  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // state will be updated via authStateChanges listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Real Google Sign In
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Sync with Firestore
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Positive User',
          photoUrl: firebaseUser.photoURL ?? '',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Sign out
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800)); // Smooth transition
    await _auth.signOut();
    await _googleSignIn.signOut();
    state = const AuthState(isLoggedIn: false, isInitialized: true);
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Delete all user data from Firestore
  Future<void> deleteAllData() async {
    if (state.user == null) return;
    final uid = state.user!.uid;
    
    // Delete analyses subcollection
    final analyses = await _db.collection('users').doc(uid).collection('analyses').get();
    for (final doc in analyses.docs) {
      await doc.reference.delete();
    }
    
    // Delete settings subcollection
    final settings = await _db.collection('users').doc(uid).collection('settings').get();
    for (final doc in settings.docs) {
      await doc.reference.delete();
    }
    
    // Delete user document
    await _db.collection('users').doc(uid).delete();
  }

  /// Update user profile in Firestore and state
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (state.user == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['displayName'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      await _db.collection('users').doc(state.user!.uid).update(updates);
      
      final updatedUser = state.user!.copyWith(
        displayName: name ?? state.user!.displayName,
        photoUrl: photoUrl ?? state.user!.photoUrl,
      );
      
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Pick an image and upload to Supabase, then update Firestore
  Future<void> uploadProfileImage(ImageSource source) async {
    if (state.user == null) return;
    
    final ImagePicker picker = ImagePicker();
    try {
      // 1. Pick Image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image == null) return;
      
      state = state.copyWith(isLoading: true);
      final file = File(image.path);
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${state.user!.uid}/$fileName';

      // 2. Upload to Supabase (using folder structure from guide)
      final supabase = Supabase.instance.client;
      await supabase.storage.from('profile-images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 3. Get Public URL
      final String publicUrl = supabase.storage.from('profile-images').getPublicUrl(storagePath);

      // 4. Update Profile in Firestore
      await updateProfile(photoUrl: publicUrl);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Upload failed: ${e.toString()}');
    }
  }

  /// Pick an image and upload to Supabase 'journal-attachments' bucket
  Future<String?> uploadJournalImage(ImageSource source) async {
    if (state.user == null) return null;
    
    final ImagePicker picker = ImagePicker();
    try {
      // 1. Pick Image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      
      if (image == null) return null;
      
      state = state.copyWith(isLoading: true);
      final file = File(image.path);
      final fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${state.user!.uid}/$fileName';

      // 2. Upload to Supabase
      final supabase = Supabase.instance.client;
      await supabase.storage.from('journal-attachments').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 3. Get Public URL
      final String publicUrl = supabase.storage.from('journal-attachments').getPublicUrl(storagePath);
      
      state = state.copyWith(isLoading: false);
      return publicUrl;
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Journal image upload failed: ${e.toString()}');
      return null;
    }
  }
}

// ── Dashboard State ──

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});

class DashboardState {
  final DailyReport? todayReport;
  final List<InsightData> weeklyInsights;
  final List<AnalysisResult> recentAnalyses;
  final Map<String, dynamic> streakInfo;
  final bool isLoading;

  const DashboardState({
    this.todayReport,
    this.weeklyInsights = const [],
    this.recentAnalyses = const [],
    this.streakInfo = const {},
    this.isLoading = true,
  });
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DashboardNotifier() : super(const DashboardState());

  /// Load all dashboard data from Firestore
  Future<void> loadDashboard(String userId) async {
    state = const DashboardState(isLoading: true);

    try {
      // Fetch recent analyses from Firestore
      final analysesSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('analyses')
          .orderBy('analyzedAt', descending: true)
          .limit(20)
          .get();

      final recentAnalyses = analysesSnap.docs
          .map((doc) => AnalysisResult.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Build today's report from analyses
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayAnalyses = recentAnalyses
          .where((a) => a.analyzedAt.isAfter(todayStart))
          .toList();

      DailyReport? todayReport;
      if (todayAnalyses.isNotEmpty) {
        final avgScore = todayAnalyses.map((a) => a.positivityScore).reduce((a, b) => a + b) ~/ todayAnalyses.length;
        final sentiments = todayAnalyses.map((a) => a.sentiment).toList();
        final dominantSentiment = _mostCommon(sentiments);
        final tones = todayAnalyses.map((a) => a.tone).toList();
        final dominantTone = _mostCommon(tones);

        todayReport = DailyReport(
          id: 'report_today',
          userId: userId,
          date: now,
          averageScore: avgScore,
          dominantSentiment: dominantSentiment,
          dominantTone: dominantTone,
          entriesCount: todayAnalyses.length,
          suggestions: _getSuggestions(avgScore),
        );
      } else {
        // Fallback with dummy data if no analyses yet
        todayReport = DummyDataService.getTodayReport(userId);
      }

      // Build weekly insights from analyses
      List<InsightData> weeklyInsights;
      if (recentAnalyses.length >= 3) {
        final weekStart = now.subtract(const Duration(days: 7));
        weeklyInsights = recentAnalyses
            .where((a) => a.analyzedAt.isAfter(weekStart))
            .map((a) => InsightData(
                  date: a.analyzedAt,
                  score: a.positivityScore,
                  sentiment: a.sentiment,
                ))
            .toList();
        if (weeklyInsights.isEmpty) {
          weeklyInsights = DummyDataService.getWeeklyInsights();
        }
      } else {
        weeklyInsights = DummyDataService.getWeeklyInsights();
      }

      // Fetch user doc for streak info
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final streakInfo = {
        'currentStreak': userData['streak'] ?? 0,
        'longestStreak': userData['longestStreak'] ?? 0,
        'totalEntries': recentAnalyses.length,
        'level': userData['level'] ?? 1,
        'points': userData['totalPoints'] ?? 0,
        'nextLevelPoints': ((userData['level'] ?? 1) + 1) * 500,
      };

      state = DashboardState(
        todayReport: todayReport,
        weeklyInsights: weeklyInsights,
        recentAnalyses: recentAnalyses.take(5).toList(),
        streakInfo: streakInfo,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to dummy data on error
      state = DashboardState(
        todayReport: DummyDataService.getTodayReport(userId),
        weeklyInsights: DummyDataService.getWeeklyInsights(),
        recentAnalyses: DummyDataService.getRecentAnalyses(userId),
        streakInfo: DummyDataService.getStreakInfo(),
        isLoading: false,
      );
    }
  }

  String _mostCommon(List<String> items) {
    final freq = <String, int>{};
    for (final item in items) {
      freq[item] = (freq[item] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<String> _getSuggestions(int score) {
    if (score > 70) {
      return [
        'Your positivity is radiating! Keep journaling daily.',
        'Share your positive energy with someone today.',
        'Consider setting a new personal growth goal.',
      ];
    } else if (score > 45) {
      return [
        'You\'re doing well. Try a gratitude exercise this evening.',
        'Take 5 minutes for mindful breathing.',
        'Reflect on one thing that went well today.',
      ];
    } else {
      return [
        'Take a moment to pause and breathe deeply.',
        'Write down 3 things you\'re grateful for.',
        'Remember: every storm passes. Better days are ahead.',
      ];
    }
  }

  /// Refresh data
  Future<void> refresh(String userId) async => loadDashboard(userId);
}

// ── Analysis State ──

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});

class AnalysisState {
  final AnalysisResult? currentResult;
  final List<FeedbackItem> feedback;
  final bool isAnalyzing;
  final String? error;

  const AnalysisState({
    this.currentResult,
    this.feedback = const [],
    this.isAnalyzing = false,
    this.error,
  });
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AnalysisNotifier() : super(const AnalysisState());

  /// Analyze user text input and save to Firestore
  Future<void> analyze({
    required String text,
    required String userId,
    required String inputType,
    String? imageUrl,
  }) async {
    state = const AnalysisState(isAnalyzing: true);

    try {
      final result = await ApiService.analyzeText(
        text: text,
        userId: userId,
        inputType: inputType,
      );

      // Add the imageUrl if provided
      final finalResult = imageUrl != null ? result.copyWith(imageUrl: imageUrl) : result;

      final feedback = await ApiService.getFeedback(
        sentiment: finalResult.sentiment,
        tone: finalResult.tone,
        score: finalResult.positivityScore,
      );

      // Save analysis to Firestore
      await _db
          .collection('users')
          .doc(userId)
          .collection('analyses')
          .doc(finalResult.id)
          .set(finalResult.toMap());

      // Update user stats
      await _db.collection('users').doc(userId).update({
        'lastActiveAt': DateTime.now().toIso8601String(),
        'totalPoints': FieldValue.increment(result.positivityScore ~/ 10),
      });

      state = AnalysisState(
        currentResult: result,
        feedback: feedback,
        isAnalyzing: false,
      );
    } catch (e) {
      state = AnalysisState(isAnalyzing: false, error: e.toString());
    }
  }

  void clear() => state = const AnalysisState();
}

// ── Settings State ──

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsState {
  final bool trackingEnabled;
  final bool notificationsEnabled;
  final bool islamicContentEnabled;
  final bool isPremium;
  final bool isDarkMode;

  const SettingsState({
    this.trackingEnabled = true,
    this.notificationsEnabled = true,
    this.islamicContentEnabled = true,
    this.isPremium = false,
    this.isDarkMode = false, // Defaults to Light Mode as requested
  });

  SettingsState copyWith({
    bool? trackingEnabled,
    bool? notificationsEnabled,
    bool? islamicContentEnabled,
    bool? isPremium,
    bool? isDarkMode,
  }) => SettingsState(
    trackingEnabled: trackingEnabled ?? this.trackingEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    islamicContentEnabled: islamicContentEnabled ?? this.islamicContentEnabled,
    isPremium: isPremium ?? this.isPremium,
    isDarkMode: isDarkMode ?? this.isDarkMode,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'is_dark_mode';

  SettingsNotifier(this._prefs) : super(SettingsState(
    isDarkMode: _prefs.getBool(_themeKey) ?? false,
  ));

  void toggleTheme() {
    final newValue = !state.isDarkMode;
    _prefs.setBool(_themeKey, newValue);
    state = state.copyWith(isDarkMode: newValue);
  }

  void toggleTracking() => state = state.copyWith(trackingEnabled: !state.trackingEnabled);
  void toggleNotifications() => state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  void toggleIslamicContent() => state = state.copyWith(islamicContentEnabled: !state.islamicContentEnabled);
  void upgradeToPremium() => state = state.copyWith(isPremium: true);
}


// ── Shared Preferences Provider ──

/// Access to the persisted settings
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main() and override in ProviderScope');
});

// ── Onboarding State ──

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String _key = 'onboarding_complete';

  OnboardingNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
    state = true;
  }

  /// Reset for testing if needed
  Future<void> resetOnboarding() async {
    await _prefs.setBool(_key, false);
    state = false;
  }
}

// ── Navigation State ──
final currentTabProvider = StateProvider<int>((ref) => 0);

// ── Chat State ──
final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([
    ChatMessage(
      text: "Hello! I'm your AI Positivity Coach. 🌟\n\nHow are you feeling today? Share your thoughts and I'll help you cultivate a more positive mindset.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String text) async {
    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true, timestamp: DateTime.now())];

    // Get AI response
    final response = await ApiService.chatWithCoach(text);
    state = [...state, ChatMessage(text: response, isUser: false, timestamp: DateTime.now())];
  }
}
