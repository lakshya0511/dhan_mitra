import 'package:flutter/material.dart';
import '../../components/models/learning_database.dart';
import 'feedback_report_page.dart';

class QuizPage extends StatefulWidget {
  final String lessonId;
  final Map<String, dynamic> lessonData;

  const QuizPage({
    super.key,
    required this.lessonId,
    required this.lessonData,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final LearningService _learning = LearningService();

  late final List<Map<String, dynamic>> questions;
  late final int totalScore;

  int questionIndex = 0;
  int obtainedScore = 0;

  bool isSubmitting = false;
  bool lessonCompleted = false;

  String? selectedDecisionOption;
  Map<String, dynamic>? selectedDecisionData;
  String? selectedReflectionOption;

  @override
  void initState() {
    super.initState();

    questions = List<Map<String, dynamic>>.from(
      widget.lessonData['quiz']['questions'] ?? [],
    );

    totalScore = questions.fold<int>(
      0,
          (sum, q) => sum + ((q['weight'] as num?)?.toInt() ?? 0),
    );

    _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    final completed = await _learning.isLessonCompleted(widget.lessonId);
    if (completed && mounted) {
      setState(() => lessonCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (lessonCompleted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Completed")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "You have already completed this practice.\nYour answers are saved.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${questionIndex + 1}/${questions.length}"),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (questionIndex + 1) / questions.length,
            backgroundColor: cs.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(cs.primary),
            minHeight: 6,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: _buildQuestion(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final q = questions[questionIndex];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final decisionOptions = Map<String, dynamic>.from(q['options'] ?? {});
    final reflection = q['reflection'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q['question'] ?? "",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            children: [
              ...decisionOptions.entries.map((entry) {
                final key = entry.key;
                final option = Map<String, dynamic>.from(entry.value);

                final selected = selectedDecisionOption == key;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: selected ? cs.primary : cs.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: selected ? cs.primaryContainer.withOpacity(0.05) : null,
                  child: ListTile(
                    title: Text(
                      option['text'] ?? "",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    leading: Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      setState(() {
                        selectedDecisionOption = key;
                        selectedDecisionData = option;
                      });
                    },
                  ),
                );
              }),

              if (reflection != null) ...[
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 20),

                Text(
                  reflection['question'] ?? "",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...List.from(reflection['options'] ?? []).map((opt) {
                  final selected = selectedReflectionOption == opt.toString();

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: selected ? cs.primaryContainer.withOpacity(0.05) : null,
                    child: ListTile(
                      title: Text(
                        opt.toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      onTap: () {
                        setState(() {
                          selectedReflectionOption = opt.toString();
                        });
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _canSubmit() ? _submitBoth : null,
            child: isSubmitting
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text("Submit & Continue"),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    final reflection = questions[questionIndex]['reflection'];
    return selectedDecisionOption != null &&
        (reflection == null || selectedReflectionOption != null) &&
        !isSubmitting;
  }

  Future<void> _submitBoth() async {
    setState(() => isSubmitting = true);

    final q = questions[questionIndex];
    final option = selectedDecisionData!;

    final paisa = (option['paisa'] as num?)?.toInt() ?? 0;
    final score = (option['score'] as num?)?.toInt() ?? 0;

    obtainedScore += score;

    final futures = <Future>[
      _learning.saveDecisionAnswer(
        lessonId: widget.lessonId,
        questionId: q['id'],
        selectedOption: selectedDecisionOption!,
        outcomeText: option['outcome'] ?? "",
        paisaAmount: paisa,
      ),
    ];

    if (q['reflection'] != null) {
      futures.add(
        _learning.saveDecisionReflection(
          lessonId: widget.lessonId,
          questionId: q['id'],
          answer: selectedReflectionOption!,
        ),
      );
    }

    await Future.wait(futures);

    setState(() {
      selectedDecisionOption = null;
      selectedDecisionData = null;
      selectedReflectionOption = null;
      isSubmitting = false;
    });

    _goNext();
  }

  void _goNext() {
    if (questionIndex < questions.length - 1) {
      setState(() => questionIndex++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FeedbackPage(lessonId: widget.lessonId),
        ),
      );

      _learning.completeLesson(
        lessonId: widget.lessonId,
        obtainedScore: obtainedScore,
        totalScore: totalScore,
      );
    }
  }
}
