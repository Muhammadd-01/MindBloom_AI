import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/loading_overlay.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final success = await ref.read(feedbackProvider.notifier).submitFeedback(
      _rating,
      _commentController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _commentController.clear();
        setState(() => _rating = 5.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit feedback. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDarkMode),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubmitSection(isDarkMode),
                          const SizedBox(height: 32),
                          _buildCommunityStats(feedbackState.reviews, isDarkMode),
                          const SizedBox(height: 16),
                          Text(
                            'Community Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (feedbackState.isLoading && feedbackState.reviews.isEmpty)
                            const Center(child: CircularProgressIndicator())
                          else if (feedbackState.reviews.isEmpty)
                            _buildEmptyState(isDarkMode)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: feedbackState.reviews.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, index) => _buildReviewCard(feedbackState.reviews[index], isDarkMode),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting) const LoadingOverlay(message: 'Submitting your review...'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
            ),
          ),
          Text(
            'Feedback & Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How is your experience?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1.0),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.primaryAccent,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimaryDark),
            decoration: InputDecoration(
              hintText: 'Tell us what you think...',
              hintStyle: TextStyle(color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
              filled: true,
              fillColor: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStats(List<AppReview> reviews, bool isDarkMode) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average Rating',
            avgRating.toStringAsFixed(1),
            Icons.star_rounded,
            AppColors.primaryAccent,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Reviews',
            reviews.length.toString(),
            Icons.people_rounded,
            AppColors.secondaryAccent,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(AppReview review, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                backgroundImage: review.userPhoto != null && review.userPhoto!.isNotEmpty
                    ? NetworkImage(review.userPhoto!)
                    : null,
                child: review.userPhoto == null || review.userPhoto!.isEmpty
                    ? Text(review.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryAccent))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.primaryAccent,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.primaryAccent.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your experience!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
