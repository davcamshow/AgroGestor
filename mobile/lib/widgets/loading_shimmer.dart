import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const LoadingShimmer({
    this.height = 16,
    this.width = double.infinity,
    this.padding = const EdgeInsets.all(0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class LoadingShimmerListItem extends StatelessWidget {
  final int lines;
  final EdgeInsets padding;

  const LoadingShimmerListItem({
    this.lines = 3,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer(height: 18, width: double.infinity),
          const SizedBox(height: 12),
          for (int i = 0; i < lines - 1; i++) ...[
            LoadingShimmer(
              height: 14,
              width: i == lines - 2 ? 200 : double.infinity,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
