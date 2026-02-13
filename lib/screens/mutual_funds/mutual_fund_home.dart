import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_nav_simulator.dart';
import 'package:dhan_mitra/components/models/mutual_funds/sip_engine.dart';
import 'package:dhan_mitra/components/models/mutual_funds/swp_engine.dart';
import 'package:dhan_mitra/screens/virtual_trading/mandatory_status_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'buy_fund_sheet.dart';
import 'mutual_fund_portfolio.dart';
import '../../components/models/user_database.dart';

class MutualFundHomePage extends StatefulWidget {
  const MutualFundHomePage({super.key});

  @override
  State<MutualFundHomePage> createState() => _MutualFundHomePageState();
}

class _MutualFundHomePageState extends State<MutualFundHomePage> {
  final UserService userService = UserService();
  final TextEditingController _search = TextEditingController();

  String query = '';

  late final MutualFundNAVUpdater _navUpdater;
  late final SIPEngine _sipEngine;
  late final SWPEngine _swpEngine;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _navUpdater = MutualFundNAVUpdater();
    _sipEngine = SIPEngine();
    _swpEngine = SWPEngine();

    _search.addListener(() {
      setState(() {
        query = _search.text.toUpperCase();
      });
    });

    _startEngines();
  }

  void _startEngines() async {
    await _navUpdater.updateAllNAV();

    _timer = Timer.periodic(
      const Duration(minutes: 10),
          (_) async {
        await _navUpdater.updateAllNAV();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: Text("Unable to load user data")),
          );
        }

        final userData =
            userSnap.data!.data() as Map<String, dynamic>? ?? {};

        final bool tradingUnlocked =
            userData['trading']?['unlocked'] == true;

        // 🔒 SAME LOCK AS TRADING
        if (!tradingUnlocked) {
          return const MandatoryStatusPage();
        }

        // ✅ UNLOCKED → SHOW PAGE
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Mutual Funds",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: "My Portfolio",
                icon:
                const Icon(Icons.account_balance_wallet_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const MutualFundPortfolioPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // ================= WALLET CARD =================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: StreamBuilder<double>(
                  stream:
                  userService.walletBalanceStream(),
                  builder: (context, snapshot) {
                    final balance =
                        snapshot.data ?? 0;

                    return Card(
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                        side: BorderSide(
                            color: cs.outlineVariant),
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.all(
                                  10),
                              decoration: BoxDecoration(
                                color:
                                cs.primaryContainer,
                                shape:
                                BoxShape.circle,
                              ),
                              child: Icon(
                                Icons
                                    .account_balance_wallet,
                                color: cs
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  "Available Balance",
                                  style: theme
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const SizedBox(
                                    height: 4),
                                Row(
                                  children: [
                                    coin(22),
                                    const SizedBox(
                                        width: 6),
                                    Text(
                                      balance
                                          .toStringAsFixed(
                                          0),
                                      style: theme
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ================= SEARCH BAR =================

              Padding(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText:
                    "Search funds...",
                    prefixIcon:
                    const Icon(Icons.search),
                    filled: true,
                    fillColor:
                    cs.surfaceVariant
                        .withOpacity(0.2),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= FUND LIST =================

              Expanded(
                child:
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore
                      .instance
                      .collection('mf_nav')
                      .orderBy('nav')
                      .snapshots(),
                  builder:
                      (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child:
                          CircularProgressIndicator());
                    }

                    final docs = snap
                        .data!.docs
                        .where((doc) {
                      final id =
                      doc.id.toUpperCase();
                      return id
                          .contains(query);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child:
                        Text("No funds found"),
                      );
                    }

                    return ListView.builder(
                      padding:
                      const EdgeInsets.all(
                          16),
                      itemCount:
                      docs.length,
                      itemBuilder:
                          (_, i) {
                        final data =
                        docs[i].data()
                        as Map<
                            String,
                            dynamic>;

                        final double nav =
                        (data['nav']
                        as num)
                            .toDouble();

                        final double
                        changePercent =
                            (data['changePercent']
                            as num?)
                                ?.toDouble() ??
                                0.0;

                        final bool isUp =
                            changePercent >=
                                0;

                        return Card(
                          elevation: 0,
                          margin:
                          const EdgeInsets
                              .only(
                              bottom: 12),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                20),
                          ),
                          child: InkWell(
                            borderRadius:
                            BorderRadius
                                .circular(
                                20),
                            onTap: () {
                              showModalBottomSheet(
                                context:
                                context,
                                isScrollControlled:
                                true,
                                shape:
                                const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.vertical(
                                      top: Radius.circular(
                                          24)),
                                ),
                                builder:
                                    (_) =>
                                    BuyFundSheet(
                                      fundId:
                                      docs[i]
                                          .id,
                                      nav: nav,
                                    ),
                              );
                            },
                            child: Padding(
                              padding:
                              const EdgeInsets
                                  .all(
                                  16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                    cs.primaryContainer
                                        .withOpacity(
                                        0.3),
                                    child: Text(
                                      docs[i]
                                          .id
                                          .substring(
                                          0,
                                          1),
                                      style: TextStyle(
                                        color: cs
                                            .primary,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                      12),
                                  Expanded(
                                    child:
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          docs[i]
                                              .id,
                                          style: theme
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                            fontWeight:
                                            FontWeight
                                                .bold,
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                            4),
                                        Row(
                                          children: [
                                            coin(
                                                14),
                                            const SizedBox(
                                                width:
                                                4),
                                            Text(
                                              nav.toStringAsFixed(
                                                  2),
                                              style: theme
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal:
                                        8,
                                        vertical:
                                        4),
                                    decoration:
                                    BoxDecoration(
                                      color: isUp
                                          ? Colors.green.withOpacity(
                                          0.1)
                                          : Colors.red.withOpacity(
                                          0.1),
                                      borderRadius:
                                      BorderRadius.circular(
                                          8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isUp
                                              ? Icons.arrow_drop_up
                                              : Icons.arrow_drop_down,
                                          color: isUp
                                              ? Colors.green
                                              : Colors.red,
                                          size:
                                          20,
                                        ),
                                        Text(
                                          "${changePercent.abs().toStringAsFixed(2)}%",
                                          style:
                                          TextStyle(
                                            color: isUp
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
