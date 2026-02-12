import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../components/models/learning_database.dart';
import 'quiz_page.dart';
import 'feedback_report_page.dart';

class LessonDetailPage extends StatefulWidget {
  final String lessonId;
  final Map<String, dynamic> lessonData;

  const LessonDetailPage({
    super.key,
    required this.lessonId,
    required this.lessonData,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late final YoutubePlayerController _controller;
  Timer? _timer;

  final LearningService _learning = LearningService();

  int watchedSeconds = 0;
  int lastPosition = 0;
  late final int totalSeconds;

  bool _playerReady = false;

  @override
  void initState() {
    super.initState();

    final video = widget.lessonData['video'];
    totalSeconds = (video['durationSeconds'] as num).toInt();

    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(video['url'])!,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        disableDragSeek: true,
        enableCaption: true,
      ),
    );

    _learning.initLesson(
      lessonId: widget.lessonId,
      sectionId: widget.lessonData['sectionId'],
      totalVideoSeconds: totalSeconds,
      isMandatory: widget.lessonData['isMandatory'] ?? false,
      points: (widget.lessonData['rewardPaisa'] as num?)?.toInt() ?? 0,
    );
  }

  void _startTracking() {
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_playerReady) return;

      final current = _controller.value.position.inSeconds;

      if (current > lastPosition && current - lastPosition <= 3) {
        watchedSeconds += current - lastPosition;

        _learning.updateVideoProgress(
          lessonId: widget.lessonId,
          watchedSeconds: watchedSeconds,
          totalSeconds: totalSeconds,
        );
      }

      lastPosition = current;
    });
  }

  void _stopVideo() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    }
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopVideo();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final video = widget.lessonData['video'];
    final script = List<String>.from(video['script']);
    final title = widget.lessonData['title'];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: Text("Lesson View", style: theme.textTheme.titleMedium),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final lesson = userData?['lessonProgress']?[widget.lessonId];
          final videoProgress = lesson?['video'];

          final bool lessonCompleted = lesson?['score'] != null;
          final int backendWatched = (videoProgress?['watchedSeconds'] ?? 0) as int;

          // UI calculation only
          double progressPercent = (totalSeconds > 0) ? (watchedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

          return YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
              progressColors: ProgressBarColors(
                playedColor: cs.primary,
                handleColor: cs.primary,
                bufferedColor: cs.primaryContainer,
              ),
              onReady: () {
                if (_playerReady) return;
                _playerReady = true;

                if (backendWatched > 0) {
                  _controller.seekTo(Duration(seconds: backendWatched));
                  watchedSeconds = backendWatched;
                  lastPosition = backendWatched;
                }

                _startTracking();
              },
            ),
            builder: (context, player) {
              return Column(
                children: [
                  // VIDEO SECTION
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: player,
                  ),

                  // CONTENT SECTION
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // SCRIPT HEADER
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.menu_book_rounded, size: 18, color: cs.onSecondaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Lesson Script",
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // SCRIPT LIST
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                itemCount: script.length,
                                itemBuilder: (_, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    script[i],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ACTION BUTTONS
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: lessonCompleted ? null : () {
                                      _stopVideo();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuizPage(
                                            lessonId: widget.lessonId,
                                            lessonData: widget.lessonData,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      lessonCompleted ? "Lesson Completed" : "Start Practice Quiz",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                if (lessonCompleted) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: BorderSide(color: cs.primary),
                                      ),
                                      icon: const Icon(Icons.analytics_outlined),
                                      label: const Text("View Performance Feedback"),
                                      onPressed: () {
                                        _stopVideo();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FeedbackPage(lessonId: widget.lessonId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
}