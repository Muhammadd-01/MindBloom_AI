import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_notifications.dart';

// ── Auth State ──

/// Tracks if the user is logged in via Firebase
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
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
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
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
        _ref.read(settingsProvider.notifier).updateSubscription(userModel.subscriptionTier);
        state = state.copyWith(isLoggedIn: true, user: userModel, isInitialized: true, isLoading: false);
      } else {
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = 21
        // targetSdk = flutter.targetSdkVersion
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
      final message = AppNotifications.getFriendlyErrorMessage(e);
      AppNotifications.show(null, message: message, type: NotificationType.error);
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

      UserModel userModel;
      
      // SPECIAL ACCESS: For user GeniusAISquad@gmail.com, grant full Elite access regardless of setup
      if (email.toLowerCase() == 'geniusaisquad@gmail.com') {
        userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: name,
          subscriptionTier: SubscriptionTier.forest, // Full access (Elite/Forest)
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
      } else {
        userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: name,
          subscriptionTier: SubscriptionTier.seedling, // Default free
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
      }

      // Save to Firestore
      await _db.collection('users').doc(userModel.uid).set(userModel.toMap());

      state = state.copyWith(isLoggedIn: true, user: userModel, isInitialized: true, isLoading: false);
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

      // Fetch user data
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        UserModel user = UserModel.fromMap(doc.data()!);
        
        // SPECIAL ACCESS: Re-verify special user on login
        if (firebaseUser.email?.toLowerCase() == 'geniusaisquad@gmail.com') {
          user = user.copyWith(subscriptionTier: SubscriptionTier.forest);
          await _db.collection('users').doc(user.uid).update({'subscriptionTier': 'forest'});
        }
        
        state = state.copyWith(user: user, isLoading: false);
      } else {
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

  /// Add experience points and handle leveling up
  Future<void> addPoints(int points) async {
    if (state.user == null) return;
    
    final currentPoints = state.user!.totalPoints + points;
    final newLevel = (currentPoints / 100).floor() + 1;
    
    final updates = {
      'totalPoints': currentPoints,
      'level': newLevel,
      'lastActiveAt': DateTime.now().toIso8601String(),
    };
    
    await _db.collection('users').doc(state.user!.uid).update(updates);
    
    final updatedUser = state.user!.copyWith(
      totalPoints: currentPoints,
      level: newLevel,
      lastActiveAt: DateTime.now(),
    );
    
    state = state.copyWith(user: updatedUser);
  }

  /// Update user profile in Firestore and state
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (state.user == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['displayName'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      await _db.collection('users').doc(state.user!.uid).set(updates, SetOptions(merge: true));
      
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
      final fileBytes = await image.readAsBytes();
      
      // Use a consistent naming convention
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'avatar_$timestamp.jpg';
      final storagePath = '${state.user!.uid}/$fileName';

      if (kDebugMode) print('📤 Supabase: Starting profile upload to path: $storagePath');

      // 2. Upload to Supabase
      final supabase = Supabase.instance.client;
      
      // Explicitly set content type and use upsert
      await supabase.storage.from('profile-images').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600', 
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // 3. Get Public URL
      final String publicUrl = supabase.storage.from('profile-images').getPublicUrl(storagePath);
      
      if (kDebugMode) print('✅ Supabase: Profile upload success. URL: $publicUrl');

      // 4. Update Profile in Firestore
      await updateProfile(photoUrl: publicUrl);
      AppNotifications.show(null, message: 'Profile updated successfully!', type: NotificationType.success);
      
    } catch (e) {
      if (kDebugMode) print('❌ Supabase Profile Upload Error: $e');
      state = state.copyWith(isLoading: false, error: 'Upload failed: ${e.toString()}');
      
      // Friendly message with technical hint for developer
      String errorMsg = 'Image upload failed. ';
      if (e.toString().contains('403')) {
        errorMsg += 'Check Supabase RLS Policies for "anon" role.';
      } else {
        errorMsg += 'Please check your connection.';
      }
      
      AppNotifications.show(null, message: errorMsg, type: NotificationType.error);
    }
  }

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
      final fileBytes = await image.readAsBytes();
      
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'journal_$timestamp.jpg';
      final storagePath = '${state.user!.uid}/$fileName';

      if (kDebugMode) print('📤 Supabase: Starting journal upload to path: $storagePath');

      // 2. Upload to Supabase
      final supabase = Supabase.instance.client;
      await supabase.storage.from('journal-attachments').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600', 
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // 3. Get Public URL
      final String publicUrl = supabase.storage.from('journal-attachments').getPublicUrl(storagePath);
      
      if (kDebugMode) print('✅ Supabase: Journal upload success. URL: $publicUrl');
      
      state = state.copyWith(isLoading: false);
      return publicUrl;
      
    } catch (e) {
      if (kDebugMode) print('❌ Supabase Journal Upload Error: $e');
      state = state.copyWith(isLoading: false, error: 'Journal image upload failed');
      
      String errorMsg = 'Failed to attach image. ';
      if (e.toString().contains('403')) {
        errorMsg += 'Check Supabase RLS Policies.';
      }
      
      AppNotifications.show(null, message: errorMsg, type: NotificationType.error);
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
  final List<InsightData> monthlyInsights;
  final List<AnalysisResult> recentAnalyses;
  final Map<String, dynamic> streakInfo;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.todayReport,
    this.weeklyInsights = const [],
    this.monthlyInsights = const [],
    this.recentAnalyses = const [],
    this.streakInfo = const {},
    this.isLoading = true,
    this.error,
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
        // Fallback with zero/starting state if no analyses yet
        todayReport = DailyReport(
          id: 'report_initial',
          userId: userId,
          date: now,
          averageScore: 0,
          dominantSentiment: 'Neutral',
          dominantTone: 'Observational',
          entriesCount: 0,
          suggestions: [
            'Welcome to MindBloom! Record your first thought to generate your daily positivity score.',
            'Consistency is key to pattern recognition.',
          ],
        );
      }

      // Build weekly/monthly insights from analyses
      List<InsightData> weeklyInsights;
      List<InsightData> monthlyInsights;
      
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = now.subtract(const Duration(days: 30));

      weeklyInsights = recentAnalyses
          .where((a) => a.analyzedAt.isAfter(weekStart))
          .map((a) => InsightData(
                date: a.analyzedAt,
                score: a.positivityScore,
                sentiment: a.sentiment,
              ))
          .toList()
          .reversed.toList(); // Chronological for charts

      monthlyInsights = recentAnalyses
          .where((a) => a.analyzedAt.isAfter(monthStart))
          .map((a) => InsightData(
                date: a.analyzedAt,
                score: a.positivityScore,
                sentiment: a.sentiment,
              ))
          .toList()
          .reversed.toList();

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
        monthlyInsights: monthlyInsights,
        recentAnalyses: recentAnalyses.take(5).toList(),
        streakInfo: streakInfo,
        isLoading: false,
      );
    } catch (e) {
      print('Dashboard Load Error: $e');
      // On error, we still want to show a valid (empty) state rather than dummy data
      // unless we are in a specifically designated 'demo' mode.
      state = DashboardState(
        todayReport: DailyReport(
          id: 'error',
          userId: userId,
          date: DateTime.now(),
          averageScore: 0,
          dominantSentiment: 'Neutral',
          dominantTone: 'Calm',
          suggestions: ['Your insights will appear once your reflections are analyzed.'],
        ),
        weeklyInsights: [],
        recentAnalyses: [],
        streakInfo: {
          'currentStreak': 0,
          'level': 1,
          'points': 0,
        },
        isLoading: false,
        error: 'Failed to load specific user data: ${e.toString()}',
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
  return AnalysisNotifier(ref);
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
  final Ref _ref;

  AnalysisNotifier(this._ref) : super(const AnalysisState());

  /// Analyze user text input and save to Firestore
  Future<void> analyze({
    required String text,
    required String userId,
    required String inputType,
    String? imageUrl,
  }) async {
    // Check daily limits
    final dashboard = _ref.read(dashboardProvider);
    final user = _ref.read(authStateProvider).user;
    final currentEntries = dashboard.todayReport?.entriesCount ?? 0;
    final limit = user?.subscriptionTier.dailyLimit ?? SubscriptionTier.seedling.dailyLimit;

    if (currentEntries >= limit) {
      state = const AnalysisState(
        isAnalyzing: false, 
        error: 'Daily growth limit reached. Upgrade to unlock more reflections.'
      );
      return;
    }

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

      // Update user stats and grant points
      await _ref.read(authStateProvider.notifier).addPoints(result.positivityScore ~/ 10);

      state = AnalysisState(
        currentResult: result,
        feedback: feedback,
        isAnalyzing: false,
      );
    } catch (e) {
      final message = AppNotifications.getFriendlyErrorMessage(e);
      AppNotifications.show(null, message: message, type: NotificationType.error);
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

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>((ref) => FeedbackNotifier(ref));

class SettingsState {
  final bool trackingEnabled;
  final bool notificationsEnabled;
  final bool islamicContentEnabled;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final SubscriptionTier subscriptionTier;
  final bool isDarkMode;
  final bool isPassiveMode;

  const SettingsState({
    this.trackingEnabled = true,
    this.notificationsEnabled = true,
    this.islamicContentEnabled = true,
    this.twoFactorEnabled = false,
    this.biometricEnabled = true,
    this.subscriptionTier = SubscriptionTier.seedling,
    this.isDarkMode = false,
    this.isPassiveMode = false,
  });

  SettingsState copyWith({
    bool? trackingEnabled,
    bool? notificationsEnabled,
    bool? islamicContentEnabled,
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    SubscriptionTier? subscriptionTier,
    bool? isDarkMode,
    bool? isPassiveMode,
  }) => SettingsState(
    trackingEnabled: trackingEnabled ?? this.trackingEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    islamicContentEnabled: islamicContentEnabled ?? this.islamicContentEnabled,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    isDarkMode: isDarkMode ?? this.isDarkMode,
    isPassiveMode: isPassiveMode ?? this.isPassiveMode,
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
  void toggleTwoFactor() => state = state.copyWith(twoFactorEnabled: !state.twoFactorEnabled);
  void toggleBiometric() => state = state.copyWith(biometricEnabled: !state.biometricEnabled);
  void togglePassiveMode() => state = state.copyWith(isPassiveMode: !state.isPassiveMode);
  void toggleIslamicContent() {
    state = state.copyWith(islamicContentEnabled: !state.islamicContentEnabled);
  }
  void updateSubscription(SubscriptionTier tier) {
    state = state.copyWith(subscriptionTier: tier);
  }

  Future<bool> authenticateBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Fail-safe for demo

      return await auth.authenticate(
        localizedReason: 'Please authenticate to access MindBloom',
      );
    } catch (e) {
      return true; // Fail-safe for demo/simulators
    }
  }
}

// ── Feedback Provider ──

class FeedbackState {
  final List<AppReview> reviews;
  final bool isLoading;
  final String? error;

  const FeedbackState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  FeedbackNotifier(this._ref) : super(const FeedbackState()) {
    loadFeedbacks();
  }

  Future<void> loadFeedbacks() async {
    state = FeedbackState(reviews: state.reviews, isLoading: true);
    try {
      final snapshot = await _db
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final reviews = snapshot.docs.map((doc) => AppReview.fromMap(doc.data())).toList();
      state = FeedbackState(reviews: reviews, isLoading: false);
    } catch (e) {
      state = FeedbackState(reviews: state.reviews, isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitFeedback(double rating, String comment) async {
    final user = _ref.read(authStateProvider).user;
    if (user == null) return false;

    try {
      final id = _db.collection('feedbacks').doc().id;
      final review = AppReview(
        id: id,
        userId: user.uid,
        userName: user.displayName.isNotEmpty ? user.displayName : 'User',
        userPhoto: user.photoUrl,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _db.collection('feedbacks').doc(id).set(review.toMap());
      await loadFeedbacks(); // Refresh list
      return true;
    } catch (e) {
      return false;
    }
  }
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
