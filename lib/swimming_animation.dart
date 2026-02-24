import 'package:flutter/material.dart';
import 'dart:math';

class SwimmingAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SwimmingAnimation({Key? key, required this.onAnimationComplete})
      : super(key: key);

  @override
  _SwimmingAnimationState createState() => _SwimmingAnimationState();
}

class _SwimmingAnimationState extends State<SwimmingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swimmerPositionAnimation;
  late Animation<double> _armStrokeAnimation;
  late Animation<double> _legKickAnimation;
  late Animation<double> _bodyRotationAnimation;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 4), vsync: this)
          ..addListener(() {
            setState(() {});
          });

    _swimmerPositionAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _armStrokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _legKickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _bodyRotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward().whenComplete(() {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SwimmerPainter(
        swimmerPosition: _swimmerPositionAnimation.value,
        armStrokeProgress: _armStrokeAnimation.value,
        legKickProgress: _legKickAnimation.value,
        bodyRotation: _bodyRotationAnimation.value,
        bubbleProgress: _bubbleAnimation.value,
      ),
      child: Container(),
    );
  }
}

class _SwimmerPainter extends CustomPainter {
  final double swimmerPosition;
  final double armStrokeProgress;
  final double legKickProgress;
  final double bodyRotation;
  final double bubbleProgress;

  _SwimmerPainter({
    required this.swimmerPosition,
    required this.armStrokeProgress,
    required this.legKickProgress,
    required this.bodyRotation,
    required this.bubbleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final swimmerColor = Colors.blue.shade800;
    final skinColor = Colors.orange.shade200;
    final capColor = Colors.red.shade600;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black.withOpacity(0.5);

    // Water background gradient (shallow to deep)
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue.shade200, Colors.blue.shade800],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = waterGradient,
    );

    // Calculate swimmer's X position
    final swimmerX = size.width * swimmerPosition;
    final centerY = size.height / 2;

    canvas.save();
    canvas.translate(swimmerX, centerY);
    canvas.rotate(bodyRotation * pi / 4); // Subtle body rotation

