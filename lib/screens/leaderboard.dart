import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('wallet.points', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text("No rankings available yet"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;

              final wallet = data['wallet'] ?? {};
              final points = wallet['points'] ?? 0;
              final name = data['name'] ?? "User";
              final userId = users[index].id;

              final bool isCurrentUser = userId == uid;

              return _LeaderboardTile(
                rank: index + 1,
                name: name,
                points: points,
                highlight: isCurrentUser,
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final bool highlight;

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.points,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Define colors for Top 3
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.orange; // Gold
    } else if (rank == 2) {
      rankColor = Colors.blueGrey; // Silver
    } else if (rank == 3) {
      rankColor = Colors.brown; // Bronze
    } else {
      rankColor = cs.surfaceVariant;
    }

    return Card(
      elevation: 0, // Set to 0 to match your minimalist/flat theme
      margin: const EdgeInsets.only(bottom: 10),
      color: highlight ? cs.primaryContainer.withOpacity(0.3) : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight ? cs.primary : cs.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: rankColor,
            shape: BoxShape.circle,
            boxShadow: rank <= 3
                ? [BoxShadow(color: rankColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            rank <= 3 ? "🏆" : "#$rank",
            style: TextStyle(
              color: rank <= 3 ? Colors.white : cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: rank <= 3 ? 18 : 14,
            ),
          ),
        ),
        title: Text(
          highlight ? "$name (You)" : name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              points.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            Text(
              "Points",
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}