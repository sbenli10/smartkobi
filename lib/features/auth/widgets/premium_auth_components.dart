import 'package:flutter/material.dart';

class PremiumAuthBackground extends StatelessWidget {
  const PremiumAuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff6456D6),
            Color(0xff4B4AC8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -110,
            bottom: -150,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumAuthScaffold extends StatelessWidget {
  const PremiumAuthScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PremiumAuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumAuthCard extends StatelessWidget {
  const PremiumAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(32, 28, 32, 28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff5A54D6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff5A54D6),
            side: const BorderSide(color: Color(0xff5A54D6), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          );

    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          );

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: filled
          ? ElevatedButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xff7A7A8C),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class AuthLineField extends StatelessWidget {
  const AuthLineField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.onSuffixTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onFieldSubmitted;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: Color(0xff323240),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xffB1B1BF),
          fontSize: 14,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: enabled ? onSuffixTap : null,
                icon: Icon(suffixIcon, size: 20, color: const Color(0xff8C8C99)),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffCFCFDC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff5A54D6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffEF4444), width: 1.4),
        ),
      ),
    );
  }
}

class SocialDot extends StatelessWidget {
  const SocialDot({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class PhoneIllustration extends StatelessWidget {
  const PhoneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(left: 12, top: 18, child: MiniStar()),
          const Positioned(right: 18, top: 12, child: OutlineDot()),
          const Positioned(left: 24, child: OutlineDot()),
          const Positioned(right: 42, top: 72, child: PlusStar()),
          Container(
            width: 92,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xff2F3153), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2F3153).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xff2F3153),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF6F7FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xffD8D8E8)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: index == 1 ? 14 : 18,
                                  height: 2.3,
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  color: const Color(0xff5357C8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xff5357C8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 92,
            bottom: 8,
            child: WalkingFigure(),
          ),
        ],
      ),
    );
  }
}

class DoorIllustration extends StatelessWidget {
  const DoorIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(left: 6, top: 76, child: OutlineDot()),
          const Positioned(right: 26, top: 24, child: MiniStar()),
          const Positioned(right: 6, top: 68, child: OutlineDot(fill: true)),
          Container(
            width: 122,
            height: 156,
            decoration: BoxDecoration(
              color: const Color(0xffE8E8ED),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 54,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xffE0E0E7)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Container(decoration: _gridBorder())),
                          Expanded(child: Container(decoration: _gridBorder())),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Container(decoration: _gridBorder())),
                          Expanded(child: Container(decoration: _gridBorder())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 56,
            bottom: 24,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xffEFEFF5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 54,
            bottom: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xffEFEFF5),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          const Positioned(
            right: 76,
            bottom: 22,
            child: WalkingFigure(compact: true),
          ),
        ],
      ),
    );
  }

  BoxDecoration _gridBorder() {
    return BoxDecoration(
      border: Border.all(color: const Color(0xffECECF2)),
    );
  }
}

class MiniStar extends StatelessWidget {
  const MiniStar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.auto_awesome,
      size: 13,
      color: Color(0xffCCCCD7),
    );
  }
}

class PlusStar extends StatelessWidget {
  const PlusStar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.add,
      size: 22,
      color: Color(0xff5357C8),
    );
  }
}

class OutlineDot extends StatelessWidget {
  const OutlineDot({super.key, this.fill = false});

  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill ? const Color(0xff5357C8) : Colors.transparent,
        border: Border.all(
          color: const Color(0xff5357C8),
          width: 1.5,
        ),
      ),
    );
  }
}

class WalkingFigure extends StatelessWidget {
  const WalkingFigure({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.78 : 1.0;
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 62,
        height: 108,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 22,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xffFFD8C2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                width: 34,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xff5A54D6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(6),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 42,
              left: 21,
              child: Transform.rotate(
                angle: 0.32,
                child: Container(
                  width: 8,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xff353547),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 44,
              left: 33,
              child: Transform.rotate(
                angle: -0.16,
                child: Container(
                  width: 8,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xff353547),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 26,
              left: 4,
              child: Transform.rotate(
                angle: 0.68,
                child: Container(
                  width: 8,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xffFFD8C2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 2,
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: 8,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xffFFD8C2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
