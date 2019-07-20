/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime: 2019-07-20 21:03
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'dataSource.dart';
import 'test_indicator.dart';

Widget buildRefresher(RefreshController controller,{int count:20}){
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      width: 375.0,
      height: 690.0,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        child: ListView.builder(
          itemBuilder: (c,i) => Text(data[i]),
          itemCount: 0,
          itemExtent: 100,
        ),
        controller: controller,
      ),
    ),

  );
}

// consider two situation, the one is Viewport full,second is Viewport not full
void testRequestFun(bool full){
  testWidgets("requestRefresh(init),requestLoading function", (tester) async{

    final RefreshController _refreshController = RefreshController(initialRefresh: true);

    await tester.pumpWidget(buildRefresher(_refreshController,count: full?20:1));
    //init Refresh
    await tester.pumpAndSettle();
    expect(_refreshController.headerStatus, RefreshStatus.refreshing);
    _refreshController.refreshCompleted();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(_refreshController.headerStatus, RefreshStatus.idle);

    _refreshController.position.jumpTo(200.0);
    _refreshController.requestRefresh(duration: Duration(milliseconds: 500),curve: Curves.linear);
    await tester.pumpAndSettle();
    _refreshController.refreshCompleted();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(_refreshController.headerStatus, RefreshStatus.idle);


    _refreshController.requestLoading();
    await tester.pumpAndSettle();
    expect(_refreshController.footerStatus, LoadStatus.loading);
  });
}

void main(){
  
  
  test("check RefreshController inital param ", () async{

    final RefreshController _refreshController = RefreshController(initialRefreshStatus: RefreshStatus.idle,initialLoadStatus: LoadStatus.noMore);

    expect(_refreshController.headerMode.value, RefreshStatus.idle);

    expect(_refreshController.footerMode.value,LoadStatus.noMore);
  });

  testWidgets("check RefreshController function if valid", (tester) async{

    final RefreshController _refreshController = RefreshController();

    await tester.pumpWidget(buildRefresher(_refreshController));

    _refreshController.headerMode.value = RefreshStatus.refreshing;
    _refreshController.refreshCompleted();
    expect(_refreshController.headerMode.value, RefreshStatus.completed);

    _refreshController.headerMode.value = RefreshStatus.refreshing;
    _refreshController.refreshFailed();
    expect(_refreshController.headerMode.value, RefreshStatus.failed);

    _refreshController.headerMode.value = RefreshStatus.refreshing;
    _refreshController.refreshToIdle();
    expect(_refreshController.headerMode.value, RefreshStatus.idle);

    _refreshController.headerMode.value = RefreshStatus.refreshing;
    _refreshController.refreshToIdle();
    expect(_refreshController.headerMode.value, RefreshStatus.idle);


    _refreshController.footerMode.value = LoadStatus.loading;
    _refreshController.loadComplete();
    await tester.pump(Duration(milliseconds: 200));
    expect(_refreshController.footerMode.value, LoadStatus.idle);


    _refreshController.footerMode.value = LoadStatus.loading;
    _refreshController.loadFailed();
    await tester.pump(Duration(milliseconds: 200));
    expect(_refreshController.footerMode.value, LoadStatus.failed);

    _refreshController.footerMode.value = LoadStatus.loading;
    _refreshController.loadNoData();
    await tester.pump(Duration(milliseconds: 200));
    expect(_refreshController.footerMode.value, LoadStatus.noMore);
  });

  testRequestFun(true);

  testRequestFun(false);



}