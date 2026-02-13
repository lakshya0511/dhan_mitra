import 'package:dhan_mitra/components/models/user_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RewardHistoryPage extends StatelessWidget {
  const RewardHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reward History"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userService.userStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user =
          snap.data!.data() as Map<String, dynamic>;
          final redeemed = List<String>.from(
              user['wallet']['redeemedOffers'] ?? []);

          if (redeemed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(Icons.redeem_outlined,
                      size: 64,
                      color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    "No rewards claimed yet",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            itemCount: redeemed.length,
            itemBuilder: (context, index) {
              final rewardId = redeemed[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('rewards')
                    .doc(rewardId)
                    .get(),
                builder: (context, rewardSnap) {
                  if (!rewardSnap.hasData) {
                    return Container(
                      height: 80,
                      margin: const EdgeInsets.only(
                          bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant
                            .withOpacity(0.3),
                        borderRadius:
                        BorderRadius.circular(
                            16),
                      ),
                    );
                  }

                  final r = rewardSnap.data!.data()
                  as Map<String, dynamic>?;

                  if (r == null)
                    return const SizedBox();

                  return Container(
                    margin:
                    const EdgeInsets.only(
                        bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                      border: Border.all(
                          color:
                          cs.outlineVariant),
                      color: cs.surface,
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8),
                      leading: Container(
                        padding:
                        const EdgeInsets.all(
                            10),
                        decoration: BoxDecoration(
                          color: Colors.orange
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius
                              .circular(
                              12),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      title: Text(
                        r['title'] ??
                            "Reward",
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Redeemed for ${r['costPoints']} points",
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color:
                          cs.onSurfaceVariant,
                        ),
                      ),

                      // ✅ Coin Instead of ₹
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                        children: [
                          Row(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/gold_coin.svg',
                                height: 18,
                                width: 18,
                              ),
                              const SizedBox(
                                  width: 6),
                              Text(
                                (r['paisaReward'] /
                                    100)
                                    .toStringAsFixed(
                                    0),
                                style: theme
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                  color:
                                  Colors
                                      .green,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Earned",
                            style: theme
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              color:
                              cs.outline,
                            ),
                          ),
                        ],
                      ),
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
