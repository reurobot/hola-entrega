import 'dart:async';

import 'package:eshop_multivendor/Provider/explore_provider.dart';
import 'package:eshop_multivendor/widgets/GridViewProduct.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

import '../../Helper/Color.dart';
import '../../Helper/String.dart';
import '../../Model/Section_Model.dart';
import '../../Provider/productListProvider.dart';
import '../../widgets/ListViewProdusct.dart';
import '../../widgets/appBar.dart';
import '../../widgets/desing.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/simmerEffect.dart';
import '../../widgets/snackbar.dart';
import '../NoInterNetWidget/NoInterNet.dart';

class SliderProductList extends StatefulWidget {
  final String id;
  final String name;

  const SliderProductList({
    super.key,
    required this.id,
    required this.name,
  });

  @override
  State<StatefulWidget> createState() => StateProduct();
}

String? totalProduct;
bool isProgress = false;
final List<TextEditingController> controllerText = [];

class StateProduct extends State<SliderProductList> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  RangeValues? currentRangeValues;

  int total = 0;
  bool filterApply = false;
  ScrollController controller = ScrollController();
  List filterList = [];
  String minPrice = '0', maxPrice = '0';

  bool _isFirstLoad = true;

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  AnimationController? _animationController;
  AnimationController? _animationController1;

  late AnimationController listViewIconController;

  late StateSetter setStater;

  bool notificationisnodata = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProduct('0');
    });

    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _animationController1 =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    listViewIconController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    buttonController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    _animationController!.dispose();
    _animationController1!.dispose();
    listViewIconController.dispose();
    currentRangeValues = null;
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void setStateNow() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
        widget.name,
        context,
        setStateNow,
      ),
      key: _scaffoldKey,
      body: isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showForm(),
                DesignConfiguration.showCircularProgress(
                  isProgress,
                  colors.primary,
                ),
              ],
            )
          : NoInterNet(
              setStateNoInternate: setStateNoInternate,
              buttonSqueezeanimation: buttonSqueezeanimation,
              buttonController: buttonController,
            ),
      bottomNavigationBar: null,
    );
  }

  void setStateNoInternate() async {
    _playAnimation();
    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          total = 0;
          getProduct('0');
        } else {
          await buttonController!.reverse();
          if (mounted) {
            setState(
              () {},
            );
          }
        }
      },
    );
  }

  void getProduct(dynamic top) {
    context.read<ProductListProvider>().getSliderList(widget.id).then((value) async {
      bool error = value['error'];
      String? msg = value['message'];
      setState(() {
        _isLoading = false;
      });

      if (!error) {
        total = int.parse(value['total']);
        if (_isFirstLoad) {
          filterList = value['filters'];
          minPrice = value[MINPRICE].toString();
          maxPrice = value[MAXPRICE].toString();
          _isFirstLoad = false;
        }
        if (currentRangeValues == null) {
          if (value[MINPRICE] == null || value[MAXPRICE] == null) {
            currentRangeValues = null;
          } else {
            currentRangeValues =
                RangeValues(double.tryParse(minPrice) ?? 0, double.tryParse(maxPrice) ?? 0);
          }
        }
        var data = value['data'];
        if (data.isNotEmpty) {
          List<Product> tempList = (data as List).map((data) => Product.fromJson(data)).toList();

          getAvailVarient(tempList);
        } else {
          if (msg != 'Products Not Found !') setSnackbar(msg!, context);
        }
      } else {
        if (msg != 'Products Not Found !') setSnackbar(msg!, context);
        notificationisnodata = true;
      }

      setState(
        () {
          _isLoading = false;
        },
      );
    });
  }

  void getAvailVarient(List<Product> tempList) {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == '2') {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == '1') {
            tempList[j].selVarient = i;
            break;
          }
        }
      }
    }

    productList.addAll(tempList);
  }

  Widget _showForm() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? context.watch<ExploreProvider>().getCurrentView != 'GridView'
                  ? ShimmerEffect()
                  : ShimmerEffectGrid()
              : productList.isEmpty || notificationisnodata
                  ? DesignConfiguration.getNoItem(context)
                  : context.watch<ExploreProvider>().getCurrentView != 'GridView'
                      ? NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: ListView.builder(
                            controller: controller,
                            shrinkWrap: true,
                            itemCount: productList.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ListIteamListWidget(
                                index: index,
                                productList: productList,
                                length: productList.length,
                                setState: setStateNow,
                              );
                            },
                          ),
                        )
                      : NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: GridView.count(
                            shrinkWrap: true,
                            padding: const EdgeInsetsDirectional.only(top: 10, start: 8),
                            crossAxisCount: 2,
                            controller: controller,
                            childAspectRatio: 0.62,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: List.generate(
                              productList.length,
                              (index) {
                                return GridViewProductListWidget(
                                  pad: false,
                                  index: index,
                                  productList: productList,
                                  setState: setStateNow,
                                );
                              },
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  void clearAll() {
    setState(() {
      productList.clear();
    });
  }

  void errorListener(SpeechRecognitionError error) {
    if (kDebugMode) {
      print(error);
    }
    setState(() {
      setSnackbar('NO_MATCH'.translate(context: context), context);
    });
  }
}
