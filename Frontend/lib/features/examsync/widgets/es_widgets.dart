import 'package:flutter/material.dart';
import 'package:neopop/neopop.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';

const double kPlunkDepth = 3;

/// Static NeoPOP block: a flat face with 3px skewed edges on the right and
/// bottom. Interactive blocks use [NeoPopButton] instead.
class PlunkBox extends StatelessWidget {
  const PlunkBox({
    super.key,
    required this.child,
    this.color = EsColors.surface,
    this.rightColor = EsColors.border,
    this.bottomColor = EsColors.border,
    this.border,
    this.depth = kPlunkDepth,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final Color rightColor;
  final Color bottomColor;
  final Color? border;
  final double depth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlunkEdgePainter(depth, rightColor, bottomColor),
      child: Padding(
        padding: EdgeInsets.only(right: depth, bottom: depth),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            border: border == null ? null : Border.all(color: border!),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlunkEdgePainter extends CustomPainter {
  _PlunkEdgePainter(this.depth, this.right, this.bottom);

  final double depth;
  final Color right;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final d = depth;
    canvas.drawPath(
      Path()
        ..moveTo(w - d, 0)
        ..lineTo(w, d)
        ..lineTo(w, h)
        ..lineTo(w - d, h - d)
        ..close(),
      Paint()..color = right,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h - d)
        ..lineTo(w - d, h - d)
        ..lineTo(w, h)
        ..lineTo(d, h)
        ..close(),
      Paint()..color = bottom,
    );
  }

  @override
  bool shouldRepaint(_PlunkEdgePainter old) =>
      old.depth != depth || old.right != right || old.bottom != bottom;
}

/// Tappable NeoPOP block whose face sinks into its edges when pressed.
class PlunkTap extends StatelessWidget {
  const PlunkTap({
    super.key,
    required this.child,
    required this.onTap,
    this.color = EsColors.surface,
    this.rightColor = EsColors.border,
    this.bottomColor = EsColors.border,
    this.border,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color rightColor;
  final Color bottomColor;
  final Color? border;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: NeoPopButton(
        color: color,
        disabledColor: color,
        rightShadowColor: rightColor,
        bottomShadowColor: bottomColor,
        depth: kPlunkDepth,
        animationDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 50),
        border: border == null ? null : Border.all(color: border!),
        onTapDown: () {},
        onTapUp: onTap,
        child: child,
      ),
    );
  }
}

enum EsButtonVariant { primary, premium, success, secondary }

enum EsButtonSize {
  sm(34, 12.5),
  md(42, 13.5),
  lg(52, 15);

  const EsButtonSize(this.height, this.fontSize);
  final double height;
  final double fontSize;
}

class EsButton extends StatelessWidget {
  const EsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EsButtonVariant.primary,
    this.size = EsButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final EsButtonVariant variant;
  final EsButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (face, right, bottom, ink) = switch (variant) {
      EsButtonVariant.primary => (
          EsColors.accent,
          EsColors.accentRight,
          EsColors.accentBottom,
          Colors.black
        ),
      EsButtonVariant.premium => (
          EsColors.premium,
          EsColors.premiumRight,
          EsColors.premiumBottom,
          Colors.white
        ),
      EsButtonVariant.success => (
          EsColors.success,
          EsColors.successRight,
          EsColors.successBottom,
          Colors.black
        ),
      EsButtonVariant.secondary => (
          EsColors.surfaceElevated,
          EsColors.borderLight,
          EsColors.border,
          EsColors.text
        ),
    };
    final textColor = enabled || loading ? ink : EsColors.textDisabled;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final content = SizedBox(
      height: size.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: ink),
              )
            else if (icon != null)
              Icon(icon, size: size.fontSize + 3, color: textColor),
            if (loading || icon != null) const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EsText.body(
                  size: size.fontSize,
                  weight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: NeoPopButton(
        color: face,
        // While loading keep the face colour so the spinner reads as
        // progress, not as a disabled button.
        disabledColor: loading ? face : const Color(0xFF2A2A2A),
        rightShadowColor: enabled || loading ? right : const Color(0xFF222222),
        bottomShadowColor:
            enabled || loading ? bottom : const Color(0xFF1A1A1A),
        border: variant == EsButtonVariant.secondary && enabled
            ? Border.all(color: EsColors.borderLight)
            : null,
        depth: kPlunkDepth,
        animationDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 50),
        onTapDown: () {},
        onTapUp: enabled ? onPressed : null,
        child: content,
      ),
    );
  }
}

