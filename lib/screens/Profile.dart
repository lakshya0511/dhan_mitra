import 'package:dhan_mitra/screens/practice_dashboard.dart';
import 'package:dhan_mitra/screens/virtual_trading/trading_home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';

import '../main.dart';
import 'Learning/finance_sections_page.dart';
import 'Login/auth_page.dart';
import 'dashboard.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
              (route) => false,
        );
      }
    }
  }

  Map<String, dynamic> getUserStage(int points, String gender) {
    final bool isMale = gender.toLowerCase() == 'male';

    final String imagePath = isMale
        ? 'assets/profile_stages/male.png'
        : 'assets/profile_stages/female_logo.png';

    String stageName;
    Color stageColor;

    if (points >= 700) {
      stageName = 'Financial Pro';
      stageColor = Colors.purple;
    } else if (points >= 300) {
      stageName = 'Skilled Planner';
      stageColor = Colors.blue;
    } else if (points >= 100) {
      stageName = 'Dedicated Learner';
      stageColor = Colors.green;
    } else {
      stageName = 'Finance Beginner';
      stageColor = Colors.grey;
    }

    return {
      'name': stageName,
      'color': stageColor,
      'image': imagePath,
    };
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            "assets/logo_without_tagline.png",
            height: 58,
            fit: BoxFit.contain,
          ),
        ),
        title: const Text("My Profile"),
        actions: [
          IconButton(
            tooltip: "Toggle Theme",
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              MoneyMitraApp.of(context)?.toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
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

          final user =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final wallet = user['wallet'] ?? {};
          final lessonProgress =
              user['lessonProgress'] as Map<String, dynamic>? ?? {};

          final int points = wallet['points'] ?? 0;
          final gender = user['gender'] ?? 'Male';
          final stage = getUserStage(points, gender);
          final completedLessons = lessonProgress.values
              .where((l) => l['completedAt'] != null)
              .length;

          return SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: stage['color'], width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: cs.surfaceVariant,
                          backgroundImage:
                          AssetImage(stage['image']),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(stage['name']),
                        backgroundColor:
                        stage['color'].withOpacity(0.1),
                        side: BorderSide(color: stage['color']),
                        labelStyle: TextStyle(
                            color: stage['color'],
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user['name'] ?? "User",
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Text("Financial Standing",
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.outline,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.auto_awesome,
                        label: "Points",
                        value: "$points XP",
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _StatCard(
                        label: "Balance",
                        value:
                        ((wallet['balance'] as num?)?.toDouble() ?? 0.0)
                            .toStringAsFixed(0) + " Coins",
                        color: Colors.green,
                        leading: SvgPicture.asset(
                          'assets/icons/gold_coin.svg',
                          height: 22,
                          width: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _StatCard(
                  icon: Icons.school_rounded,
                  label: "Learning Milestone",
                  value:
                  "$completedLessons Lessons Completed",
                  color: cs.primary,
                  isFullWidth: true,
                ),

                const SizedBox(height: 32),

                Text(
                  "Account Details",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _DetailTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: user['email'] ?? "-",
                ),
                _DetailTile(
                  icon: Icons.phone_android_outlined,
                  label: "Phone",
                  value: (user['phone'] as String?)
                      ?.replaceFirst(RegExp(r'^\+91'), '')
                      .trim() ??
                      "-",
                ),
                _DetailTile(
                  icon: Icons.location_on_outlined,
                  label: "City",
                  value: user['city'] ?? "-",
                ),

                const SizedBox(height: 22),

                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 40, // smaller height
                    child: FilledButton.icon(
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 14),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.school), label: "Lessons"),
          NavigationDestination(
              icon:  Icon(Icons.currency_rupee), label: "Practice Paisa"),
          NavigationDestination(
              icon: Icon(Icons.person), label: "Profile"),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinanceSectionsPage(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PracticeDashboardPage(),
              ),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              ),
            );
          }
        },
      ),
    );
  }
}

// ================= SUPPORTING WIDGETS =================

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;
  final Color color;
  final bool isFullWidth;

  const _StatCard({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize:
        isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Icon or Custom Leading Widget
          if (leading != null)
            leading!
          else if (icon != null)
            Icon(icon, color: color),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        color: cs.surface,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
