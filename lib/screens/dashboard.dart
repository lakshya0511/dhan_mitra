import 'package:dhan_mitra/screens/rewards_page.dart';
import 'package:dhan_mitra/screens/virtual_trading/portfolio_page.dart' show PortfolioPage;
import 'package:dhan_mitra/screens/virtual_trading/trading_home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/models/feedback_database.dart';
import '../components/models/trading/trading_database.dart';
import 'Learning/continue_lesson_page.dart';
import 'Learning/finance_sections_page.dart';
import 'about_us.dart';
import 'leaderboard.dart';
import 'virtual_trading/mandatory_status_check.dart';
import 'Profile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      TradingService().autoUnlockTradingIfEligible();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

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
        title: const Text("धन Mitra"),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RewardsPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: _UserDashboardSection(uid: uid),

      // BOTTOM NAV
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.school), label: "Lessons"),
          NavigationDestination(
              icon: Icon(Icons.trending_up), label: "Trading"),
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
                builder: (_) => const TradingHomePage(),
              ),
            );
          }
          else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
          }
        },
      ),
    );
  }
}

class _UserDashboardSection extends StatelessWidget {
  final String uid;

  const _UserDashboardSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
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
        final lessonProgress = user['lessonProgress'] ?? {};
        final trading = user['trading'] ?? {};

        final double balance =
            (wallet['balance'] as num?)?.toDouble() ?? 0.0;
        final int points = wallet['points'] ?? 0;

        final completedLessons = lessonProgress.values
            .where((l) => l['completedAt'] != null)
            .length;

        final int totalLessons = lessonProgress.length;
        final double progress =
        totalLessons == 0 ? 0 : completedLessons / totalLessons;

        final bool tradingUnlocked = trading['unlocked'] == true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back, ${firstName(user['name'])}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Keep building smart money habits",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// DASHBOARD CARD
              _DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(
                          label: "Points",
                          value: points.toString(),
                          icon: Icons.star,
                        ),

                        if (balance > 0)
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/gold_coin.svg',
                                height: 25,
                                width: 25,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                balance.toStringAsFixed(0),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),

                    Text(
                      "Learning Progress",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$completedLessons of $totalLessons lessons completed",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// QUICK ACTIONS
              Text(
                "Quick Actions",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ActionFlashCard(
                      icon: Icons.play_circle_fill,
                      title: "Continue Learning",
                      subtitle: "Resume your last lesson",
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ContinueLearningPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionFlashCard(
                      icon: Icons.trending_up,
                      title: "Portfolio",
                      subtitle: tradingUnlocked
                          ? "Practice Paisa Transition"
                          : "Complete mandatory lessons",
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => tradingUnlocked
                                ? const PortfolioPage()
                                : const MandatoryStatusPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// EXPLORE
              Text(
                "Explore",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ActionFlashCard(
                      icon: Icons.info_outline,
                      title: "About Us",
                      subtitle: "Know Money Mitra",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutUsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionFlashCard(
                      icon: Icons.leaderboard,
                      title: "Leaderboard",
                      subtitle: "Top performers",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              /// TEAM
              Center(
                child: Text(
                  "Meet Our Team",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TeamMember(
                          name: "Shambhavi Chandra",
                          photo_url: 'assets/team/Shambhavi.jpeg',
                          linkedin_url:
                          'https://www.linkedin.com/in/shambhavi-chandra-a0b899276/'),
                      _TeamMember(
                          name: "Pranjal Kakrania",
                          photo_url: 'assets/team/Pranjal.jpeg',
                          linkedin_url:
                          'https://www.linkedin.com/in/pranjal-kakrania-880685244/'),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TeamMember(
                          name: "Harshika Kamalia",
                          photo_url: 'assets/team/harshika.jpeg',
                          linkedin_url:
                          'https://www.linkedin.com/in/harshika-kamalia-0b1669380/'),
                      _TeamMember(
                          name: "Lakshya Singhi",
                          photo_url: 'assets/team/lakshya.jpeg',
                          linkedin_url:
                          'https://www.linkedin.com/in/lakshya-singhi-a3108736a/'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              /// CONTACT
              Text(
                "Contact & Feedback",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ContactRow(
                      icon: Icons.phone,
                      text: "+91 8607444486",
                    ),
                    const _ContactRow(
                      icon: Icons.email,
                      text: "info.dhanmitra@gmail.com",
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _FeedbackForm(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/* ================= FEEDBACK FORM ================= */
class _FeedbackForm extends StatefulWidget {
  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final TextEditingController controller = TextEditingController();
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Have suggestions or feedback?",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: "Write your feedback here...",
              hintStyle: TextStyle(color: colorScheme.outline),
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, // Made button full width for better accessibility
            height: 48,
            child: FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                if (controller.text.trim().isEmpty) return;
                setState(() => submitting = true);

                // Note: Ensure FeedbackService is imported correctly
                await FeedbackService()
                    .submitFeedback(message: controller.text.trim());

                if (!mounted) return;

                setState(() {
                  submitting = false;
                  controller.clear();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: const Text("Feedback submitted successfully!"),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: submitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Submit Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= UI HELPERS ================= */

class _DashboardCard extends StatelessWidget {
  final Widget child;
  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ActionFlashCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionFlashCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Card(
          elevation: 6,
          shadowColor: cs.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: isPrimary ? cs.primaryContainer : cs.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 30,
                  color:
                  isPrimary ? cs.onPrimaryContainer : cs.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? cs.onPrimaryContainer
                        : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPrimary
                        ? cs.onPrimaryContainer.withOpacity(0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String photo_url;
  final String linkedin_url;
  const _TeamMember({required this.name, required this.photo_url, required this.linkedin_url});

  Future<void> _openLinkedIn() async {
    final Uri url = Uri.parse(linkedin_url);
    // Ensure you have url_launcher in pubspec.yaml
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Matching your existing theme colors
    const Color scaffoldBg = Color(0xFF0D1B2A);
    const Color surfaceColor = Color(0xFF1B263B);
    const Color accentBlue = Colors.lightBlueAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Profile Photo with Premium Border
        GestureDetector(
          onTap: null,
          child: Container(
            padding: const EdgeInsets.all(3), // Border gap
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentBlue.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: surfaceColor,
              backgroundImage: AssetImage(photo_url),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Name with Bold Typography
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        // 3. Modernized LinkedIn Button
        // Replaced the light blue "bubble" with a sleek outlined style
        InkWell(
          onTap: _openLinkedIn,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/linkedin.svg',
                  height: 16,
                  width: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String firstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'Learner';
  return fullName.trim().split(' ').first;
}
