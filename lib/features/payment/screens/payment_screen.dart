import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionTier tier;
  final String price;

  const PaymentScreen({
    super.key,
    required this.tier,
    required this.price,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _selectedMethod = 0; // 0: Card, 1: Apple Pay, 2: Google Pay
  bool _isProcessing = false;

  final TextEditingController _cardController = TextEditingController(text: '**** **** **** 4242');
  final TextEditingController _expiryController = TextEditingController(text: '12/26');
  final TextEditingController _cvvController = TextEditingController(text: '***');

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment delay
    await Future.delayed(const Duration(seconds: 2));
    
    await ref.read(authStateProvider.notifier).upgradeSubscription(widget.tier);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ${widget.tier.label} membership is now active.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close payment screen
                  Navigator.pop(context); // Close subscription screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDarkMode),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(isDarkMode),
                      const SizedBox(height: 32),
                      const Text(
                        'Payment Method',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildMethodSelector(isDarkMode),
                      const SizedBox(height: 32),
                      if (_selectedMethod == 0) _buildCardForm(isDarkMode),
                      if (_selectedMethod != 0) _buildWalletPrompt(isDarkMode),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Text(
            'Payment Details',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MindBloom ${widget.tier.label}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Monthly Subscription',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            widget.price,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDarkMode) {
    return Row(
      children: [
        _methodBtn(0, Icons.credit_card_rounded, 'Card'),
        const SizedBox(width: 12),
        _methodBtn(1, Icons.apple, 'Apple Pay'),
        const SizedBox(width: 12),
        _methodBtn(2, Icons.payment_rounded, 'Google Pay'),
      ],
    );
  }

  Widget _methodBtn(int index, IconData icon, String label) {
    final isSelected = _selectedMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm(bool isDarkMode) {
    return Column(
      children: [
        _buildTextField('Card Number', _cardController, Icons.credit_card),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Expiry Date', _expiryController, Icons.calendar_month)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('CVV', _cvvController, Icons.lock_outline)),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildWalletPrompt(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(
            _selectedMethod == 1 ? Icons.apple : Icons.payment_rounded,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Pay with ${_selectedMethod == 1 ? "Apple Pay" : "Google Pay"}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryAccent, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Confirm & Pay ${widget.price}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
