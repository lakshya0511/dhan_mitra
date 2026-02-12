import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lesson_detail_page.dart';

class LessonsListPage extends StatefulWidget {
  final String sectionId;
  final String sectionTitle;

  const LessonsListPage({
    Key? key,
    required this.sectionId,
    required this.sectionTitle,
  }) : super(key: key);

  @override
  State<LessonsListPage> createState() => _LessonsListPageState();
}

class _LessonsListPageState extends State<LessonsListPage> {
  String selectedLanguage = "EN";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Query lessonsQuery = FirebaseFirestore.instance
        .collection('lessons')
        .where('sectionId', isEqualTo: widget.sectionId)
        .where('language', isEqualTo: selectedLanguage);

    return Scaffold(
      appBar: AppBar(title: Text(widget.sectionTitle)),

      body: StreamBuilder<QuerySnapshot>(
        stream: lessonsQuery.snapshots(),
        builder: (context, lessonSnap) {
          if (!lessonSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessons = lessonSnap.data!.docs;
          final totalLessons = lessons.length;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {

              final userData =
              userSnap.data?.data() as Map<String, dynamic>?;

              final progress =
                  userData?['lessonProgress'] as Map<String, dynamic>? ?? {};

              final completedLessons = lessons.where((doc) {
                return progress[doc.id]?['completedAt'] != null;
              }).length;

              final double progressValue =
              totalLessons == 0
                  ? 0
                  : completedLessons / totalLessons;

              return Column(
                children: [

                  // ================= LANGUAGE FILTER (M3) =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: DropdownMenu<String>(
                      initialSelection: selectedLanguage,
                      label: const Text("Select Language"),
                      width: double.infinity,
                      onSelected: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "EN",
                          label: "English",
                        ),
                        DropdownMenuEntry(
                          value: "KN",
                          label: "Kannada",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ================= PROGRESS HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Section Progress",
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                color:
                                colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${(progressValue * 100).toInt()}%",
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 10,
                            backgroundColor:
                            colorScheme.surfaceVariant,
                            valueColor:
                            AlwaysStoppedAnimation(
                                colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$completedLessons of $totalLessons lessons mastered",
                          style: theme.textTheme.labelMedium
                              ?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= LESSON AREA =================
                  Expanded(
                    child: totalLessons == 0
                        ? _buildEmptyState(theme, colorScheme)
                        : ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16),
                      itemCount: totalLessons,
                      itemBuilder:
                          (context, index) {

                        final lessonDoc =
                        lessons[index];
                        final lessonData =
                        lessonDoc.data()
                        as Map<String, dynamic>;

                        final lessonId =
                            lessonDoc.id;

                        final bool isMandatory =
                            lessonData['isMandatory'] == true;

                        final bool isCompleted =
                            progress[lessonId]?['completedAt'] != null;

                        final int points =
                        (lessonData['points'] ?? 0) as int;

                        return Card(
                          elevation: 0,
                          margin:
                          const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isCompleted
                                  ? colorScheme.primary
                                  .withOpacity(0.6)
                                  : colorScheme.outlineVariant,
                              width: isCompleted ? 1.5 : 1,
                            ),
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.fromLTRB(
                                16, 10, 12, 10),
                            title: Text(
                              lessonData['title'] ??
                                  'Untitled Lesson',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                              const EdgeInsets.only(top: 6),
                              child: isCompleted
                                  ? _buildPointsEarned(
                                points,
                                theme,
                                colorScheme,
                              )
                                  : _buildStatusBadge(
                                isMandatory,
                                theme,
                                colorScheme,
                              ),
                            ),
                            trailing:
                            _buildTrailingIcon(
                              isCompleted,
                              colorScheme,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LessonDetailPage(
                                        lessonId:
                                        lessonId,
                                        lessonData:
                                        lessonData,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 60, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            "No lessons available",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Try selecting a different language.",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
      bool isMandatory,
      ThemeData theme,
      ColorScheme colorScheme) {
    final color = isMandatory
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMandatory)
          Icon(Icons.assignment_late_outlined,
              size: 14, color: color),
        if (isMandatory)
          const SizedBox(width: 6),
        if (isMandatory)
          Text(
            "MANDATORY",
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
      ],
    );
  }

  Widget _buildPointsEarned(
      int points,
      ThemeData theme,
      ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events_rounded,
            size: 14, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          "+$points points earned",
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(
      bool isCompleted,
      ColorScheme colorScheme) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check,
            size: 16, color: Colors.white),
      );
    }
    return Icon(Icons.chevron_right_rounded,
        color: colorScheme.outline);
  }
}
