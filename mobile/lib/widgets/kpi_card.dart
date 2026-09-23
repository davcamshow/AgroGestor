import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final LinearGradient? gradient;

  /// Modo compacto: menos padding, tipografía e iconos más pequeños.
  final bool compact;

  const KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.gradient,
    this.compact = false,
    super.key,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppTheme.primaryGradient;
    final color = widget.color ?? AppTheme.primary;
    final compact = widget.compact;

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut)),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            boxShadow: [AppTheme.softShadow],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontSize: compact ? 11 : 13,
                            ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(compact ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: compact ? 16 : 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 16),
                Text(
                  widget.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 22 : 28,
                      ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: compact ? 4 : 8),
                  Text(
                    widget.subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
