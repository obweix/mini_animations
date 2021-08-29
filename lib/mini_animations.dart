
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';



class OpenContainer extends StatefulWidget {
  const OpenContainer({
    Key? key,
    required this.closedBuilder,
    required this.openBuilder,
    required this.onClosed,
    required this.tappable,
    required this.useRootNavigator
  }) : super(key: key);

  final Widget Function(BuildContext context, VoidCallback action) closedBuilder;
  final Widget Function(BuildContext context, VoidCallback action) openBuilder;
  final void Function() onClosed;
  final bool useRootNavigator;

  /// Whether the entire closed container can be tapped to open it.
  ///
  /// Defaults to true.
  ///
  /// When this is set to false the container can only be opened by calling the
  /// `action` callback that is provided to the [closedBuilder].
  final bool tappable;

  @override
  _OpenContainerState createState() => _OpenContainerState();
}

class _OpenContainerState extends State<OpenContainer> {
  final GlobalKey<_HideableState> _hideableKey = GlobalKey<_HideableState>();

  // Key used to steal the state of the widget returned by
  // [OpenContainer.openBuilder] from the source route and attach it to the
  // same widget included in the [_OpenContainerRoute] where it fades out.
  final GlobalKey _closedBuilderKey = GlobalKey();

  Future<void> openContainer() async {
    await Navigator.of(context,rootNavigator: widget.useRootNavigator).push(_OpenContainerRoute<bool>(
        closedBuilder: widget.closedBuilder,
        openBuilder: widget.openBuilder,
        hideableKey: _hideableKey,
        closedBuilderKey: _closedBuilderKey,
        useRootNavigator: widget.useRootNavigator,
        transitionDuration: Duration(milliseconds: 3000))
    );
  }


  @override
  Widget build(BuildContext context) {
    return Hideable(
      key: _hideableKey,
      child: GestureDetector(
        onTap: widget.tappable ? openContainer : null,
        child: Material(
            child: Builder(
              key: _closedBuilderKey,
              builder: (BuildContext context){
                return widget.closedBuilder(context,openContainer);
              },
            )
        ),
      ),
    );
  }
}

class Hideable extends StatefulWidget {
  const Hideable({
    Key? key,
    this.child,
  }) : super(key: key);

  final Widget? child;

  @override
  _HideableState createState() => _HideableState();
}

class _HideableState extends State<Hideable> {
  Size? get placeholderSize => _placeholderSize;
  Size? _placeholderSize;
  set placeholderSize(Size? size){
    if(_placeholderSize == size){
      return;
    }
    setState(() {
      _placeholderSize = size;
    });
  }

  /// When true the child is not visible, but will maintain its size.
  ///
  /// The value of this property is ignored when [placeholderSize] is non-null
  /// (i.e. [isInTree] returns false).
  bool get isVisible => _visible;
  bool _visible = true;
  set isVisible(bool value) {
    if (_visible == value) {
      return;
    }
    setState(() {
      _visible = value;
    });
  }

  /// Whether the child is currently included in the tree.
  ///
  /// When it is included, it may be visible or not according to [isVisible].
  bool get isInTree => _placeholderSize == null;


  @override
  Widget build(BuildContext context) {
    if(_placeholderSize != null){
      return SizedBox.fromSize(size:_placeholderSize);
    }

    return Opacity(
      opacity: _visible ? 1.0 : 0.0,
      child: widget.child,
    );
  }
}

class _OpenContainerRoute<T> extends ModalRoute<T> {
  _OpenContainerRoute({
    required this.closedBuilder,
    required this.openBuilder,
    required this.hideableKey,
    required this.closedBuilderKey,
    required this.useRootNavigator,
    required this.transitionDuration,
  });


  final Widget Function(BuildContext context, VoidCallback action) closedBuilder;
  final Widget Function(BuildContext context, VoidCallback action) openBuilder;

  // See [_OpenContainerState._hideableKey].
  final GlobalKey<_HideableState> hideableKey;

  // See [_OpenContainerState._closedBuilderKey].
  final GlobalKey closedBuilderKey;

