import 'package:flutter/material.dart';

class FooterComponent extends StatelessWidget {
  final double contentWidth;
  final double height;

  const FooterComponent({
    super.key,
    required this.contentWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const legalEntries = [
      "Impressum",
      "Datenschutzerklärung",
      "AGB",
      "Cookie-Richtlinie",
      "Widerrufsbelehrung",
    ];

    return SizedBox(
      height: height,
      child: Container(
        width: double.infinity,
        color: colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      for (final entry in legalEntries)
                        _legalLinkPlaceholder(context, entry),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, thickness: 0.5, height: 1),
                const SizedBox(height: 16),
                const Spacer(),
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

  Widget _legalLinkPlaceholder(BuildContext context, String label) {
    final linkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
          decoration: TextDecoration.underline,
        );

    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: linkStyle),
    );
  }
}
