import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
      ),
      body: Stack(
        children: [
          // 🌿 Watermark Logo
          Center(
            child: Opacity(
              opacity: 0.38, // adjust: 0.04 – 0.08
              child: Image.asset(
                "assets/logo.png",
                width: 360,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "धन Mitra",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your companion for financial literacy and smart decision-making.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _Section(
                  title: "🎯 About धन Mitra",
                  content:
                  """We are a group of passionate engineering students from MIT Manipal who came together with a simple observation — millions of people in Tier-2 and Tier-3 cities lack access to clear, practical financial education. Many struggle with basic money concepts, while others hesitate to start investing because most platforms require large amounts or feel too complex.
DhanMitra was built to change that. We wanted to create a friendly, accessible financial companion that helps people learn, practice, and grow their money skills without fear or confusion.
                  """),

                _Section(
                  title: "🎯 Our Mission",
                  content:
                  """DhanMitra aims to empower individuals from Tier-2 and Tier-3 cities — and anyone eager to understand personal finance — with practical, real-world financial knowledge. Through micro-lessons, decision-based simulations, and virtual trading experiences, we make learning about money interactive, relevant, and easy to apply in everyday life.
Our goal is not just to teach finance, but to build confidence in financial decision-making.
                  """,
                ),

                _Section(
                  title: "📚 What We Offer",
                  isList: true,
                  content:
                  "Bite-sized finance lessons that simplify complex money concepts into easy, actionable insights\n"
                      "Multilingual learning support to make financial education accessible beyond language barriers\n"
                      "Decision-based practice scenarios that simulate real-life financial choices and consequences\n"
                      "Virtual stock trading to help users learn investing without risking real money",
                ),

                _Section(
                  title: "🚀 Our vision",
                  content:
                  """DhanMitra bridges the gap between financial theory and real-world decision-making. We believe financial literacy should be practical, inclusive, and accessible to everyone — regardless of background, language, or income level. By combining education with hands-on practice, we aim to create a generation that makes smarter, more confident financial choices.
                  """,
                ),

                const SizedBox(height: 12),

                Center(
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        "Learn smart. Decide better. Grow financially.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final bool isList;

  const _Section({
    required this.title,
    required this.content,
    this.isList = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          if (isList)
            ...content.split('\n').map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
        ],
      ),
    );
  }
}
