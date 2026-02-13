import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_database.dart';
import 'package:dhan_mitra/screens/mutual_funds/mf_transaction_history.dart';
import 'package:dhan_mitra/screens/mutual_funds/sell_fund_sheet.dart';
import 'package:dhan_mitra/screens/mutual_funds/my_sip_page.dart';
import 'package:dhan_mitra/screens/mutual_funds/my_swp_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MutualFundPortfolioPage extends StatelessWidget {
  const MutualFundPortfolioPage({super.key});

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  @override
  Widget build(BuildContext context) {
    final MutualFundService mfService = MutualFundService();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("My Portfolio", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MFTransactionHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: mfService.portfolioStream(),
        builder: (context, portfolioSnap) {
          if (!portfolioSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final portfolio = portfolioSnap.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('mf_nav').snapshots(),
            builder: (context, navSnap) {
              if (!navSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final navMap = {for (var doc in navSnap.data!.docs) doc.id: doc};

              double totalInvested = 0;
              double totalCurrentValue = 0;

              List<Widget> fundTiles = [];

              for (var entry in portfolio.entries) {
                final fundId = entry.key;
                final data = entry.value as Map<String, dynamic>;

                final units = (data['units'] as num).toDouble();
                final invested = (data['investedAmount'] as num).toDouble();

                final navDoc = navMap[fundId];
                if (navDoc == null) continue;

                final nav = (navDoc['nav'] as num).toDouble();
                final currentValue = units * nav;
                final gain = currentValue - invested;
                final gainPercent = invested == 0 ? 0 : (gain / invested) * 100;

                totalInvested += invested;
                totalCurrentValue += currentValue;

                fundTiles.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => SellFundSheet(
                            fundId: fundId,
                            units: units,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fundId, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Units: ${units.toStringAsFixed(3)} • NAV: ${nav.toStringAsFixed(2)}",
                                    style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currentValue.toStringAsFixed(0),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                Text(
                                  "${gain >= 0 ? "+" : ""}${gainPercent.toStringAsFixed(2)}%",
                                  style: TextStyle(
                                    color: gain >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final totalGain = totalCurrentValue - totalInvested;
              final totalGainPercent = totalInvested == 0 ? 0 : (totalGain / totalInvested) * 100;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 MODERN TOTAL PORTFOLIO CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text("Total Portfolio Value", style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              coin(24),
                              const SizedBox(width: 8),
                              Text(
                                totalCurrentValue.toStringAsFixed(0),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${totalGain >= 0 ? "Profit" : "Loss"}: ${totalGain.toStringAsFixed(0)} (${totalGainPercent.toStringAsFixed(2)}%)",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔥 QUICK ACTIONS (FLASHCARDS)
                    Row(
                      children: [
                        Expanded(
                          child: _flashCard(
                            context,
                            title: "My SIPs",
                            icon: Icons.sync_rounded,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MySIPPage()));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _flashCard(
                            context,
                            title: "My SWPs",
                            icon: Icons.south_west_rounded,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MySWPPage()));
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Text("Your Holdings", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...fundTiles,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _flashCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
            color: color.withOpacity(0.05),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}