    // Body
    final bodyWidth = size.width * 0.07;
    final bodyHeight = size.height * 0.03;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, 0),
        width: bodyWidth,
        height: bodyHeight,
      ),
      const Radius.circular(5),
    );
    paint.color = swimmerColor;
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, strokePaint);

    // Head
    final headRadius = size.width * 0.018;
    final headCenter = Offset(
      bodyWidth / 2 - headRadius / 2,
      -bodyHeight / 2 - headRadius,
    );
    paint.color = skinColor;
    canvas.drawCircle(headCenter, headRadius, paint);
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Swim Cap
    paint.color = capColor;
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius),
      pi, // Start angle (180 degrees)
      pi, // Sweep angle (180 degrees)
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius),
      pi, // Start angle (180 degrees)
      pi, // Sweep angle (180 degrees)
      false,
      strokePaint,
    );

    // Arms
    final armLength = size.width * 0.04;
    final armOffset = bodyWidth * 0.3;
    final armYOffset = bodyHeight * 0.2;

    // Right Arm (front stroke)
    final rightArmStart = Offset(-armOffset, -armYOffset);
    final rightArmEnd = Offset(
      rightArmStart.dx -
          armLength * sin(armStrokeProgress * pi * 2), // Circular motion
      rightArmStart.dy + armLength * cos(armStrokeProgress * pi * 2),
    );
    strokePaint.strokeWidth = 3.0;
    canvas.drawLine(rightArmStart, rightArmEnd, strokePaint);

    // Left Arm (back stroke)
    final leftArmStart = Offset(-armOffset, armYOffset);
    final leftArmEnd = Offset(
      leftArmStart.dx -
          armLength * sin((armStrokeProgress + 0.5) * pi * 2), // Opposite phase
      leftArmStart.dy + armLength * cos((armStrokeProgress + 0.5) * pi * 2),
    );
    canvas.drawLine(leftArmStart, leftArmEnd, strokePaint);

    // Legs
    final legLength = size.width * 0.03;
    final legOffset = bodyWidth * 0.4;
    final legYOffset = bodyHeight * 0.3;

    // Right Leg
    final rightLegStart = Offset(legOffset, -legYOffset);
    final rightLegEnd = Offset(
      rightLegStart.dx +
          legLength * cos(legKickProgress * pi * 2), // Kick up and down
      rightLegStart.dy + legLength * sin(legKickProgress * pi * 2),
    );
    canvas.drawLine(rightLegStart, rightLegEnd, strokePaint);

    // Left Leg
    final leftLegStart = Offset(legOffset, legYOffset);
    final leftLegEnd = Offset(
      leftLegStart.dx +
          legLength * cos((legKickProgress + 0.5) * pi * 2), // Opposite kick
      leftLegStart.dy + legLength * sin((legKickProgress + 0.5) * pi * 2),
    );
    canvas.drawLine(leftLegStart, leftLegEnd, strokePaint);

    canvas.restore();

    // Water ripples (more dynamic)
    final ripplePaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final rippleRadius =
          (size.width * 0.05) * (armStrokeProgress + i * 0.2) % 1.0;
      final rippleOpacity = (1.0 - rippleRadius / (size.width * 0.05)).clamp(
        0.0,
        1.0,
      );
      ripplePaint.color = Colors.lightBlue.withOpacity(rippleOpacity * 0.6);
      canvas.drawCircle(
        Offset(swimmerX - bodyWidth / 2, centerY + bodyHeight / 2 + 10),
        rippleRadius * 50,
        ripplePaint,
      );
    }

    // Bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final bubbleX =
          swimmerX + (sin(bubbleProgress * pi * 2 + i) * 20) + (i * 5);
      final bubbleY = centerY + (bubbleProgress * size.height * 0.5) - (i * 10);
      final bubbleRadius = 2.0 + (sin(bubbleProgress * pi * 2 + i) * 1);
      if (bubbleY > 0 && bubbleY < size.height) {
        canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, bubblePaint);
      }
    }

    // Splashes (simple expanding circles around arms/legs)
    final splashPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Splash for right arm
    if (armStrokeProgress > 0.7 && armStrokeProgress < 0.9) {
      final splashRadius = (armStrokeProgress - 0.7) * 50;
      splashPaint.color = Colors.white.withOpacity(
        1.0 - (armStrokeProgress - 0.7) * 5,
      );
      canvas.drawCircle(
        Offset(swimmerX - bodyWidth / 2 - 20, centerY - 10),
        splashRadius,
        splashPaint,
      );
    }

    // Splash for left arm
    if (armStrokeProgress > 0.2 && armStrokeProgress < 0.4) {
      final splashRadius = (armStrokeProgress - 0.2) * 50;
      splashPaint.color = Colors.white.withOpacity(
        1.0 - (armStrokeProgress - 0.2) * 5,
      );
      canvas.drawCircle(
        Offset(swimmerX - bodyWidth / 2 - 20, centerY + 10),
        splashRadius,
        splashPaint,
      );
    }

    // App Title
    final textPainter = TextPainter(
      text: TextSpan(
        text: "Swim Across",
        style: TextStyle(
          color: Colors.white.withOpacity(
            max(0, 1 - (swimmerPosition - 0.5).abs() * 2),
          ), // Fade in/out with swimmer
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height * 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    _SwimmerPainter oldPainter = oldDelegate as _SwimmerPainter;
    return oldPainter.swimmerPosition != swimmerPosition ||
        oldPainter.armStrokeProgress != armStrokeProgress ||
        oldPainter.legKickProgress != legKickProgress ||
        oldPainter.bodyRotation != bodyRotation ||
        oldPainter.bubbleProgress != bubbleProgress;
  }
}
