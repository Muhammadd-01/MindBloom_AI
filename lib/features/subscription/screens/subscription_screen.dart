import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import 'dart:ui';
import '../../payment/screens/payment_screen.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDarkMode = settings.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
            ),
          ),
          
          // Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.close_rounded, 
                        color: isDarkMode ? Colors.white : AppColors.textPrimaryDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  floating: true,
                  centerTitle: true,
                  title: Text(
                    'Choose Your Path',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Unlock your full behavioral potential with our elite growth tiers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildTierCard(
                        context,
                        tier: SubscriptionTier.seedling,
                        icon: '🌱',
                        title: 'Seedling',
                        subtitle: 'Basic Mindfulness',
                        price: 'Free',
                        features: [
                          '3 Daily AI Reflections',
                          'Daily Positivity Score',
                          'Basic Journal History',
                        ],
                        isCurrent: settings.subscriptionTier == SubscriptionTier.seedling,
                        isDarkMode: isDarkMode,
                        color: Colors.greenAccent,
                        ref: ref,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildTierCard(
                        context,
                        tier: SubscriptionTier.bloom,
                        icon: '🌸',
                        title: 'Bloom',
                        subtitle: 'Advanced Growth',
                        price: '\$4.99/mo',
                        features: [
                          '15 Daily AI Reflections',
                          'Weekly Mood Trends',
                          'Unlimited Voice Recordings',
                          'Advanced Sentiment Charts',
                        ],
                        isCurrent: settings.subscriptionTier == SubscriptionTier.bloom,
                        isDarkMode: isDarkMode,
                        color: AppColors.primaryAccent,
                        ref: ref,
                        isPopular: true,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildTierCard(
                        context,
                        tier: SubscriptionTier.forest,
                        icon: '🌳',
                        title: 'Forest',
                        subtitle: 'Elite Mastery',
                        price: '\$9.99/mo',
                        features: [
                          'Unlimited Daily Reflections',
                          'Deep Behavioral DNA Analysis',
                          'Personal AI Lifestyle Coach',
                          'Custom Mindset Goals',
                          'Priority Feature Access',
                        ],
                        isCurrent: settings.subscriptionTier == SubscriptionTier.forest,
                        isDarkMode: isDarkMode,
                        color: AppColors.secondaryAccent,
                        ref: ref,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        'Subscription will renew automatically. Cancel anytime in settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required String icon,
    required String title,
    required String subtitle,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required bool isDarkMode,
    required Color color,
    required WidgetRef ref,
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? color : (isDarkMode ? Colors.white10 : Colors.black12),
          width: isPopular ? 2 : 1,
        ),
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        boxShadow: isPopular 
          ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]
          : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white10),
                ),
                
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : AppColors.textPrimaryDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () {
                      if (tier == SubscriptionTier.seedling) {
                        ref.read(settingsProvider.notifier).updateSubscription(tier);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Welcome back to the Free Tier!'),
                            backgroundColor: color,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(tier: tier, price: price),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey.withOpacity(0.2) : color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isCurrent ? 'Current Plan' : 'Select Plan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