  final bool useRootNavigator;

  // Key used for the widget returned by [OpenContainer.openBuilder] to keep
  // its state when the shape of the widget tree is changed at the end of the
  // animation to remove all the craft that was necessary to make the animation
  // work.
  final GlobalKey _openBuilderKey = GlobalKey();

  // Defines the position and the size of the (opening) [OpenContainer] within
  // the bounds of the enclosing [Navigator].
  final RectTween _rectTween = RectTween();

  AnimationStatus? _lastAnimationStatus;
  AnimationStatus? _currentAnimationStatus;

  // final ShapeBorderTween _shapeTween;
  // final Tween<double> _elevationTween;

  @override
  final Duration transitionDuration;

  @override
  TickerFuture didPush(){
    _takeMeasurements(navigatorContext: hideableKey.currentContext!);

    animation!.addStatusListener((AnimationStatus status) {
      _lastAnimationStatus = _currentAnimationStatus;
      _currentAnimationStatus = status;
      switch(status){
        case AnimationStatus.dismissed:
          _toggleHideable(hide: false);
          break;
        case AnimationStatus.completed:
          _toggleHideable(hide: true);
          break;
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          break;
      }
    });

    print("TickerFuture didPush()");

    return super.didPush();
  }

  @override
  bool didPop(T? result){
    //_takeMeasurements(navigatorContext: subtreeContext!,delayForSourceRoute: true);
    return super.didPop(result);
  }


  void _toggleHideable({required bool hide}) {
    if (hideableKey.currentState != null) {
      hideableKey.currentState!
        ..placeholderSize = null
        ..isVisible = !hide;
    }
  }

  void _takeMeasurements({
    required BuildContext navigatorContext,
    bool delayForSourceRoute = false,
  }) {
    final RenderBox navigator = Navigator.of(
      navigatorContext,
      rootNavigator: useRootNavigator,
    ).context.findRenderObject()! as RenderBox;
    final Size navSize = _getSize(navigator);
    _rectTween.end = Offset.zero & navSize;

    void takeMeasurementsInSourceRoute([Duration? _]) {
      if (!navigator.attached || hideableKey.currentContext == null) {
        return;
      }
      _rectTween.begin = _getRect(hideableKey, navigator);
      hideableKey.currentState!.placeholderSize = _rectTween.begin!.size;
    }

    if (delayForSourceRoute) {
      SchedulerBinding.instance!
          .addPostFrameCallback(takeMeasurementsInSourceRoute);
    } else {
      takeMeasurementsInSourceRoute();
    }
    print("begin:${_rectTween.begin},end:${_rectTween.end}");
  }

  Size _getSize(RenderBox render) {
    assert(render.hasSize);
    return render.size;
  }

  // Returns the bounds of the [RenderObject] identified by `key` in the
  // coordinate system of `ancestor`.
  Rect _getRect(GlobalKey key, RenderBox ancestor) {
    assert(key.currentContext != null);
    assert(ancestor.hasSize);
    final RenderBox render =
    key.currentContext!.findRenderObject()! as RenderBox;
    assert(render.hasSize);
    return MatrixUtils.transformRect(
      render.getTransformTo(ancestor),
      Offset.zero & render.size,
    );
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Align(
      alignment: Alignment.topLeft,
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final Animation<double> curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
            reverseCurve:
            false ? null : Curves.fastOutSlowIn.flipped,
          );

          final Rect rect = _rectTween.evaluate(curvedAnimation)!;
          return SizedBox.expand(
            child: Container(
              color: Colors.transparent,
              child: Align(
                  alignment: Alignment.topLeft,
                  child:  Transform.translate(
                    offset: Offset(rect.left,rect.top),
                    child: SizedBox(
                      width: rect.width,
                      height: rect.height,
                      child: Material(
                        clipBehavior: Clip.antiAlias,
                        animationDuration: Duration.zero,
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            openBuilder(context, (){})
                          ],
                        ),
                      ),
                    ),
                  )
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

}