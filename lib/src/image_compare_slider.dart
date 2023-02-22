import 'package:flutter/material.dart';

part 'slider_clipper.dart';
part 'handle_painter.dart';

/// Slider direction.
enum SliderDirection {
  /// Slider direction from left to right.
  leftToRight,

  /// Slider direction from right to left.
  rightToLeft,

  /// Slider direction from top to bottom.
  topToBottom,

  /// Slider direction from bottom to top.
  bottomToTop,
}

/// {@template flutter_compare_slider}
///  A Flutter widget that allows you to compare two images.
///
/// Usage:
/// ```dart
///  ImageCompareSlider(
///    itemOne: const Image.asset('...'),
///    itemTwo: const Image.asset('...'),
///  )
/// ```
/// See also:
/// * [SliderDirection] for the direction of the slider.
/// {@endtemplate}
class ImageCompareSlider extends StatefulWidget {
  /// Creates a [ImageCompareSlider].
  ///
  /// {@macro flutter_compare_slider}
  const ImageCompareSlider({
    required this.itemOne,
    required this.itemTwo,
    super.key,
    this.itemOneBuilder,
    this.itemTwoBuilder,
    this.changePositionOnHover = false,
    this.onPositionChange,
    this.position = 0.5,
    this.dividerColor = Colors.white,
    this.dividerWidth = 2.5,
    this.handleSize = 20,
    this.handleRadius = const BorderRadius.all(Radius.circular(10)),
    this.fillHandle = false,
    this.hideHandle = false,
    this.handlePosition = 0.5,
    this.direction = SliderDirection.leftToRight,
  })  : portrait = direction == SliderDirection.topToBottom ||
            direction == SliderDirection.bottomToTop,
        assert(
          position >= 0 && position <= 1,
          'initialPosition must be between 0 and 1',
        ),
        assert(
          handlePosition >= 0 && handlePosition <= 1,
          'handlePosition must be between 0 and 1',
        ),
        assert(
          handleSize >= 0,
          'handleSize must be greater or equal to 0',
        );

  /// First component to show in slider.
  final Image itemOne;

  /// Second component to show in slider.
  final Image itemTwo;

  /// Wrapper for the first component.
  final Widget Function(Widget child)? itemOneBuilder;

  /// Wrapper for the second component.
  final Widget Function(Widget child)? itemTwoBuilder;

  /// Whether the slider should follow the pointer on hover.
  final bool changePositionOnHover;

  /// Callback on position change, returns current position.
  final void Function(double position)? onPositionChange;

  /// Initial percentage position of divide (0-1).
  final double position;

  /// Color of the divider
  final Color dividerColor;

  /// Width of the divider
  final double dividerWidth;

  /// Handle size.
  final double handleSize;

  /// Handle radius.
  final BorderRadius handleRadius;

  /// Wether to fill the handle.
  final bool fillHandle;

  /// Whether to hide the handle.
  final bool hideHandle;

  /// Where to place the handle.
  final double handlePosition;

  /// Direction of the slider.
  final SliderDirection direction;

  /// Whether to use portrait orientation.
  final bool portrait;

  @override
  State<ImageCompareSlider> createState() => _ImageCompareSliderState();
}

class _ImageCompareSliderState extends State<ImageCompareSlider> {
  late double position;
  void initPosition() => position = widget.position;

  @override
  void didUpdateWidget(ImageCompareSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position != oldWidget.position) initPosition();
  }

  @override
  void initState() {
    super.initState();
    initPosition();
  }

  void updatePosition(double newPosition) {
    setState(() => position = newPosition);
    widget.onPositionChange?.call(position);
  }

  void onDetection(Offset globalPosition) {
    // ignore: cast_nullable_to_non_nullable
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    var newPosition = widget.portrait
        ? localPosition.dy / box.size.height
        : localPosition.dx / box.size.width;
    newPosition = newPosition.clamp(0.0, 1.0);
    updatePosition(newPosition);
  }

  Image generateImage(Image image1) => Image(
        image: image1.image,
        fit: BoxFit.cover,
        /* Gathered properties */
        color: image1.color,
        colorBlendMode: image1.colorBlendMode,
        alignment: image1.alignment,
        loadingBuilder: image1.loadingBuilder,
        frameBuilder: image1.frameBuilder,
        errorBuilder: image1.errorBuilder,
        excludeFromSemantics: image1.excludeFromSemantics,
        filterQuality: image1.filterQuality,
        gaplessPlayback: image1.gaplessPlayback,
        isAntiAlias: image1.isAntiAlias,
        matchTextDirection: image1.matchTextDirection,
        opacity: image1.opacity,
        repeat: image1.repeat,
        semanticLabel: image1.semanticLabel,
        /* Not used properties */
        // width: image1.width,
        // height: image1.height,
        // centerSlice: image1.centerSlice,
      );

  @override
  Widget build(BuildContext context) {
    final firstImage = generateImage(widget.itemOne);
    final secondImage = generateImage(widget.itemTwo);

    final child = Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRect(
          clipper: _SliderClipper.invert(
            position: position,
            direction: widget.direction,
          ),
          child: widget.itemOneBuilder?.call(firstImage) ?? firstImage,
        ),
        ClipRect(
          clipper: _SliderClipper(
            position: position,
            direction: widget.direction,
          ),
          child: widget.itemTwoBuilder?.call(secondImage) ?? secondImage,
        ),
        GestureDetector(
          onTapDown: (details) => onDetection(details.globalPosition),
          onPanUpdate: (details) => onDetection(details.globalPosition),
          onPanEnd: (_) => updatePosition(position),
          child: CustomPaint(
            painter: _HandlePainter(
              position: position,
              color: widget.dividerColor,
              strokeWidth: widget.dividerWidth,
              portrait: widget.portrait,
              fillHandle: widget.fillHandle,
              handleSize: widget.handleSize,
              hideHandle: widget.hideHandle,
              handlePosition: widget.handlePosition,
              handleRadius: widget.handleRadius,
            ),
            child: Opacity(opacity: 0, child: firstImage),
          ),
        ),
      ],
    );

    return widget.changePositionOnHover
        ? MouseRegion(
            onHover: (event) => onDetection(event.position),
            child: child,
          )
        : child;
  }
}
