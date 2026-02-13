import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhan_mitra/screens/Learning/finance_sections_page.dart';
import 'package:dhan_mitra/screens/Profile.dart';
import 'package:dhan_mitra/screens/dashboard.dart';
import 'package:dhan_mitra/screens/mutual_funds/mutual_fund_home.dart';
import 'package:dhan_mitra/screens/rewards_page.dart';
import 'package:dhan_mitra/screens/virtual_trading/trading_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PracticeDashboardPage extends StatelessWidget {
  const PracticeDashboardPage({super.key});

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(uid);

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

        title: const Text("Practice Paisa"),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
          snap.data!.data() as Map<String, dynamic>;


          final wallet =
          Map<String, dynamic>.from(userData['wallet'] ?? {});

          final double balance =
              (wallet['balance'] as num?)?.toDouble() ?? 0;

          final int points =
              (wallet['points'] as num?)?.toInt() ?? 0;

          // ================= HEALTH INDICATOR =================

          String healthText;
          Color healthColor;

          if (balance <= 0) {
            healthText = "At Risk";
            healthColor = Colors.red;
          } else if (balance < 5000) {
            healthText = "Needs Balance";
            healthColor = Colors.orange;
          } else {
            healthText = "Growing Well";
            healthColor = Colors.green;
          }

          // ================= MOTIVATIONAL MESSAGE =================

          String message;

          if (balance <= 0) {
            message =
            "Start practicing investments to build your portfolio.";
          } else if (balance < 5000) {
            message =
            "Build consistency through SIP or small trades.";
          } else if (balance < 20000) {
            message =
            "Your financial discipline is improving steadily.";
          } else {
            message =
            "You are managing your practice capital confidently.";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // ================= HERO CARD =================

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(0.15),
                        cs.secondary.withOpacity(0.15),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [

                      const Text(
                        "Practice Wallet Balance",
                        style: TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          coin(28),
                          const SizedBox(width: 10),
                          Text(
                            balance.toStringAsFixed(0),
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(
                                fontWeight:
                                FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Health Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(20),
                          border:
                          Border.all(color: healthColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 10,
                                color: healthColor),
                            const SizedBox(width: 6),
                            Text(
                              healthText,
                              style: TextStyle(
                                color: healthColor,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        message,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ================= ACTION BUTTONS =================

                _bigActionButton(
                  context,
                  icon: Icons.show_chart,
                  title: "Virtual Trading",
                  subtitle:
                  "Practice stock trading in real time",
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const TradingHomePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                _bigActionButton(
                  context,
                  icon: Icons.account_balance,
                  title: "Mutual Funds",
                  subtitle:
                  "SIP, SWP & long term investing",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const MutualFundHomePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // ================= REWARDS SECTION =================
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to rewards page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RewardsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 🔵 Fully rounded
                    ),
                  ),
                  child: const Text(
                    "Claim Rewards",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),

      // ================= BOTTOM NAV =================

      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home),
              label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.school),
              label: "Lessons"),
          NavigationDestination(
              icon: Icon(Icons.currency_rupee),
              label: "Practice Paisa"),
          NavigationDestination(
              icon: Icon(Icons.person),
              label: "Profile"),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const DashboardPage(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const FinanceSectionsPage(),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ProfilePage(),
              ),
            );
          }
        },
      ),
    );
  }

  // =====================================================
  // ================= BIG ACTION BUTTON =================
  // =====================================================

  Widget _bigActionButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor:
              color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme
                          .titleMedium
                          ?.copyWith(
                          fontWeight:
                          FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                      theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16),
          ],
        ),
      ),
    );
  }
}
