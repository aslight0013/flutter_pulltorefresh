/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime:2018-05-01 11:39
*/

import 'package:flutter/widgets.dart';
import 'internals/default_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:pull_to_refresh/src/internals/indicator_wrap.dart';
import 'package:pull_to_refresh/src/internals/refresh_physics.dart';
import 'indicator/classic_indicator.dart';
import 'indicator/material_indicator.dart';
import 'package:flutter/scheduler.dart';

typedef void OnOffsetChange(bool up, double offset);

enum RefreshStatus { idle, canRefresh, refreshing, completed, failed }

enum LoadStatus { idle, loading, noMore }

enum RefreshStyle { Follow, UnFollow, Behind, Front }

/*
    This is the most important component that provides drop-down refresh and up loading.
 */
class SmartRefresher extends StatefulWidget {
  //indicate your listView
  final ScrollView child;

  final RefreshIndicator header;
  final LoadIndicator footer;

  // This bool will affect whether or not to have the function of drop-up load.
  final bool enablePullUp;

  //This bool will affect whether or not to have the function of drop-down refresh.
  final bool enablePullDown;

  // upper and downer callback when you drag out of the distance
  final Function onRefresh, onLoading;

  // This method will callback when the indicator changes from edge to edge.
  final OnOffsetChange onOffsetChange;

  //controll inner state
  final RefreshController controller;

  // When SmartRefresher is wrapped in some ScrollView,if true:it will find the primaryScrollController in parent widget
  final bool isNestWrapped;

  SmartRefresher(
      {Key key,
      @required this.child,
      @required this.controller,
      RefreshIndicator header,
      LoadIndicator footer,
      this.enablePullDown: default_enablePullDown,
      this.enablePullUp: default_enablePullUp,
      this.onRefresh,
      this.onLoading,
      this.onOffsetChange,
      this.isNestWrapped: false})
      : assert(child != null),
        assert(controller != null),
        footer = footer ?? ClassicFooter(),
        header = header ??
            (defaultTargetPlatform == TargetPlatform.iOS
                ? ClassicHeader()
                : MaterialClassicHeader()),
        super(key: key);

  @override
  SmartRefresherState createState() => SmartRefresherState();

  static SmartRefresherState of(BuildContext context) {
    return context
        ?.ancestorStateOfType(const TypeMatcher<SmartRefresherState>());
  }
}

class SmartRefresherState extends State<SmartRefresher> {
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    // there is no method to get PrimaryScrollController in initState
    widget.controller.scrollController =
        widget.child.controller ?? PrimaryScrollController.of(context);
    widget.controller._header = widget.header;

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(SmartRefresher oldWidget) {
    // TODO: implement didUpdateWidget
    if (widget.enablePullDown != oldWidget.enablePullDown) {
      widget.controller.headerMode.value = RefreshStatus.idle;
    }
    if (widget.enablePullUp != oldWidget.enablePullUp) {
      widget.controller.footerMode.value = LoadStatus.idle;
    }
    widget.controller.scrollController =
        widget.child.controller ?? PrimaryScrollController.of(context);
    widget.controller._header = widget.header;
    super.didUpdateWidget(oldWidget);
  }

  ScrollPhysics _getScrollPhysics() {
    if (widget.header.refreshStyle == RefreshStyle.Front) {
      return widget.enablePullDown
          ? RefreshClampPhysics(springBackDistance: widget.header.height)
          : ClampingScrollPhysics();
    } else {
      return RefreshBouncePhysics();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers;

    if (widget.child is BoxScrollView) {
      //avoid system inject padding when own indicator top or bottom
      Widget sliver = (widget.child as BoxScrollView).buildChildLayout(context);
      EdgeInsets effectPadding = (widget.child as BoxScrollView).padding;
      if (effectPadding == null) {
        final MediaQueryData mediaQuery = MediaQuery.of(context, nullOk: true);
        if (mediaQuery != null) {
          effectPadding = mediaQuery.padding.copyWith(
              left: 0.0,
              right: 0.0,
              top: widget.enablePullDown ? 0.0 : null,
              bottom: widget.enablePullUp ? 0.0 : null);
          sliver = MediaQuery(
            child: sliver,
            data: mediaQuery.copyWith(
              padding: effectPadding,
            ),
          );
        }
      }
      if (effectPadding != null) {
        sliver = SliverPadding(padding: effectPadding, sliver: sliver);
      }
      slivers = [sliver];
    } else {
      slivers = List.from(widget.child.buildSlivers(context), growable: true);
    }

    if (widget.enablePullDown) {
      slivers.insert(0, widget.header);
    }
    if (widget.enablePullUp) {
      slivers.add(widget.footer);
    }
    return CustomScrollView(
      physics: _getScrollPhysics(),
      controller: widget.controller.scrollController,
      cacheExtent: widget.child.cacheExtent,
      key: widget.child.key,
      center: widget.child.center,
      anchor: widget.child.anchor,
      semanticChildCount: widget.child.semanticChildCount,
      slivers: slivers,
      reverse: widget.child.reverse,
    );
  }

}

class RefreshController {
  ValueNotifier<RefreshStatus> headerMode = ValueNotifier(RefreshStatus.idle);
  ValueNotifier<LoadStatus> footerMode = ValueNotifier(LoadStatus.idle);
  ScrollController scrollController;
  RefreshIndicator _header;

  RefreshStatus get headerStatus => headerMode?.value;

  LoadStatus get footerStatus => footerMode?.value;

  bool get isRefresh => headerMode?.value == RefreshStatus.refreshing;

  bool get isLoading => footerMode?.value == LoadStatus.loading;

  void requestRefresh(
      {Duration duration: const Duration(milliseconds: 300),
      Curve curve: Curves.linear}) {
    assert(scrollController != null,
        'Try not to call requestRefresh() before build,please call after the ui was rendered');
    if (headerMode?.value != RefreshStatus.idle) return;
    scrollController.animateTo(
        _header.refreshStyle == RefreshStyle.Front
            ? 0.0
            : -_header.triggerDistance,
        duration: duration,
        curve: curve);
  }

  void requestLoading(
      {Duration duration: const Duration(milliseconds: 300),
      Curve curve: Curves.linear}) {
    assert(scrollController != null,
        'Try not to call requestLoading() before build,please call after the ui was rendered');
    if (footerStatus == LoadStatus.idle) {
      if (_header.refreshStyle == RefreshStyle.Front) {
        if (scrollController.position.maxScrollExtent - _header.height < 0.0) {
          footerMode.value = LoadStatus.loading;
        } else
          scrollController
              .animateTo(scrollController.position.maxScrollExtent,
                  duration: duration, curve: curve)
              .whenComplete(() {
            footerMode.value = LoadStatus.loading;
          });
      } else {
        scrollController
            .animateTo(scrollController.position.maxScrollExtent,
                duration: duration, curve: curve)
            .whenComplete(() {
          footerMode.value = LoadStatus.loading;
        });
      }
    }
  }

  void refreshCompleted() {
    headerMode?.value = RefreshStatus.completed;
  }

  void refreshFailed() {
    headerMode?.value = RefreshStatus.failed;
  }

  void loadComplete() {
    // change state after ui update,else it will have a bug:twice loading
    SchedulerBinding.instance.addPostFrameCallback((_) {
      footerMode?.value = LoadStatus.idle;
    });
  }

  void loadNoData() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      footerMode?.value = LoadStatus.noMore;
    });
  }

  void resetNoData() {
    footerMode?.value = LoadStatus.idle;
  }

  void dispose() {
    headerMode.dispose();
    footerMode.dispose();
    headerMode = null;
    footerMode = null;
  }
}
