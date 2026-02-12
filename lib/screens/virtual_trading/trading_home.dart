import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../components/models/trading/market_price_updater.dart';
import '../../components/models/user_database.dart';
import '../Learning/finance_sections_page.dart';
import '../Profile.dart';
import '../dashboard.dart';
import 'mandatory_status_check.dart';
import 'buy_sell_page.dart';
import 'portfolio_page.dart';

class TradingHomePage extends StatefulWidget {
  const TradingHomePage({super.key});

  @override
  State<TradingHomePage> createState() => _TradingHomePageState();
}

class _TradingHomePageState extends State<TradingHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';

  late final MarketPriceUpdater _marketUpdater;
  Timer? _marketTimer;

  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _marketUpdater = MarketPriceUpdater();
    _userFuture = UserService().userStream().first;

    _searchController.addListener(() {
      final newQuery = _searchController.text;
      if (newQuery != query) {
        setState(() {
          query = newQuery;
        });
      }
    });
  }

  @override
  void dispose() {
    _marketTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startMarketUpdatesOnce() {
    if (_marketTimer != null) return;

    _marketUpdater.maybeUpdateMarket();

    _marketTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _marketUpdater.maybeUpdateMarket(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final UserService userService = UserService();

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
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

        if (!tradingUnlocked) {
          return const MandatoryStatusPage();
        }

        _startMarketUpdatesOnce();

        return Scaffold(
          resizeToAvoidBottomInset: false,
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
            title: const Text('Virtual Market'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: "Portfolio",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PortfolioPage()),
                  );
                },
              ),
            ],
          ),

          body: Column(
            children: [

              // Wallet Balance Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: StreamBuilder<double>(
                  stream: userService.walletBalanceStream(),
                  builder: (context, snapshot) {
                    final balance = snapshot.data ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Available Balance",
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/gold_coin.svg',
                                      height: 22,
                                      width: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      balance.toStringAsFixed(0),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
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

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stocks...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor:
                    colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('market_prices')
                      .orderBy('symbol')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final search = query.trim().toUpperCase();

                    final docs =
                    snapshot.data!.docs.where((doc) {
                      if (search.isEmpty) return true;

                      final symbol =
                      (doc['symbol'] as String).toUpperCase();

                      return symbol.contains(search);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text("No stocks found"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                        docs[index].data() as Map<String, dynamic>;

                        final symbol = data['symbol'];
                        final price =
                        (data['price'] as num).toDouble();
                        final changePercent =
                        (data['changePercent'] as num)
                            .toDouble();

                        final isUp = changePercent >= 0;
                        final trendColor =
                        isUp ? Colors.green : Colors.red;

                        return Card(
                          elevation: 0,
                          margin:
                          const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color:
                                colorScheme.outlineVariant),
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(
                              symbol,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                  fontWeight:
                                  FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/gold_coin.svg',
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  price.toStringAsFixed(0),
                                  style:
                                  theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color: trendColor
                                    .withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(
                                    8),
                              ),
                              child: Text(
                                '${isUp ? "+" : ""}${changePercent.toStringAsFixed(2)}%',
                                style: theme
                                    .textTheme.labelLarge
                                    ?.copyWith(
                                  color: trendColor,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape:
                                const RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.vertical(
                                      top: Radius
                                          .circular(
                                          20)),
                                ),
                                builder: (_) =>
                                    BuySellSheet(
                                      symbol: symbol,
                                      price:price,
                                    ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

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
                  icon: Icon(Icons.trending_up),
                  label: "Trading"),
              NavigationDestination(
                  icon: Icon(Icons.person),
                  label: "Profile"),
            ],
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const FinanceSectionsPage(),
                  ),
                );
              } else if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const DashboardPage(),
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
      },
    );
  }
}
