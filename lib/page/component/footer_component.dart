import 'package:flutter/material.dart';

class FooterComponent extends StatelessWidget {
  final double contentWidth;

  const FooterComponent({super.key, required this.contentWidth});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Findexpert",
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 12,
                children: [
                  _footerColumn("Über uns", ["Karriere", "Presse"]),
                  _footerColumn("Kontakt", ["Adresse", "Email", "Service"]),
                  _footerColumn(
                      "Rechtliches", ["AGB", "Datenschutz", "Impressum"]),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  "© 2025 FindExpert. All rights reserved.",
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }
}
