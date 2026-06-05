import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

class ExamScreen extends StatefulWidget {
  final String specialization;
  const ExamScreen({super.key, required this.specialization});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  bool _hasStarted = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<String, String> _selectedAnswers = {};
  
  // Results state
  bool _showResult = false;
  bool _passed = false;
  int _score = 0;
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startExam() async {
    final userId = SessionService().userId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _hasStarted = true;
    });

    try {
      final questions = await ApiService.generateExam(
        tutorId: userId,
        specialization: widget.specialization,
      );
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasStarted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load exam: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _submitExam() async {
    final userId = SessionService().userId;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await ApiService.submitExam(
        tutorId: userId,
        specialization: widget.specialization,
        answers: _selectedAnswers,
      );
      
      setState(() {
        _isSubmitting = false;
        _showResult = true;
        _passed = result['passed'] ?? false;
        _score = result['score'] ?? 0;
        _totalQuestions = result['total'] ?? 5;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit exam: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _selectOption(String questionId, String option) {
    setState(() {
      _selectedAnswers[questionId] = option;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitExam();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _resetExam() {
    setState(() {
      _hasStarted = false;
      _isLoading = false;
      _isSubmitting = false;
      _questions = [];
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _showResult = false;
      _passed = false;
      _score = 0;
      _totalQuestions = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Skill Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStateView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    if (_isSubmitting) {
      return _buildSubmittingView();
    }
    if (_showResult) {
      return _buildResultView();
    }
    if (!_hasStarted) {
      return _buildInstructionsView();
    }
    if (_isLoading) {
      return _buildLoadingView();
    }
    if (_questions.isEmpty) {
      return _buildEmptyStateView();
    }
    return _buildQuizView();
  }

  Widget _buildInstructionsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey('instructions'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology_rounded,
            size: 80,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'AI Competency Exam',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Verify your specialization: ${widget.specialization.toUpperCase()}',
          style: const TextStyle(color: AppTheme.secondaryOrange, fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: [
              _buildInstructionRow(Icons.rule_rounded, '5 Multiple Choice Questions'),
              const SizedBox(height: 16),
              _buildInstructionRow(Icons.timer_outlined, 'No time limit, take your time'),
              const SizedBox(height: 16),
              _buildInstructionRow(Icons.check_circle_outline_rounded, 'Must score at least 3/5 (60%) to pass'),
              const SizedBox(height: 16),
              _buildInstructionRow(Icons.lock_open_rounded, 'Passing unlocks full course & shorts upload features'),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text(
              'START VERIFICATION EXAM',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryPurple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Column(
      key: ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primaryPurple)),
        SizedBox(height: 24),
        Text('Generating AI Skill Exam questions...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        SizedBox(height: 8),
        Text('Tailoring exam to your specialization', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSubmittingView() {
    return const Column(
      key: ValueKey('submitting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.secondaryOrange)),
        SizedBox(height: 24),
        Text('Checking answers against AI key...', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        SizedBox(height: 8),
        Text('Calculating your competency grade', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyStateView() {
    return Column(
      key: const ValueKey('empty'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorRed),
        const SizedBox(height: 16),
        const Text('No questions found for this specialty.', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _resetExam,
          child: const Text('Go Back'),
        )
      ],
    );
  }

  Widget _buildQuizView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuestion = _questions[_currentQuestionIndex];
    final String questionId = currentQuestion['id'];
    final String questionText = currentQuestion['question'] ?? 'No Question';
    final List<dynamic> options = currentQuestion['options'] ?? [];
    final String? selectedOption = _selectedAnswers[questionId];
    
    double progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      key: ValueKey('quiz_$_currentQuestionIndex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPurple),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${_currentQuestionIndex + 1} / ${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Question Card
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUESTION ${_currentQuestionIndex + 1}',
                  style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  questionText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 32),
                // Options list
                ...options.map((option) {
                  final isSelected = selectedOption == option;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? AppTheme.primaryPurple.withValues(alpha: 0.1) 
                        : (isDark ? AppTheme.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                          ? AppTheme.primaryPurple 
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
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
                      onTap: () => _selectOption(questionId, option),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryPurple : Colors.grey,
                                  width: 2,
                                ),
                                color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
                              ),
                              child: isSelected 
                                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryPurple : (isDark ? Colors.white : Colors.black87)
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentQuestionIndex > 0)
              TextButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryPurple),
                label: const Text('PREVIOUS', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton(
              onPressed: selectedOption == null ? null : _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentQuestionIndex == _questions.length - 1 ? 'SUBMIT EXAM' : 'NEXT',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentQuestionIndex == _questions.length - 1 ? Icons.check_circle : Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('result'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Animated icon
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: (_passed ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _passed ? Icons.verified_rounded : Icons.cancel_rounded,
            size: 100,
            color: _passed ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 32),
        // Heading
        Text(
          _passed ? 'Verification Passed! 🎉' : 'Verification Failed',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _passed 
            ? 'Congratulations! Your expertise has been verified by our AI system.' 
            : 'You did not pass the minimum threshold (3/5) for this specialization.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Score banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: [
              const Text('YOUR SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold, 
                      color: _passed ? AppTheme.successGreen : AppTheme.errorRed
                    ),
                  ),
                  Text(
                    ' / $_totalQuestions',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _passed ? 'ACCURACY: ${((_score / _totalQuestions) * 100).toInt()}%' : 'REQUIRED: 60% (3/5)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Buttons
        if (_passed)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Return true to indicate passing
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RETURN TO COMMAND CENTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _resetExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('RETRY EXAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
