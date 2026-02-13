import 'package:dhan_mitra/components/models/user_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Rewards Store")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userService.userStream(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
          userSnap.data!.data() as Map<String, dynamic>;
          final wallet = userData['wallet'] ?? {};
          final points = wallet['points'] ?? 0;
          final redeemed =
          List<String>.from(wallet['redeemedOffers'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rewards')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (context, rewardsSnap) {
              if (!rewardsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rewards = rewardsSnap.data!.docs;
              final availableRewards = rewards
                  .where((r) => !redeemed.contains(r.id))
                  .toList();
              final claimedRewards = rewards
                  .where((r) => redeemed.contains(r.id))
                  .toList();

              return ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                children: [

                  // ================= POINTS HEADER =================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.85),
                          cs.primary.withOpacity(0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Your Total Balance",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.orangeAccent,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$points Points",
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  _SectionHeader(
                      title: "Available Offers",
                      count: availableRewards.length),
                  const SizedBox(height: 16),

                  if (availableRewards.isEmpty)
                    const _EmptyState(
                        message:
                        "Check back later for more rewards!")
                  else
                    ...availableRewards.map((doc) {
                      final r =
                      doc.data() as Map<String, dynamic>;
                      final bool canAfford =
                          points >= r['costPoints'];

                      return _RewardVoucher(
                        title: r['title'],
                        points: r['costPoints'],
                        cash: (r['paisaReward'] / 100)
                            .toStringAsFixed(0),
                        canAfford: canAfford,
                        onClaim: () async {
                          try {
                            await userService.claimReward(
                              rewardId: doc.id,
                              costPoints: r['costPoints'],
                              paisaReward:
                              r['paisaReward'],
                            );
                            _showSuccess(
                              context,
                              "${(r['paisaReward'] / 100).toStringAsFixed(0)} coins added to wallet!",
                            );
                          } catch (e) {
                            _showError(context,
                                e.toString());
                          }
                        },
                      );
                    }),

                  const SizedBox(height: 32),

                  _SectionHeader(
                      title: "Past Redemptions",
                      count: claimedRewards.length),
                  const SizedBox(height: 16),

                  ...claimedRewards.map((doc) {
                    final r =
                    doc.data() as Map<String, dynamic>;
                    return _ClaimedTile(
                      title: r['title'],
                      points: r['costPoints'],
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent),
    );
  }
}

// ================= CUSTOM UI COMPONENTS =================

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(
      {required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (count > 0)
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .primary),
            ),
          ),
      ],
    );
  }
}

class _RewardVoucher extends StatelessWidget {
  final String title;
  final int points;
  final String cash;
  final bool canAfford;
  final VoidCallback onClaim;

  const _RewardVoucher({
    required this.title,
    required this.points,
    required this.cash,
    required this.canAfford,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: canAfford
                ? cs.primary.withOpacity(0.5)
                : cs.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.wallet_giftcard_rounded,
                color: canAfford
                    ? cs.primary
                    : cs.outline),
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            subtitle: Text(
                "$points points required"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/gold_coin.svg',
                  height: 18,
                  width: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  cash,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: canAfford
                        ? Colors.green
                        : cs.outline,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                canAfford ? onClaim : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canAfford
                      ? cs.primary
                      : cs.surfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          12)),
                ),
                child: Text(canAfford
                    ? "Redeem Now"
                    : "Need ${points} Points"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimedTile extends StatelessWidget {
  final String title;
  final int points;

  const _ClaimedTile(
      {required this.title,
        required this.points});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 8),
        padding:
        const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceVariant
              .withOpacity(0.3),
          borderRadius:
          BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
                Icons.check_circle_outline,
                size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            Text("-$points",
                style: const TextStyle(
                    fontWeight:
                    FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Text(message,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .outline)),
      ),
    );
  }
}
