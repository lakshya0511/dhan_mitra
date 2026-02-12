import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Profile.dart';
import '../dashboard.dart';
import '../virtual_trading/trading_home.dart';
import 'lessons_list_page.dart';

class FinanceSectionsPage extends StatelessWidget {
  const FinanceSectionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        title: const Text("Learning Sections"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sections')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    "No sections available yet",
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final sections = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final data = sections[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  // Added a leading index indicator to show curriculum progress
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Untitled Section',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.outline,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonsListPage(
                          sectionId: sections[index].id,
                          sectionTitle: data['title'] ?? 'Lessons',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
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
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
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