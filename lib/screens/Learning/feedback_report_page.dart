import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  final String lessonId;

  const FeedbackPage({
    super.key,
    required this.lessonId,
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUser() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getLesson() {
    return FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Learning Summary")),
      body: FutureBuilder(
        future: Future.wait([_getUser(), _getLesson()]),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot<Map<String, dynamic>>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data![0].data();
          final lessonData = snapshot.data![1].data();

          if (userData == null || lessonData == null) {
            return const Center(child: Text("Data unavailable"));
          }

          final lessonProgress = userData['lessonProgress']?[lessonId] as Map<String, dynamic>?;

          if (lessonProgress == null) {
            return const Center(child: Text("Lesson progress missing"));
          }

          final quizProgress = lessonProgress['quiz'] ?? {};
          final Map<String, dynamic> answers = Map<String, dynamic>.from(quizProgress['answers'] ?? {});
          final Map<String, dynamic> reflections = Map<String, dynamic>.from(quizProgress['reflections'] ?? {});

          final List questions = List.from(lessonData['quiz']?['questions'] ?? []);

          final Map<String, dynamic> questionMap = {for (var q in questions) q['id']: q};

          if (answers.isEmpty) {
            return const Center(child: Text("No answers recorded."));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: answers.entries.map((entry) {
              final questionId = entry.key;
              final answer = Map<String, dynamic>.from(entry.value);
              final question = questionMap[questionId] as Map<String, dynamic>?;

              final String questionText = question?['question'] ?? 'Decision';
              final String selectedKey = answer['selectedOption'] ?? '';
              final option = question?['options']?[selectedKey];
              final String optionText = option?['text'] ?? selectedKey;

              final String outcome = answer['outcome'] ?? '';
              final int paisa = (answer['paisa'] as num?)?.toInt() ?? 0;

              final reflection = reflections[questionId] as Map<String, dynamic>?;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "DECISION",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Question Text
                      Text(
                        questionText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selection Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your choice:",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              optionText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Outcome
                      Text(
                        "Outcome",
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outcome,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Financial Impact (Paisa)
                      if (paisa != 0)
                        Row(
                          children: [
                            Icon(
                              paisa > 0 ? Icons.trending_up : Icons.trending_down,
                              size: 20,
                              color: paisa > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              paisa > 0
                                  ? "Gained: ₹${paisa ~/ 100}"
                                  : "Lost: ₹${(paisa.abs()) ~/ 100}",
                              style: TextStyle(
                                color: paisa > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                      // Reflection Section
                      if (reflection != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            Icon(Icons.psychology, size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Your Reflection",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reflection['userAnswer'] ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}