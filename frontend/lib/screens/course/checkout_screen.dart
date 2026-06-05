import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  const CheckoutScreen({super.key, required this.course});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'MTN'; // 'MTN' or 'Orange'
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showSuccess = false;

  double get _price {
    final raw = widget.course['price'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '0') ?? 0.0;
  }

  double get _tax => (_price * 0.1); // 10% tax
  double get _total => _price + _tax;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _triggerPayment() {
    if (!_formKey.currentState!.validate()) return;
    
    _showUssdDialog();
  }

  void _showUssdDialog() {
    final pinController = TextEditingController();
    final ussdFormKey = GlobalKey<FormState>();
    bool processingUssd = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: _selectedMethod == 'MTN' ? const Color(0xFFFFFDE7) : const Color(0xFFFFF3E0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _selectedMethod == 'MTN' ? AppTheme.accentYellow : AppTheme.secondaryOrange,
                width: 2,
              )
            ),
            title: Row(
              children: [
                Icon(
                  Icons.phone_android_rounded, 
                  color: _selectedMethod == 'MTN' ? const Color(0xFFF57F17) : AppTheme.secondaryOrange
                ),
                const SizedBox(width: 12),
                Text(
                  '$_selectedMethod MoMo Push',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Form(
              key: ussdFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authorize payment of ${_total.toStringAsFixed(0)} fr to SkillSwap Pro.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your 4-digit PIN:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    enabled: !processingUssd,
                    decoration: const InputDecoration(
                      hintText: '••••',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (val) {
                      if (val == null || val.length != 4 || int.tryParse(val) == null) {
                        return 'Enter a 4-digit numeric PIN';
                      }
                      return null;
                    },
                  ),
                  if (processingUssd) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: processingUssd ? null : () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: processingUssd 
                  ? null 
                  : () async {
                      if (!ussdFormKey.currentState!.validate()) return;
                      
                      setStateSB(() => processingUssd = true);
                      
                      try {
                        final userId = SessionService().userId;
                        if (userId == null) throw Exception('User not logged in');

                        // 1. Checkout
                        final checkoutRes = await ApiService.createPayment(
                          userId: userId,
                          courseId: widget.course['id'],
                          amount: _price,
                          method: _selectedMethod,
                          phoneNumber: _phoneController.text.trim(),
                        );

                        final paymentId = checkoutRes['paymentId'];

                        // 2. Authorize
                        await ApiService.authorizePayment(
                          paymentId: paymentId,
                          pin: pinController.text.trim(),
                        );

                        // 3. Enroll
                        await ApiService.enrollCourse(
                          courseId: widget.course['id'],
                          studentId: userId,
                          instructorId: widget.course['instructorId'],
                          studentName: SessionService().fullName,
                          courseTitle: widget.course['title'],
                          instructorName: widget.course['instructorName'],
                          instructorAvatar: widget.course['instructorAvatarUrl'],
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          setState(() {
                            _showSuccess = true;
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment Failed: $e'),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod == 'MTN' 
                      ? const Color(0xFFF57F17) 
                      : AppTheme.secondaryOrange,
                ),
                child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showSuccess ? _buildSuccessView() : _buildCheckoutFormView(),
        ),
      ),
    );
  }

  Widget _buildCheckoutFormView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course card details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: AppTheme.primaryPurple, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course['title'] ?? 'Untitled Course',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tutor: ${widget.course['instructorName'] ?? 'Instructor'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Payment selection title
            const Text(
              'Select Mobile Money Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Method selectors
            Row(
              children: [
                _buildMethodCard('MTN', 'Mobile Money', AppTheme.accentYellow, const Color(0xFFF57F17), 'assets/images/mtn.png'),
                const SizedBox(width: 16),
                _buildMethodCard('Orange', 'Money', AppTheme.secondaryOrange, AppTheme.secondaryOrange, 'assets/images/orange.png'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Phone input
            const Text(
              'Mobile Money Phone Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              decoration: InputDecoration(
                hintText: '6XXXXXXXX',
                prefixText: '+237 ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Enter your phone number';
                }
                if (val.length != 9 || !val.startsWith('6')) {
                  return 'Must be 9 digits starting with 6';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Invoice summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInvoiceRow('Course Price', '${_price.toStringAsFixed(0)} fr'),
                  const SizedBox(height: 12),
                  _buildInvoiceRow('VAT Tax (10%)', '${_tax.toStringAsFixed(0)} fr'),
                  const Divider(height: 24),
                  _buildInvoiceRow(
                    'Total Payment', 
                    '${_total.toStringAsFixed(0)} fr', 
                    isBold: true,
                    textColor: _selectedMethod == 'MTN' ? const Color(0xFFF57F17) : AppTheme.secondaryOrange
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _triggerPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod == 'MTN' ? const Color(0xFFF57F17) : AppTheme.secondaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'PAY ${_total.toStringAsFixed(0)} FR NOW',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 15 : 14,
            color: isBold ? null : Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            fontSize: isBold ? 18 : 14,
            color: textColor ?? (isBold ? null : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(String id, String label, Color color, Color accent, String imgPath) {
    final isSelected = _selectedMethod == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.1) 
              : (isDark ? AppTheme.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : (isDark ? Colors.white10 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMethod = id;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
            child: Column(
              children: [
                // Branding Icon / Image fallback
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      id[0], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? accent : null,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 100,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Payment Successful! 🎉',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'You have been successfully enrolled in this course. Access materials instantly.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Return true to indicate enrollment success
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'START LEARNING', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
        ),
      ],
    );
  }
}
