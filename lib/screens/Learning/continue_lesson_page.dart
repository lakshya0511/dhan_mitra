import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lesson_detail_page.dart';

class ContinueLearningPage extends StatelessWidget {
  const ContinueLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Continue Learning"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};
          final lessonProgress =
              user['lessonProgress'] as Map<String, dynamic>? ?? {};

          /// 🔥 Filter: lesson started but NOT completed
          final inProgressLessons = lessonProgress.entries.where((entry) {
            final data = entry.value as Map<String, dynamic>;

            final bool lessonCompleted =
                data['completedAt'] != null;

            final video =
                data['video'] as Map<String, dynamic>? ?? {};
            final int watchedSeconds =
                video['watchedSeconds'] ?? 0;

            final quiz =
                data['quiz'] as Map<String, dynamic>? ?? {};
            final answers =
                quiz['answers'] as Map<String, dynamic>? ?? {};

            final bool videoStarted = watchedSeconds > 0;
            final bool quizStarted = answers.isNotEmpty;

            return !lessonCompleted &&
                (videoStarted || quizStarted);
          }).toList();

          /// 🔥 Sort: latest updated first
          inProgressLessons.sort((a, b) {
            final aTime = (a.value['lastUpdatedAt'] ??
                a.value['startedAt']) as Timestamp;
            final bTime = (b.value['lastUpdatedAt'] ??
                b.value['startedAt']) as Timestamp;
            return bTime.compareTo(aTime);
          });

          if (inProgressLessons.isEmpty) {
            return Center(
              child: Text(
                "No lessons in progress 🙌",
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: inProgressLessons.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lessonId =
                  inProgressLessons[index].key;

              final progressData =
              inProgressLessons[index].value
              as Map<String, dynamic>;

              final video =
                  progressData['video']
                  as Map<String, dynamic>? ??
                      {};

              final int watchedSeconds =
                  video['watchedSeconds'] ?? 0;

              final bool videoStarted =
                  watchedSeconds > 0;

              final bool videoCompleted =
                  video['isCompleted'] == true;

              final quiz =
                  progressData['quiz']
                  as Map<String, dynamic>? ??
                      {};

              final answers =
                  quiz['answers']
                  as Map<String, dynamic>? ??
                      {};

              final bool quizStarted =
                  answers.isNotEmpty;

              /// 🔥 Clean learning state subtitle logic
              final String subtitle = quizStarted
                  ? "Continue quiz"
                  : videoStarted
                  ? "Continue watching"
                  : "Start lesson";

              /// 🔥 Icon logic
              final IconData icon = quizStarted
                  ? Icons.assignment
                  : Icons.play_circle_fill;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('lessons')
                    .doc(lessonId)
                    .get(),
                builder: (context, lessonSnap) {
                  if (!lessonSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  final lessonData =
                  lessonSnap.data!.data()
                  as Map<String, dynamic>?;

                  if (lessonData == null) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    elevation: 3,
                    shadowColor: colorScheme.primary
                        .withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Icon(
                        icon,
                        size: 28,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        lessonData['title'] ??
                            "Lesson $lessonId",
                        style: theme
                            .textTheme.titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(
                            top: 4),
                        child: Text(subtitle),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LessonDetailPage(
                                  lessonId: lessonId,
                                  lessonData:
                                  lessonData,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
