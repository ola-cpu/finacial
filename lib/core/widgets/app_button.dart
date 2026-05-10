import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.primary;
        borderSide = BorderSide(color: theme.colorScheme.primary, width: 1.5);
        break;
      case AppButtonVariant.danger:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        break;
    }

    if (!isEnabled) {
      if (widget.variant != AppButtonVariant.outline) {
        backgroundColor = backgroundColor.withAlpha((0.3 * 255).round());
      }
      textColor = textColor.withAlpha((0.5 * 255).round());
      if (widget.variant == AppButtonVariant.outline) {
        borderSide = BorderSide(color: theme.colorScheme.primary.withAlpha((0.3 * 255).round()), width: 1.5);
      }
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
            boxShadow: isEnabled && widget.variant != AppButtonVariant.outline
                ? [
                    BoxShadow(
                      color: backgroundColor.withAlpha((0.3 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
