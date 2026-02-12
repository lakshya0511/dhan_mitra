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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonData['title']),
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
          final int backendWatched =
          (videoProgress?['watchedSeconds'] ?? 0) as int;

          return YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
              progressColors: ProgressBarColors(
                playedColor: cs.primary,
                handleColor: cs.primary,
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // VIDEO
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: player,
                    ),

                    const SizedBox(height: 24),

                    // SCRIPT HEADER
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 20, color: cs.secondary),
                        const SizedBox(width: 8),
                        Text(
                          "Lesson Script",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // SCRIPT
                    Expanded(
                      child: ListView.builder(
                        itemCount: script.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            script[i],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: cs.onSurface.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ACTIONS
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: lessonCompleted
                            ? null
                            : () {
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
                          lessonCompleted
                              ? "Lesson Completed"
                              : "Start Practice Quiz",
                        ),
                      ),
                    ),

                    if (lessonCompleted) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text("View Performance Feedback"),
                          onPressed: () {
                            _stopVideo();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FeedbackPage(lessonId: widget.lessonId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
