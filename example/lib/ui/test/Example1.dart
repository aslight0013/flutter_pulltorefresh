import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Example1 extends StatefulWidget {
  Example1({Key key}) : super(key: key);

  @override
  Example1State createState() => Example1State();
}

class Example1State extends State<Example1> {
//  RefreshMode  refreshing = RefreshMode.idle;
//  LoadMode loading = LoadMode.idle;
  RefreshController _refreshController;
  ScrollController _scrollController;
  List<Widget> data = [];
  void _getDatas() {
    for (int i = 0; i < 14; i++) {
      data.add(Container(
        color:Colors.greenAccent,
        margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
        child: Center(
          child: Text('Data $i'),
        ),
      ));
    }
  }

  void scrollTop() {
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  void enterRefresh() {
    _refreshController.requestRefresh();
  }

  void _onOffsetCallback(bool isUp, double offset) {
  }

  @override
  void initState() {
    // TODO: implement initState
    _getDatas();
    _scrollController = ScrollController(keepScrollOffset: true);
    _refreshController = RefreshController();
    SchedulerBinding.instance.addPostFrameCallback((_) {
//      _refreshController.requestRefresh(true);
    });
    super.initState();
  }


//  Widget _footerCreate(BuildContext context,int mode){
//    return new ClassicIndicator(mode: mode);
//  }

  @override
  Widget build(BuildContext context) {
    return  NestedScrollView(
        key:PageStorageKey("q"),
        controller: _scrollController,
        headerSliverBuilder: (c, s) => [
          SliverPersistentHeader(
              delegate: _SliverDelegate(
                  child: Container(
                    height: 300.0,
                    color: Colors.red,
                  ))),
          SliverAppBar(
            backgroundColor: Colors.greenAccent,
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                background: Image.network(
                  "https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=0c21b1ac3066ae4d354a3b2e0064c8be&auto=format&fit=crop&w=500&q=60",
                  fit: BoxFit.cover,
                )),
          ),
        ],
        body: Container(
          child: SmartRefresher(

              controller: _refreshController,
              enablePullDown: true,
              isNestWrapped: true,
              header: ClassicHeader(
                idleIcon: Container(),
                idleText: "Load more...",
              ),
              enablePullUp: true,

              onRefresh: () {
                Future.delayed(const Duration(milliseconds: 2009))
                    .then((val) {
                  data.add(Card(
                    margin: EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                    child: Center(
                      child: Text('Data '),
                    ),
                  ));

                  setState(() {
                    _refreshController.refreshCompleted();
                  });
                });
              },
              onLoading: (){
                Future.delayed(const Duration(milliseconds: 2009))
                    .then((val) {
                  setState(() {
                    data.add(Card(
                      margin: EdgeInsets.only(
                          left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                      child: Center(
                        child: Text('Data '),
                      ),
                    ));
                    _refreshController.loadComplete();
                  });
                });
              },
              onOffsetChange: _onOffsetCallback,
              child: ListView.builder(

                itemExtent: 100.0,
                itemCount: data.length,
                itemBuilder: (context, index) => Item(),
              )),
        ));
  }
}

class Item extends StatefulWidget {
  @override
  _ItemState createState() => _ItemState();
}

class _ItemState extends State<Item> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color:Colors.red,
      margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
      child: Center(
        child: Text('Data'),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

class _SliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverDelegate({this.child});

  @override
  // TODO: implement minExtent
  double get minExtent => 50.0;

  @override
  // TODO: implement maxExtent
  double get maxExtent => 100.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // TODO: implement build
    return child;
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    // TODO: implement shouldRebuild
    return false;
  }


}