/// Square icon button used in top bars (back, close). 44px target.
class EsIconButton extends StatelessWidget {
  const EsIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color = EsColors.surfaceElevated,
    this.iconColor = EsColors.text,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return PlunkTap(
      color: color,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      semanticLabel: semanticLabel,
      onTap: onPressed,
      child: SizedBox(
        width: 41,
        height: 41,
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

enum EsChipVariant { accent, premium, success, ghost, ink }

class EsChip extends StatelessWidget {
  const EsChip(
    this.label, {
    super.key,
    this.variant = EsChipVariant.ghost,
    this.icon,
    this.mono = false,
  });

  final String label;
  final EsChipVariant variant;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      EsChipVariant.accent => (EsColors.accent, Colors.black, null),
      EsChipVariant.premium => (EsColors.premium, Colors.white, null),
      EsChipVariant.success => (EsColors.success, Colors.black, null),
      EsChipVariant.ink => (Colors.black, Colors.white, null),
      EsChipVariant.ghost => (
          EsColors.surfaceElevated,
          EsColors.textSecondary,
          EsColors.borderLight
        ),
    };
    final text = mono ? label : label.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: mono
                ? EsText.mono(size: 11, color: fg)
                : EsText.body(size: 11, weight: FontWeight.w800, color: fg)
                    .copyWith(letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class EsSegment<T> {
  const EsSegment({
    required this.value,
    required this.label,
    this.count,
    this.enabled = true,
  });

  final T value;
  final String label;
  final int? count;
  final bool enabled;
}

/// One-tap segmented control. The active item fills [activeColor] and sits
/// on a 3px plunk.
class EsSegmented<T> extends StatelessWidget {
  const EsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.activeColor = EsColors.accent,
    this.activeInk = Colors.black,
    this.activeRight = EsColors.accentRight,
    this.activeBottom = EsColors.accentBottom,
  });

  final List<EsSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final Color activeColor;
  final Color activeInk;
  final Color activeRight;
  final Color activeBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EsColors.bgSecondary,
        border: Border.all(color: EsColors.border),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(child: _segment(s, s.value == value)),
        ],
      ),
    );
  }

  Widget _segment(EsSegment<T> s, bool active) {
    final fg = !s.enabled
        ? EsColors.textDisabled
        : active
            ? activeInk
            : EsColors.textSecondary;
    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            s.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EsText.body(size: 13, weight: FontWeight.w800, color: fg),
          ),
        ),
        if (s.count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            color: active ? Colors.black : EsColors.surfaceElevated,
            child: Text(
              '${s.count}',
              style: EsText.mono(
                size: 10.5,
                color: active ? activeColor : EsColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );

    final body = SizedBox(height: 40, child: Center(child: label));
    return Semantics(
      button: true,
      selected: active,
      enabled: s.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: s.enabled && !active ? () => onChanged(s.value) : null,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: active
              ? PlunkBox(
                  color: activeColor,
                  rightColor: activeRight,
                  bottomColor: activeBottom,
                  child: SizedBox(height: 37, child: Center(child: label)),
                )
              : body,
        ),
      ),
    );
  }
}

/// Uppercase label above a section.
class EsEyebrow extends StatelessWidget {
  const EsEyebrow(this.text, {super.key, this.color = EsColors.textMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: EsText.eyebrow(color: color));
}

class EsAlertBanner extends StatelessWidget {
  const EsAlertBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EsColors.surface,
        border: Border(left: BorderSide(color: EsColors.accent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: EsColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: EsText.body(
                size: 12.5,
                color: EsColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey placeholder block for skeleton loading states.
class EsSkeleton extends StatefulWidget {
  const EsSkeleton({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  State<EsSkeleton> createState() => _EsSkeletonState();
}

class _EsSkeletonState extends State<EsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        color: Color.lerp(EsColors.surface, EsColors.surfaceElevated, _c.value),
      ),
    );
  }
}

/// Error state with a retry action. Never shows the raw exception.
class EsErrorState extends StatelessWidget {
  const EsErrorState({
    super.key,
    required this.onRetry,
    this.title = 'Couldn’t load this',
    this.message = 'Check your connection and try again.',
  });

  final VoidCallback onRetry;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: EsColors.error),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: EsText.body(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: EsText.body(size: 13, color: EsColors.textMuted),
          ),
          const SizedBox(height: 16),
          EsButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            variant: EsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
