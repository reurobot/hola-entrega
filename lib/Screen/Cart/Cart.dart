import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/assetsConstant.dart';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Cart/Widget/search_user_client/search_user_client_widget.dart';
import 'package:eshop_multivendor/Screen/Cart/Widget/proceed_checkout_button.dart';
import 'package:eshop_multivendor/Screen/Cart/Widget/dynamicDiscountTable.dart';
import 'package:eshop_multivendor/Screen/Cart/Widget/dynamicDiscountTable.dart';
import 'package:eshop_multivendor/Model/user_client_search.dart';
import 'package:eshop_multivendor/Screen/Payment/Widget/paymentMethod.dart';
import 'package:eshop_multivendor/Screen/WebView/instamojo_webview.dart';
import 'package:eshop_multivendor/Screen/homePage/widgets/hideAppBarBottom.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:mime/mime.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import 'package:paytmpayments_allinonesdk/paytmpayments_allinonesdk.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../Helper/Color.dart';
import '../../Helper/String.dart';
import '../../Helper/routes.dart';
import '../../Model/Model.dart';
import '../../Model/Section_Model.dart';
import '../../Model/User.dart';
import '../../Provider/paymentProvider.dart';
import '../../Provider/productListProvider.dart';
import '../../Provider/promoCodeProvider.dart';
import '../../repository/cartRepository.dart';
import '../../widgets/ButtonDesing.dart';
import '../../widgets/appBar.dart';
import '../../widgets/desing.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/security.dart';
import '../../widgets/simmerEffect.dart';
import '../../widgets/snackbar.dart';
import '../Dashboard/Dashboard.dart';
import '../Manage_Address/Manage_Address.dart';
import '../NoInterNetWidget/NoInterNet.dart';
import '../Payment/Payment.dart';
import '../StripeService/Stripe_Service.dart';
import '../WebView/PaypalWebviewActivity.dart';
import '../WebView/midtransWebView.dart';
import 'Widget/attachPrescriptionImageWidget.dart';
import 'Widget/bankTransferContentWidget.dart';
import 'Widget/cartIteamWidget.dart';
import 'Widget/cartListIteamWidget.dart';
import 'Widget/confirmDialog.dart';
import 'Widget/noIteamCartWidget.dart';
import 'Widget/orderSummeryWidget.dart';
import 'Widget/paymentWidget.dart';
import 'Widget/saveLaterIteamWidget.dart';
import 'Widget/setAddress.dart';
import '../SQLiteData/SqliteData.dart';

FocusNode focusNode = FocusNode();

class Cart extends StatefulWidget {
  const Cart({super.key, required this.fromBottom});

  final bool fromBottom;

  @override
  State<StatefulWidget> createState() => StateCart();
}

//String? stripePayId;

class StateCart extends State<Cart> with TickerProviderStateMixin {
  AnimationController? buttonController;
  Animation? buttonSqueezeanimation;
  String? msg;
  bool discountApllied = false;
  final paystackPlugin = PaystackFlutter();
  String razorpayOrderId = '';

  String? rozorpayMsg;

  bool _isCartLoad = true, _isSaveLoad = true;

  bool _isLoading = true;
  UserClient? _selectedUserClient;
  Razorpay? _razorpay;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final ScrollController _scrollControllerOnCartItems = ScrollController();
  final ScrollController _scrollControllerOnSaveForLaterItems =
      ScrollController();

  double calcularDescuento(double total) {
    if (total >= 20000) {
      return 0.25;
    } else if (total >= 15000) {
      return 0.20;
    } else if (total >= 10000) {
      return 0.15;
    } else if (total >= 5000) {
      return 0.10;
    } else if (total >= 2000) {
      return 0.07;
    } else if (total >= 1000) {
      return 0.05;
    }
    return 0.0;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().noteController.dispose();
        context.read<CartProvider>().emailController.clear();
        context.read<CartProvider>().promoC.dispose();
        context.read<CartProvider>().setProgress(false);

        for (int i = 0;
            i < context.read<CartProvider>().controller.length;
            i++) {
          context.read<CartProvider>().controller[i].dispose();
        }
      }
    });
    _scrollControllerOnCartItems.removeListener(() {});
    _scrollControllerOnSaveForLaterItems.removeListener(() {});
    if (_razorpay != null) _razorpay!.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().setPrescriptionImages('', []);
      context.read<CartProvider>().prescriptionImages.clear();
      context.read<CartProvider>().selectedMethod = null;
      context.read<CartProvider>().selectedMethod = null;
      context.read<CartProvider>().payMethod = null;
      context.read<CartProvider>().deliverable = false;
      context.read<CartProvider>().isShippingDeliveryChargeApplied = false;
      context.read<CartProvider>().promocode = null;
      context.read<CartProvider>().promoC.clear();
      context.read<CartProvider>().isAvailable = true;
      callApi();
    });
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );

    Future.delayed(Duration.zero).then(
      (value) {
        hideAppbarAndBottomBarOnScroll(
          _scrollControllerOnCartItems,
          context,
        );
      },
    );
  }

  Future<void> cartFun({
    required int index,
    required int selectedPos,
    required double total,
  }) async {
    db.moveToCartOrSaveLater(
      'save',
      context
          .read<CartProvider>()
          .saveLaterList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .id!,
      context.read<CartProvider>().saveLaterList[index].id!,
      context,
    );

    context.read<CartProvider>().productIds.add(context
        .read<CartProvider>()
        .saveLaterList[index]
        .productList![0]
        .prVarientList![selectedPos]
        .id!);
    context.read<CartProvider>().productIds.remove(context
        .read<CartProvider>()
        .saveLaterList[index]
        .productList![0]
        .prVarientList![selectedPos]
        .id!);
    context.read<CartProvider>().oriPrice =
        context.read<CartProvider>().oriPrice + total;
    context
        .read<CartProvider>()
        .addCartItem(context.read<CartProvider>().saveLaterList[index]);
    context.read<CartProvider>().saveLaterList.removeAt(index);

    context.read<CartProvider>().addCart = false;
    context.read<CartProvider>().setProgress(false);
    setState(() {});
  }

  Future<void> saveForLaterFun({
    required int index,
    required int selectedPos,
    required double total,
    required List<SectionModel> cartList,
  }) async {
    db.moveToCartOrSaveLater(
      'cart',
      cartList[index].productList![0].prVarientList![selectedPos].id!,
      cartList[index].id!,
      context,
    );
    context
        .read<CartProvider>()
        .productIds
        .add(cartList[index].productList![0].prVarientList![selectedPos].id!);
    context.read<CartProvider>().productIds.remove(
        cartList[index].productList![0].prVarientList![selectedPos].id!);
    context.read<CartProvider>().oriPrice =
        context.read<CartProvider>().oriPrice - total;
    context.read<CartProvider>().saveLaterList.add(
          SectionModel(
            id: cartList[index].id,
            varientId: cartList[index].varientId,
            qty: '1',
            sellerId: cartList[index].sellerId,
            productList: cartList[index].productList,
          ),
        );
    context.read<CartProvider>().removeCartItem(
        cartList[index].productList![0].prVarientList![selectedPos].id!);

    context.read<CartProvider>().saveLater = false;
    context.read<CartProvider>().setProgress(false);
    setState(() {});
  }

  Future<void> callApi() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<CartProvider>().setProgress(false);
      }

      if (context.read<UserProvider>().email != '') {
        context.read<CartProvider>().emailController.text =
            context.read<UserProvider>().email;
      }

      if (context.read<UserProvider>().userId != '') {
        _getCart('0');
        _getSaveLater('1');
      } else {
        context.read<CartProvider>().productIds = (await db.getCart())!;
        _getOffCart();
        context.read<CartProvider>().productVariantIds =
            (await db.getSaveForLater())!;

        _getOffSaveLater();
      }
      setState(() {});
    });
  }

  void clearAll() {
    context.read<CartProvider>().totalPrice = 0;

    context.read<CartProvider>().oriPrice = 0;
    context.read<CartProvider>().taxPer = 0;
    context.read<CartProvider>().deliveryCharge = 0;
    context.read<CartProvider>().addressList.clear();

    context.read<CartProvider>().setCartlist([]);
    context.read<CartProvider>().setProgress(false);

    context.read<CartProvider>().promoAmt = 0;
    context.read<CartProvider>().remWalBal = 0;
    context.read<CartProvider>().usedBalance = 0;
    context.read<CartProvider>().payMethod = null;
    context.read<CartProvider>().isPromoValid = false;
    context.read<CartProvider>().isUseWallet = false;
    context.read<CartProvider>().isPayLayShow = true;
    context.read<CartProvider>().selectedMethod = null;
    context.read<CartProvider>().deliverable = false;
    context.read<CartProvider>().codDeliverChargesOfShipRocket = 0.0;
    context.read<CartProvider>().prePaidDeliverChargesOfShipRocket = 0.0;
    context.read<CartProvider>().isLocalDelCharge = null;
    context.read<CartProvider>().isShippingDeliveryChargeApplied = false;
    context.read<CartProvider>().shipRocketDeliverableDate = '';
    context.read<CartProvider>().isAddressChange = null;
    context.read<CartProvider>().noteController.clear();
    context.read<CartProvider>().promoC.clear();
    context.read<CartProvider>().promocode = null;

    // Clear app link token after successful order placement
    DatabaseHelper().clearAppLinks();
  }

  void setStateNow() {
    setState(() {});
  }

  Future<void> setStateNoInternate() async {
    _playAnimation();
    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          callApi();
        } else {
          await buttonController!.reverse();
          if (mounted) setState(() {});
        }
      },
    );
  }

  void updatePromo(String promo) {
    setState(
      () {
        context.read<CartProvider>().promoC.text = promo;
      },
    );
  }

  void callShowOverlayMethod() {
    _showOverlay(context);
  }

  Future<void> promoEmpty() async {
    setState(() {
      context.read<CartProvider>().totalPrice =
          context.read<CartProvider>().totalPrice +
              context.read<CartProvider>().promoAmt;
    });
  }

  Future checkout() {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    List<SectionModel> tempCartListForTestCondtion =
        context.read<CartProvider>().cartList;

    if (context.read<CartProvider>().addressList.isNotEmpty &&
        !context.read<CartProvider>().deliverable &&
        context.read<CartProvider>().cartList[0].productList![0].productType !=
            'digital_product') {
      checkDeliverable(false);
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(circularBorderRadius10),
          topRight: Radius.circular(circularBorderRadius10),
        ),
      ),
      builder: (builder) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            context.read<CartProvider>().checkoutState = setState;
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: isNetworkAvail
                    ? context.read<CartProvider>().cartList.isEmpty
                        ? const EmptyCart()
                        : _isLoading
                            ? const ShimmerEffect()
                            : Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          child: Padding(
                                            padding:
                                                const EdgeInsetsDirectional.all(
                                                    10.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                tempCartListForTestCondtion[0]
                                                            .productType ==
                                                        'digital_product'
                                                    ? const SizedBox()
                                                    : SetAddress(
                                                        update: setStateNow),
                                                AttachPrescriptionImages(
                                                    cartList: context
                                                        .read<CartProvider>()
                                                        .cartList),
                                                SelectPayment(
                                                  updateCheckout:
                                                      updateCheckout,
                                                ),
                                                cartItems(context
                                                    .read<CartProvider>()
                                                    .cartList),
                                                OrderSummery(
                                                  cartList: context
                                                      .read<CartProvider>()
                                                      .cartList,
                                                ),
                                                SearchUserClientWidget(
                                                  onUserSelected: (value) {
                                                    _selectedUserClient = value;
                                                  },
                                                ),
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom,
                ),
              ],
            ),
           ),
                                        ),
                                        Selector<CartProvider, bool>(
                                          builder: (context, data, child) {
                                            return DesignConfiguration
                                                .showCircularProgress(
                                                    data, colors.primary);
                                          },
                                          selector: (_, provider) =>
                                              provider.isProgress,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: Platform.isIOS
                                        ? const EdgeInsetsDirectional.only(
                                            bottom: 10)
                                        : null,
                                    color: Theme.of(context).colorScheme.white,
                                    child: Row(
                                      children: <Widget>[
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 15.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${DesignConfiguration.getPriceFormat(context, context.read<CartProvider>().totalPrice)!} ',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ubuntu',
                                                ),
                                              ),
                                              Text(
                                                '${context.read<CartProvider>().cartList.length}${'ITEMS'.translate(context: context)}',
                                                style: const TextStyle(
                                                  fontFamily: 'ubuntu',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        SimBtn(
                                          borderRadius: circularBorderRadius5,
                                          size: 0.4,
                                          title: 'PLACE_ORDER'
                                              .translate(context: context),
                                          onBtnSelected: context
                                                  .read<CartProvider>()
                                                  .placeOrder
                                              ? () {
                                                  // Deshabilitar botón mientras se procesa
                                                  context
                                                      .read<CartProvider>()
                                                      .checkoutState!(
                                                    () {
                                                      context
                                                          .read<CartProvider>()
                                                          .placeOrder = false;
                                                    },
                                                  );

                                                  // Validación: si el buscador está habilitado, debe seleccionar un cliente
                                                  final userIdErp = context
                                                      .read<UserProvider>()
                                                      .userIdErp;
                                                  final isSearchClientEnabled =
                                                      userIdErp != null &&
                                                          userIdErp != 0;

                                                  if (isSearchClientEnabled &&
                                                      _selectedUserClient ==
                                                          null) {
                                                    setSnackbar(
                                                        'Debe seleccionar un cliente',
                                                        context);
                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                    return;
                                                  }

                                                  if (tempCartListForTestCondtion[0].productType != 'digital_product' &&
                                                      (context.read<CartProvider>().selAddress == null ||
                                                          context.read<CartProvider>().selAddress ==
                                                              '' ||
                                                          context
                                                              .read<
                                                                  CartProvider>()
                                                              .selAddress!
                                                              .isEmpty)) {
                                                    msg = 'addressWarning'
                                                        .translate(
                                                            context: context);

                                                    Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (context) =>
                                                            const ManageAddress(
                                                          home: false,
                                                        ),
                                                      ),
                                                    );
                                                    setState(() {});

                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (tempCartListForTestCondtion[0].productList![0].productType != 'digital_product' &&
                                                      !context
                                                          .read<CartProvider>()
                                                          .deliverable) {
                                                    checkDeliverable(true);

                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (tempCartListForTestCondtion[0].productType != 'digital_product' &&
                                                      !context
                                                          .read<CartProvider>()
                                                          .deliverable) {
                                                    msg = 'NOT_DEL'.translate(
                                                        context: context);
                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (context
                                                          .read<CartProvider>()
                                                          .payMethod ==
                                                      null) {
                                                    msg = 'payWarning'
                                                        .translate(
                                                            context: context);
                                                    Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                          updateCheckout,
                                                          msg,
                                                        ),
                                                      ),
                                                    );
                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (tempCartListForTestCondtion[0].productType !=
                                                          'digital_product' &&
                                                      (context.read<CartProvider>().isTimeSlot! &&
                                                          (context.read<CartProvider>().isLocalDelCharge == null ||
                                                              context
                                                                  .read<
                                                                      CartProvider>()
                                                                  .isLocalDelCharge!) &&
                                                          int.parse(context.read<PaymentProvider>().allowDay!) >
                                                              0 &&
                                                          (context.read<CartProvider>().selDate == null ||
                                                              context
                                                                  .read<
                                                                      CartProvider>()
                                                                  .selDate!
                                                                  .isEmpty) &&
                                                          IS_LOCAL_ON != '0')) {
                                                    msg = 'dateWarning'
                                                        .translate(
                                                            context: context);
                                                    Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                          updateCheckout,
                                                          msg,
                                                        ),
                                                      ),
                                                    );

                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (tempCartListForTestCondtion[0].productType !=
                                                          'digital_product' &&
                                                      (context.read<CartProvider>().isTimeSlot! &&
                                                          (context.read<CartProvider>().isLocalDelCharge == null || context.read<CartProvider>().isLocalDelCharge!) &&
                                                          context.read<PaymentProvider>().timeSlotList.isNotEmpty &&
                                                          (context.read<CartProvider>().selTime == null || context.read<CartProvider>().selTime!.isEmpty) &&
                                                          IS_LOCAL_ON != '0')) {
                                                    msg = 'timeWarning'
                                                        .translate(
                                                            context: context);
                                                    Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            Payment(
                                                          updateCheckout,
                                                          msg,
                                                        ),
                                                      ),
                                                    );

                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else if (double.parse(MIN_ALLOW_CART_AMT!) > context.read<CartProvider>().oriPrice) {
                                                    setSnackbar(
                                                        "${'MIN_CART_AMT'.translate(context: context)} ${DesignConfiguration.getPriceFormat(context, double.parse(MIN_ALLOW_CART_AMT!))!}",
                                                        context);
                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  } else {
                                                    if (!context
                                                        .read<CartProvider>()
                                                        .isProgress) {
                                                      confirmDialog();
                                                    }
                                                    context
                                                        .read<CartProvider>()
                                                        .checkoutState!(
                                                      () {
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .placeOrder = true;
                                                      },
                                                    );
                                                  }
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                    : NoInterNet(
                        setStateNoInternate: setStateNoInternate,
                        buttonSqueezeanimation: buttonSqueezeanimation,
                        buttonController: buttonController,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> checkDeliverable(bool navigate) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          ADD_ID: context.read<CartProvider>().selAddress,
        };
        apiBaseHelper.postAPICall(checkCartDelApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          List data = getdata['data'];
          context.read<CartProvider>().setProgress(false);

          if (error) {
            context.read<CartProvider>().deliverableList =
                (data).map((data) => Model.checkDeliverable(data)).toList();

            context.read<CartProvider>().checkoutState!(() {
              context.read<CartProvider>().deliverable = false;
              context.read<CartProvider>().placeOrder = true;
            });

            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
          } else {
            if (data.isEmpty) {
              context.read<CartProvider>().deliverable = true;

              setState(() {});

              if (context.read<CartProvider>().checkoutState != null) {
                context.read<CartProvider>().checkoutState!(() {});
              }
            } else {
              bool isDeliverible = false;
              bool? isShipRocket;
              context.read<CartProvider>().deliverableList =
                  (data).map((data) => Model.checkDeliverable(data)).toList();

              for (int i = 0;
                  i < context.read<CartProvider>().deliverableList.length;
                  i++) {
                if (context.read<CartProvider>().deliverableList[i].isDel ==
                    false) {
                  isDeliverible = false;
                  break;
                } else {
                  isDeliverible = true;
                  if (context.read<CartProvider>().deliverableList[i].delBy ==
                      'standard_shipping') {
                    isShipRocket = true;
                  }
                }
              }

              if (isDeliverible) {
                getShipRocketDeliveryCharge(
                    shipRocket:
                        isShipRocket != null && isShipRocket ? '1' : '0',
                    navigate: navigate);
              }
            }
            context.read<CartProvider>().setProgress(false);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar('somethingMSg'.translate(context: context), context);
      }
    } else {
      isNetworkAvail = false;
      setState(() {});
    }
  }

  Future<void> getShipRocketDeliveryCharge(
      {required String shipRocket, required bool navigate}) async {
    isNetworkAvail = await isNetworkAvailable();
    if (context.read<UserProvider>().userId == null ||
        context.read<UserProvider>().userId!.trim().isEmpty) {
      return;
    }
    if (isNetworkAvail) {
      if (context.read<CartProvider>().addressList.isNotEmpty) {
        try {
          context.read<CartProvider>().setProgress(true);

          var parameter = {
            ADD_ID: context
                .read<CartProvider>()
                .addressList[context.read<CartProvider>().selectedAddress!]
                .id,
            ONLY_DEL_CHARGE: shipRocket,
            DEL_PINCODE: context
                .read<CartProvider>()
                .addressList[context.read<CartProvider>().selectedAddress!]
                .pincode
          };

          print(parameter);

          CartRepository.fetchUserCart(parameter: parameter).then(
              (getData) async {
            bool error = getData['error'];
            String? msg = getData['message'];
            var data = getData['data'];

            if (error) {
              setSnackbar(msg.toString(), context);
              context.read<CartProvider>().checkoutState!(() {
                context.read<CartProvider>().deliverable = false;
              });
            } else {
              if (shipRocket == '1') {
                context.read<CartProvider>().codDeliverChargesOfShipRocket =
                    double.parse(data['delivery_charge_with_cod'].toString());

                context.read<CartProvider>().prePaidDeliverChargesOfShipRocket =
                    double.parse(
                        data['delivery_charge_without_cod'].toString());
                if (context.read<CartProvider>().codDeliverChargesOfShipRocket >
                        0 &&
                    context
                            .read<CartProvider>()
                            .prePaidDeliverChargesOfShipRocket >
                        0) {
                  context.read<CartProvider>().isLocalDelCharge = false;
                } else {
                  context.read<CartProvider>().isLocalDelCharge = true;
                }

                context.read<CartProvider>().shipRocketDeliverableDate =
                    data['estimate_date'] ?? '';
                if (context.read<CartProvider>().payMethod == '') {
                  context.read<CartProvider>().deliveryCharge = context
                      .read<CartProvider>()
                      .codDeliverChargesOfShipRocket;
                  if (context
                          .read<CartProvider>()
                          .isShippingDeliveryChargeApplied ==
                      false) {
                    context.read<CartProvider>().totalPrice =
                        context.read<CartProvider>().deliveryCharge +
                            context.read<CartProvider>().oriPrice;
                    context
                        .read<CartProvider>()
                        .isShippingDeliveryChargeApplied = true;
                  }
                } else {
                  if (context.read<CartProvider>().payMethod ==
                      'COD_LBL'.translate(context: context)) {
                    context.read<CartProvider>().deliveryCharge = context
                        .read<CartProvider>()
                        .codDeliverChargesOfShipRocket;
                    if (context
                            .read<CartProvider>()
                            .isShippingDeliveryChargeApplied ==
                        false) {
                      context.read<CartProvider>().totalPrice =
                          context.read<CartProvider>().deliveryCharge +
                              context.read<CartProvider>().oriPrice;
                      context
                          .read<CartProvider>()
                          .isShippingDeliveryChargeApplied = true;
                    }
                  } else {
                    context.read<CartProvider>().deliveryCharge = context
                        .read<CartProvider>()
                        .prePaidDeliverChargesOfShipRocket;
                    if (context
                            .read<CartProvider>()
                            .isShippingDeliveryChargeApplied ==
                        false) {
                      context.read<CartProvider>().totalPrice =
                          context.read<CartProvider>().deliveryCharge +
                              context.read<CartProvider>().oriPrice;
                      context
                          .read<CartProvider>()
                          .isShippingDeliveryChargeApplied = true;
                    }
                  }
                }
              } else {
                context.read<CartProvider>().isLocalDelCharge = true;
                context.read<CartProvider>().deliveryCharge =
                    double.parse('0.0');
                context.read<CartProvider>().totalPrice =
                    context.read<CartProvider>().deliveryCharge +
                        context.read<CartProvider>().oriPrice;
              }

              Future.microtask(() {
                context.read<CartProvider>().checkoutState!.call(() {
                  context.read<CartProvider>().deliverable = true;
                });
              });

              if (context.read<CartProvider>().isPromoValid!) {
                await context
                    .read<PromoCodeProvider>()
                    .validatePromocode(
                      check: false,
                      context: context,
                      promocode: context.read<CartProvider>().promoC.text,
                      update: setStateNow,
                    )
                    .then(
                  (value) {
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  },
                );
              } else if (context.read<CartProvider>().isUseWallet!) {
                context.read<CartProvider>().setProgress(false);
                context.read<CartProvider>().remWalBal = 0;
                context.read<CartProvider>().payMethod = null;
                context.read<CartProvider>().usedBalance = 0;
                context.read<CartProvider>().isUseWallet = false;
                context.read<CartProvider>().isPayLayShow = true;
                setState(() {});
              } else {
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              }
            }
            context.read<CartProvider>().setProgress(false);
            setState(() {});

            if (context.read<CartProvider>().checkoutState != null) {
              context.read<CartProvider>().checkoutState!(() {});
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar('somethingMSg'.translate(context: context), context);
        }
      }
    } else {
      isNetworkAvail = false;
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      {required String status, required String orderID}) async {
    var parameter = {ORDER_ID: orderID, STATUS: status};
    var result = await ApiBaseHelper().postAPICall(updateOrderApi, parameter);

    return {'error': result['error'], 'message': result['message']};
  }

  void updateCheckout() {
    if (mounted) context.read<CartProvider>().checkoutState!(() {});
  }

  Future<void> razorpayPayment(
    String orderID,
    String? msg,
  ) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    String? contact = settingsProvider.mobile;
    String? email = settingsProvider.email;
    String amt =
        (context.read<CartProvider>().totalPrice * 100).toStringAsFixed(2);

    context.read<CartProvider>().setProgress(true);

    context.read<CartProvider>().checkoutState!(() {});
    try {
      //create a razorpayOrder for capture payment automatically
      var response = await ApiBaseHelper()
          .postAPICall(createRazorpayOrder, {'order_id': orderID});
      print("response data*****${response['data']}");
      var razorpayOrderID = response['data']['id'];
      var options = {
        KEY: context.read<CartProvider>().razorpayId,
        AMOUNT: amt,
        NAME: settingsProvider.userName,
        'prefill': {CONTACT: contact, EMAIL: email},
        'order_id': razorpayOrderID,
      };
      razorpayOrderId = orderID;
      rozorpayMsg = msg;
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      _razorpay!.open(options);
    } catch (e) {}
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      var parameter = {
        ORDER_ID: orderId,
      };

      http.Response response =
          await post(deleteOrderApi, body: parameter, headers: headers)
              .timeout(const Duration(seconds: timeOut));
      var getdata = json.decode(response.body);

      bool error = getdata['error'];
      if (!error) {
        //context.read<CartProvider>().removeCart();
      }

      if (mounted) {
        setState(() {});
        Navigator.of(context).pop();
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setSnackbar('somethingMSg'.translate(context: context), context);
        setState(() {});
      }
    }
  }

  void paytmPayment(String? tranId, String orderID, String? status, String? msg,
      bool redirect) async {
    // ignore: unused_local_variable
    String? paymentResponse;
    context.read<CartProvider>().setProgress(true);

    String callBackUrl =
        '${context.read<CartProvider>().payTesting ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in'}/theia/paytmCallback?ORDER_ID=$orderID';

    var parameter = {
      AMOUNT: context.read<CartProvider>().totalPrice.toString(),
      ORDER_ID: orderID
    };

    try {
      apiBaseHelper.postAPICall(getPytmChecsumkApi, parameter).then(
        (getdata) async {
          bool error = getdata['error'];

          if (!error) {
            String txnToken = getdata['txn_token'];
            setState(
              () {
                paymentResponse = txnToken;
              },
            );
            print(
                'context.read<CartProvider>().paytmMerId******${context.read<CartProvider>().paytmMerId!}****$orderID***${context.read<CartProvider>().totalPrice.toString()}****$txnToken****$callBackUrl****${context.read<CartProvider>().payTesting}');
            var response = await PaytmPaymentsAllinonesdk().startTransaction(
                context.read<CartProvider>().paytmMerId!,
                orderID,
                context.read<CartProvider>().totalPrice.toString(),
                txnToken,
                callBackUrl,
                context.read<CartProvider>().payTesting,
                false);
            print('response***$response');

            if (response!['errorCode'] == null) {
              if (response['STATUS'] == 'TXN_SUCCESS') {
                await updateOrderStatus(orderID: orderID, status: PLACED);
                addTransaction(response['TXNID'], orderID, SUCCESS, msg, true);
              } else {
                deleteOrder(orderID);
              }

              setSnackbar(response['STATUS'], context);
            } else {
              String paymentResponse = response['RESPMSG'];

              if (response['response'] != null) {
                addTransaction(response['TXNID'], orderID,
                    response['STATUS'] ?? '', paymentResponse, false);
              }

              setSnackbar(paymentResponse, context);
            }

            context.read<CartProvider>().setProgress(false);
            context.read<CartProvider>().placeOrder = true;
            setState(() {});
          } else {
            context.read<CartProvider>().checkoutState!(
              () {
                context.read<CartProvider>().placeOrder = true;
              },
            );
            context.read<CartProvider>().setProgress(false);
            setSnackbar(getdata['message'], context);
          }
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
        },
      );
    } catch (e) {}
  }

  void payWithPhonePeCart(String orderId) {
    initiatePhonePePayment(
      context: context,
      orderId: orderId,
      paymentType: 'cart',
      onSuccess: () {
        context.read<UserProvider>().setCartCount('0');
        clearAll();
        Routes.navigateToOrderSuccessScreen(context);
        if (mounted) context.read<CartProvider>().setProgress(false);
      },
      onFailure: () {
        deleteOrder(orderId);
        setSnackbar(
            'PHONEPE_PAYMENT_FAILED'.translate(context: context), context);
        if (mounted) {
          context.read<CartProvider>().checkoutState!(
            () => context.read<CartProvider>().placeOrder = true,
          );
          context.read<CartProvider>().setProgress(false);
        }
      },
    );
  }

  // void initPhonePeSdk({required String orderId}) async {
  //   final phonePeDetails = await PaymentRepository.getPhonePeDetails(
  //     userId: context.read<UserProvider>().userId ?? '0',
  //     type: 'cart',
  //     mobile: context.read<UserProvider>().mob.trim().isEmpty
  //         ? context.read<UserProvider>().userId ?? '0'
  //         : context.read<UserProvider>().mob,
  //     orderId: orderId,
  //     transationId: orderId,
  //   );

  //   final data = phonePeDetails['data'];
  //   final environment = data['environment'];
  //   final flowId = data['flowId'];
  //   final merchantId = data['request']['merchantId'];
  //   final enbaleLogging = data['enableLogging'];

  //   print(
  //       'PhonePe Init: env=$environment, merchantId=$merchantId, flowId=$flowId');

  //   PhonePePaymentSdk.init(
  //     environment,
  //     merchantId,
  //     flowId,
  //     enbaleLogging,
  //   ).then((isInitialized) {
  //     startPaymentPhonePe(orderId: orderId, phonePeDetails: phonePeDetails);
  //   }).catchError((error) {
  //     print('PhonePe SDK init error: $error');
  //     return false;
  //   });
  // }

  // void startPaymentPhonePe(
  //     {required String orderId, required dynamic phonePeDetails}) async {
  //   try {
  //     final data = phonePeDetails['data'];
  //     final request = data['request'];
  //     Map<String, dynamic> payload = {
  //       'orderId': request['merchantOrderId'],
  //       'merchantId': request['merchantId'],
  //       'token': request['token'],
  //       'paymentMode': request['paymentMode'],
  //     };
  //     String payloadJson = jsonEncode(payload);
  //     print('Payment Request: $payloadJson');

  //     final package = Platform.isAndroid ? packageName : iosPackage;
  //     final response = await PhonePePaymentSdk.startTransaction(
  //       payloadJson,
  //       package,
  //     );
  //     print("PhonePe Status ----> ${response?['status']}");
  //     if (response != null) {
  //       String status = response['status'].toString();
  //       if (status == 'SUCCESS' ||
  //           status == 'PAYMENT_SUCCESS' ||
  //           status.toLowerCase().contains('success') ||
  //           status.toLowerCase().contains('payment_success')) {
  //         context.read<UserProvider>().setCartCount('0');
  //         clearAll();
  //         Routes.navigateToOrderSuccessScreen(context);
  //         if (mounted) {
  //           context.read<CartProvider>().setProgress(false);
  //         }
  //       } else {
  //         deleteOrder(orderId);
  //         setSnackbar(
  //             'PHONEPE_PAYMENT_FAILED'.translate(context: context), context);
  //         if (mounted) {
  //           context.read<CartProvider>().checkoutState!(
  //             () => context.read<CartProvider>().placeOrder = true,
  //           );
  //         }
  //         context.read<CartProvider>().setProgress(false);
  //       }
  //     } else {
  //       deleteOrder(orderId);
  //       setSnackbar(
  //           'PHONEPE_PAYMENT_FAILED'.translate(context: context), context);
  //       if (mounted) {
  //         context.read<CartProvider>().checkoutState!(
  //           () => context.read<CartProvider>().placeOrder = true,
  //         );
  //       }
  //       context.read<CartProvider>().setProgress(false);
  //     }
  //   } catch (error) {
  //     print('PhonePe Payment Error: $error');
  //     setSnackbar(
  //         'PHONEPE_PAYMENT_FAILED'.translate(context: context), context);
  //     context.read<CartProvider>().setProgress(false);
  //   }
  // }

  Future<void> placeOrder(String? tranId) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      context.read<CartProvider>().setProgress(true);
      List<SectionModel> tempCartListForTestCondtion =
          context.read<CartProvider>().cartList;
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      String? mob = settingsProvider.mobile;

      String? varientId, quantity;

      List<SectionModel> cartList = context.read<CartProvider>().cartList;
      for (SectionModel sec in cartList) {
        varientId =
            varientId != null ? '$varientId,${sec.varientId!}' : sec.varientId;
        quantity = quantity != null ? '$quantity,${sec.qty!}' : sec.qty;
      }

      String? payVia;
      if (context.read<CartProvider>().payMethod ==
          'COD_LBL'.translate(context: context)) {
        payVia = 'COD';
      } else if (context.read<CartProvider>().payMethod ==
          'PAYPAL_LBL'.translate(context: context)) {
        payVia = 'PayPal';
      } else if (context.read<CartProvider>().payMethod ==
          'RAZORPAY_LBL'.translate(context: context)) {
        payVia = 'RazorPay';
      } else if (context.read<CartProvider>().payMethod ==
          'PHONEPE_LBL'.translate(context: context)) {
        payVia = 'phonepe';
      } else if (context.read<CartProvider>().payMethod ==
          'PAYSTACK_LBL'.translate(context: context)) {
        payVia = 'Paystack';
      } else if (context.read<CartProvider>().payMethod ==
          'FLUTTERWAVE_LBL'.translate(context: context)) {
        payVia = 'Flutterwave';
      } else if (context.read<CartProvider>().payMethod ==
          'STRIPE_LBL'.translate(context: context)) {
        payVia = 'Stripe';
      } else if (context.read<CartProvider>().payMethod ==
          'PAYTM_LBL'.translate(context: context)) {
        payVia = 'Paytm';
      } else if (context.read<CartProvider>().payMethod == 'Wallet') {
        payVia = 'Wallet';
      } else if (context.read<CartProvider>().payMethod ==
          'BANKTRAN'.translate(context: context)) {
        payVia = 'bank_transfer';
      } else if (context.read<CartProvider>().payMethod ==
          'MidTrans'.translate(context: context)) {
        payVia = 'midtrans';
      } else if (context.read<CartProvider>().payMethod ==
          'My Fatoorah'.translate(context: context)) {
        payVia = 'my fatoorah';
      } else if (context.read<CartProvider>().payMethod ==
          'instamojo_lbl'.translate(context: context)) {
        payVia = 'instamojo';
      } else if (context.read<CartProvider>().payMethod == 'Credito') {
        payVia = 'Credito';
      }

      // Validación de seguridad: si payVia es null, mostrar error y salir
      if (payVia == null) {
        setSnackbar('Método de pago no válido, selecciona otro', context);
        context.read<CartProvider>().setProgress(false);
        if (mounted) {
          context.read<CartProvider>().checkoutState!(
            () {
              context.read<CartProvider>().placeOrder = true;
            },
          );
        }
        return;
      }

      var request = http.MultipartRequest('POST', placeOrderApi);
      request.headers.addAll(headers ?? {});

      try {
        if (mob != '') {
          request.fields[MOBILE] = mob;
        } else {
          if (context
                  .read<CartProvider>()
                  .cartList[0]
                  .productList![0]
                  .productType !=
              'digital_product') {
            request.fields[MOBILE] = context
                .read<CartProvider>()
                .addressList[context.read<CartProvider>().selectedAddress!]
                .mobile!;
          }
        }

        request.fields[PRODUCT_VARIENT_ID] = varientId!;
        if (_selectedUserClient?.customerIdErp != null) {
          request.fields[CUSTOMER_ID_ERP] = _selectedUserClient!.customerIdErp!;
        }
        request.fields[QUANTITY] = quantity!;
        request.fields[TOTAL] =
            context.read<CartProvider>().oriPrice.toString();
        request.fields[FINAL_TOTAL] =
            context.read<CartProvider>().totalPrice.toString();

        request.fields[DEL_CHARGE] =
            context.read<CartProvider>().deliveryCharge.toString();

        request.fields[TAX_PER] =
            context.read<CartProvider>().taxPer.toString();
        request.fields[PAYMENT_METHOD] = payVia;
        if (tempCartListForTestCondtion[0].productType != 'digital_product') {
          request.fields[ADD_ID] = context.read<CartProvider>().selAddress!;

          if (context.read<CartProvider>().isTimeSlot!) {
            request.fields[DELIVERY_TIME] =
                context.read<CartProvider>().selTime ?? 'Anytime';
            request.fields[DELIVERY_DATE] =
                context.read<CartProvider>().selDate ?? '';
          }
        }

        if (tempCartListForTestCondtion[0].productType == 'digital_product') {
          request.fields['email'] =
              context.read<CartProvider>().emailController.text;
        }
        request.fields[ISWALLETBALUSED] =
            context.read<CartProvider>().isUseWallet! ? '1' : '0';
        request.fields[WALLET_BAL_USED] =
            context.read<CartProvider>().usedBalance.toString();
        request.fields[ORDER_NOTE] =
            context.read<CartProvider>().noteController.text;

        if (context.read<CartProvider>().isPromoValid!) {
          request.fields[PROMOCODE] = context.read<CartProvider>().promocode!;
          request.fields[PROMO_DIS] =
              context.read<CartProvider>().promoAmt.toString();
        }

        // Build a map of variantId -> token for all products with a token
        Map<String, String> variantTokenMap = {};
        for (final section in cartList) {
          final slug = section.productList?[0].slug;
          final variantId = section.varientId;
          if (slug != null &&
              slug.isNotEmpty &&
              variantId != null &&
              variantId.isNotEmpty) {
            String? token =
                await DatabaseHelper().getLatestAppLinkTokenForProduct(slug);
            if (token != null && token.isNotEmpty) {
              variantTokenMap[variantId] = token;
            }
          }
        }
        if (variantTokenMap.isNotEmpty) {
          request.fields['app_link_token'] = jsonEncode(variantTokenMap);
          print(
              "Added app_link_token to order: ${jsonEncode(variantTokenMap)}");
        }

        if (context.read<CartProvider>().payMethod ==
                'COD_LBL'.translate(context: context) ||
            context.read<CartProvider>().payMethod == 'Wallet') {
          request.fields[ACTIVE_STATUS] = PLACED;
        } else if (tempCartListForTestCondtion[0].productType ==
            'digital_product') {
          // request.fields[ACTIVE_STATUS] = DELIVERD;
        } else {
          if (context.read<CartProvider>().payMethod ==
              'PHONEPE_LBL'.translate(context: context)) {
            request.fields[ACTIVE_STATUS] = 'draft';
          } else {
            request.fields[ACTIVE_STATUS] = WAITING;
          }
        }
        print(
            'Full prescriptionImages map: ${context.read<CartProvider>().prescriptionImages}');

        final ids = varientId.split(',');

        for (final id in ids) {
          final trimmedId = id.trim();

          final images =
              context.read<CartProvider>().getPrescriptionImages(trimmedId);

          if (images.isNotEmpty) {
            for (final image in images) {
              final mimeType = lookupMimeType(image.path);

              if (mimeType == null) {
                continue;
              }

              final extension = mimeType.split('/');
              final fieldName = getDocumentField(trimmedId);

              final pic = await http.MultipartFile.fromPath(
                fieldName,
                image.path,
                contentType: MediaType(extension[0], extension[1]),
              );
              request.files.add(pic);
            }
          } else {
            print('No prescription images found for variant ID: $trimmedId');
          }
        }
        if (kDebugMode) {
          print(
              'response api*********$placeOrderApi**********$headers*********${request.fields}*************');
        }
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        context.read<CartProvider>().placeOrder = true;
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);
          print('getdata response place order****$getdata');
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            String orderId = getdata['order_id'].toString();
            if (context.read<CartProvider>().payMethod ==
                'RAZORPAY_LBL'.translate(context: context)) {
              razorpayPayment(orderId, msg);
            } else if (context.read<CartProvider>().payMethod ==
                'PHONEPE_LBL'.translate(context: context)) {
              payWithPhonePeCart(orderId);
            } else if (context.read<CartProvider>().payMethod ==
                'PAYPAL_LBL'.translate(context: context)) {
              paypalPayment(orderId);
            } else if (context.read<CartProvider>().payMethod ==
                'STRIPE_LBL'.translate(context: context)) {
              stripePayment(context.read<CartProvider>().stripePayId, orderId,
                  tranId == 'succeeded' ? PLACED : WAITING, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'PAYSTACK_LBL'.translate(context: context)) {
              paystackPayment(context, tranId, orderId, SUCCESS, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'PAYTM_LBL'.translate(context: context)) {
              paytmPayment(tranId, orderId, SUCCESS, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'FLUTTERWAVE_LBL'.translate(context: context)) {
              flutterwavePayment(tranId, orderId, SUCCESS, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'MidTrans'.translate(context: context)) {
              midTrasPayment(
                  orderId, tranId == 'succeeded' ? PLACED : WAITING, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'My Fatoorah'.translate(context: context)) {
              fatoorahPayment(tranId, orderId,
                  tranId == 'succeeded' ? PLACED : WAITING, msg, true);
            } else if (context.read<CartProvider>().payMethod ==
                'instamojo_lbl'.translate(context: context)) {
              instamojoPayment(orderId);
            } else {
              context.read<UserProvider>().setCartCount('0');
              clearAll();
              Routes.navigateToOrderSuccessScreen(context);
            }
          } else {
            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        if (mounted) {
          context.read<CartProvider>().checkoutState!(
            () {
              context.read<CartProvider>().placeOrder = true;
            },
          );
        }
        setSnackbar('somethingMSg'.translate(context: context), context);
        context.read<CartProvider>().setProgress(false);
      } catch (e) {
        if (mounted) {
          context.read<CartProvider>().checkoutState!(
            () {
              context.read<CartProvider>().placeOrder = true;
            },
          );
        }
        setSnackbar('Ocurrió un error, vuelve a intentarlo', context);
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted) {
        context.read<CartProvider>().checkoutState!(
          () {
            isNetworkAvail = false;
          },
        );
      }
    }
  }

  Future<void> instamojoPayment(String orderId) async {
    try {
      var parameter = {
        ORDER_ID: orderId,
      };
      apiBaseHelper.postAPICall(getInstamojoWebviewApi, parameter).then(
        (getdata) {
          print('getdata instamojo****$getdata');
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            if (getdata['data']['longurl'] != null &&
                getdata['data']['longurl'] != '') {
              String? data = getdata['data']['longurl'];
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => InstamojoWebview(
                    url: data,
                    from: 'order',
                    orderId: orderId,
                  ),
                ),
              );
            } else {
              deleteOrder(orderId);
              setSnackbar('somethingMSg'.translate(context: context), context);
            }
          } else {
            deleteOrder(orderId);
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
        },
      );
    } on TimeoutException catch (_) {
      setSnackbar('somethingMSg'.translate(context: context), context);
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {
        ORDER_ID: orderId,
        AMOUNT: context.read<CartProvider>().totalPrice.toString()
      };
      apiBaseHelper.postAPICall(paypalTransactionApi, parameter).then(
        (getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            String? data = getdata['data'];
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => WebViewClass(
                  url: data,
                  from: 'order',
                  orderId: orderId,
                ),
              ),
            );
          } else {
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
        },
      );
    } on TimeoutException catch (_) {
      setSnackbar('somethingMSg'.translate(context: context), context);
    }
  }

  Future<void> addTransaction(
    String? tranId,
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    try {
      var parameter = {
        ORDER_ID: orderID,
        TYPE: context.read<CartProvider>().payMethod,
        TXNID: tranId,
        AMOUNT: context.read<CartProvider>().totalPrice.toString(),
        STATUS: status,
        MSG: msg ?? '$status the payment'
      };
      apiBaseHelper.postAPICall(addTransactionApi, parameter).then(
        (getdata) {
          bool error = getdata['error'];
          String? msg1 = getdata['message'];

          if (!error) {
            if (redirect) {
              context.read<UserProvider>().setCartCount('0');
              clearAll();
              Routes.navigateToOrderSuccessScreen(context);
            }
          } else {
            setSnackbar(msg1!, context);
          }
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
        },
      );
    } on TimeoutException catch (_) {
      setSnackbar('somethingMSg'.translate(context: context), context);
    }
  }

  Future<void> paystackPayment(
    BuildContext context,
    String? tranId,
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    context.read<CartProvider>().setProgress(true);
    String? email = context.read<SettingProvider>().email;

    paystackPlugin.pay(
      context: context,
      secretKey: context.read<CartProvider>().paystackId!,
      amount: (context.read<CartProvider>().totalPrice * 100).toDouble(),
      email: email ?? '',
      firstName: '',
      lastName: '',
      reference: _getReference(),
      callbackUrl: '',
      onSuccess: (paystackCallback) {
        addTransaction(paystackCallback.reference, orderID, SUCCESS, msg, true);
        context.read<CartProvider>().setProgress(false);
      },
      onCancelled: (paystackCallback) {
        deleteOrder(orderID);
        setSnackbar('Payment cancelled', context);
        if (mounted) {
          context.read<CartProvider>().checkoutState!(
            () {
              context.read<CartProvider>().placeOrder = true;
            },
          );
        }
        context.read<CartProvider>().setProgress(false);
      },
    );
  }

  Future<void> fatoorahPayment(
    String? tranId,
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        String amount = context.read<CartProvider>().totalPrice.toString();
        String successUrl =
            '${context.read<CartProvider>().myfatoorahSuccessUrl!}?order_id=$orderID&amount=${double.parse(amount)}';
        String errorUrl =
            '${context.read<CartProvider>().myfatoorahErrorUrl!}?order_id=$orderID&amount=${double.parse(amount)}';
        String token = context.read<CartProvider>().myfatoorahToken!;
        context.read<CartProvider>().setProgress(true);
        var response = await MFSDK.startPayment(
          context: context,
          successChild: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Payment Done Successfully ...!'.translate(context: context),
                  style: const TextStyle(
                    fontFamily: 'ubuntu',
                  ),
                ),
                const SizedBox(
                  width: 200,
                  height: 100,
                  child: Icon(
                    Icons.done,
                    size: 100,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          request: context.read<CartProvider>().myfatoorahPaymentMode == 'test'
              ? MFExecutePaymentRequest.test(
                  currencyIso: () {
                    if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Kuwait') {
                      return MFCountry.kuwait;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'UAE') {
                      return MFCountry.UAE;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Egypt') {
                      return MFCountry.Egypt;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Bahrain') {
                      return MFCountry.Bahrain;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Jordan') {
                      return MFCountry.Jordan;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Oman') {
                      return MFCountry.Oman;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'SaudiArabia') {
                      return MFCountry.SaudiArabia;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'SaudiArabia') {
                      return MFCountry.Qatar;
                    }
                    return MFCountry.SaudiArabia;
                  }(),
                  successUrl: successUrl,
                  errorUrl: errorUrl,
                  invoiceAmount: double.parse(amount),
                  userDefinedField: orderID,
                  language: () {
                    if (context.read<CartProvider>().myfatoorahLanguage ==
                        'english') {
                      return MFLanguage.English;
                    }
                    return MFLanguage.Arabic;
                  }(),
                  token: token,
                )
              : MFExecutePaymentRequest.live(
                  currencyIso: () {
                    if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Kuwait') {
                      return MFCountry.kuwait;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'UAE') {
                      return MFCountry.UAE;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Egypt') {
                      return MFCountry.Egypt;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Bahrain') {
                      return MFCountry.Bahrain;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Jordan') {
                      return MFCountry.Jordan;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'Oman') {
                      return MFCountry.Oman;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'SaudiArabia') {
                      return MFCountry.SaudiArabia;
                    } else if (context.read<CartProvider>().myfatoorahMFCountry ==
                        'SaudiArabia') {
                      return MFCountry.Qatar;
                    }
                    return MFCountry.SaudiArabia;
                  }(),
                  successUrl: successUrl,
                  userDefinedField: orderID,
                  errorUrl: errorUrl,
                  invoiceAmount: double.parse(amount),
                  language: () {
                    if (context.read<CartProvider>().myfatoorahLanguage ==
                        'english') {
                      return MFLanguage.English;
                    }
                    return MFLanguage.Arabic;
                  }(),
                  token: token,
                ),
        );
        context.read<CartProvider>().setProgress(false);

        if (response.status.toString() == 'PaymentStatus.Success') {
          context.read<CartProvider>().setProgress(true);

          await updateOrderStatus(orderID: orderID, status: PLACED);
          addTransaction(
            response.paymentId,
            orderID,
            PLACED,
            msg,
            true,
          );
        }
        if (response.status.toString() == 'PaymentStatus.None') {
          setSnackbar(response.status.toString(), context);
          deleteOrder(orderID);
          //
        }
        if (response.status.toString() == 'PaymentStatus.Error') {
          setSnackbar(response.status.toString(), context);
          deleteOrder(orderID);
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar('somethingMSg'.translate(context: context), context);
      }
    } else {
      if (mounted) {
        context.read<CartProvider>().checkoutState!(
          () {
            isNetworkAvail = false;
          },
        );
      }
    }
  }

  Future<void> midTrasPayment(
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        var parameter = {
          AMOUNT: context.read<CartProvider>().totalPrice.toString(),
          ORDER_ID: orderID
        };
        apiBaseHelper.postAPICall(createMidtransTransactionApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['data'];
              String redirectUrl = data['redirect_url'];
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => MidTrashWebview(
                    url: redirectUrl,
                    from: 'order',
                    orderId: orderID,
                  ),
                ),
              ).then(
                (value) async {
                  isNetworkAvail = await isNetworkAvailable();
                  if (isNetworkAvail) {
                    try {
                      context.read<CartProvider>().setProgress(true);
                      var parameter = {
                        ORDER_ID: orderID,
                      };
                      apiBaseHelper
                          .postAPICall(
                              getMidtransTransactionStatusApi, parameter)
                          .then(
                        (getdata) async {
                          bool error = getdata['error'];
                          String? msg = getdata['message'];
                          var data = getdata['data'];
                          if (!error) {
                            String statuscode = data['status_code'];

                            if (statuscode == '404') {
                              deleteOrder(orderID);
                              if (mounted) {
                                context.read<CartProvider>().checkoutState!(
                                  () {
                                    context.read<CartProvider>().placeOrder =
                                        true;
                                  },
                                );
                              }
                              context.read<CartProvider>().setProgress(false);
                            }

                            if (statuscode == '200') {
                              String transactionStatus =
                                  data['transaction_status'];
                              String transactionId = data['transaction_id'];
                              if (transactionStatus == 'capture') {
                                Map<String, dynamic> result =
                                    await updateOrderStatus(
                                        orderID: orderID, status: PLACED);
                                if (!result['error']) {
                                  await addTransaction(
                                    transactionId,
                                    orderID,
                                    SUCCESS,
                                    rozorpayMsg,
                                    true,
                                  );
                                } else {
                                  setSnackbar('${result['message']}', context);
                                }
                                if (mounted) {
                                  context
                                      .read<CartProvider>()
                                      .setProgress(false);
                                }
                              } else {
                                deleteOrder(orderID);
                                if (mounted) {
                                  context.read<CartProvider>().checkoutState!(
                                    () {
                                      context.read<CartProvider>().placeOrder =
                                          true;
                                    },
                                  );
                                }
                                context.read<CartProvider>().setProgress(false);
                              }
                            }
                          } else {
                            setSnackbar(msg!, context);
                          }

                          context.read<CartProvider>().setProgress(false);
                        },
                        onError: (error) {
                          setSnackbar(error.toString(), context);
                        },
                      );
                    } on TimeoutException catch (_) {
                      context.read<CartProvider>().setProgress(false);
                      setSnackbar(
                          'somethingMSg'.translate(context: context), context);
                    }
                  } else {
                    if (mounted) {
                      context.read<CartProvider>().checkoutState!(
                        () {
                          isNetworkAvail = false;
                        },
                      );
                    }
                  }
                  if (value == 'true') {
                    context.read<CartProvider>().checkoutState!(
                      () {
                        context.read<CartProvider>().placeOrder = true;
                      },
                    );
                  } else {}
                },
              );
            } else {
              setSnackbar(msg!, context);
            }
            context.read<CartProvider>().setProgress(false);
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar('somethingMSg'.translate(context: context), context);
      }
    } else {
      if (mounted) {
        context.read<CartProvider>().checkoutState!(() {
          isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> stripePayment(String? tranId, String orderID, String? status,
      String? msg, bool redirect) async {
    context.read<CartProvider>().setProgress(true);
    var response = await StripeService.payWithPaymentSheet(
        amount:
            (context.read<CartProvider>().totalPrice * 100).toInt().toString(),
        currency: context.read<CartProvider>().stripeCurCode,
        from: 'order',
        context: context,
        awaitedOrderId: orderID);

    if (response.message == 'Transaction successful') {
      await updateOrderStatus(orderID: orderID, status: PLACED);
      addTransaction(context.read<CartProvider>().stripePayId, orderID,
          response.status == 'succeeded' ? PLACED : WAITING, msg, true);
    } else if (response.status == 'pending' || response.status == 'captured') {
      await updateOrderStatus(orderID: orderID, status: WAITING);
      addTransaction(
        context.read<CartProvider>().stripePayId,
        orderID,
        tranId == 'succeeded' ? PLACED : WAITING,
        msg,
        true,
      );
      if (mounted) {
        setState(
          () {
            context.read<CartProvider>().placeOrder = true;
          },
        );
      }
    } else {
      deleteOrder(orderID);
      if (mounted) {
        setState(
          () {
            context.read<CartProvider>().placeOrder = true;
          },
        );
      }

      context.read<CartProvider>().setProgress(false);
    }
    setSnackbar(response.message!, context);
  }

  Widget cartItems(List<SectionModel> cartList) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: cartList.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return CartIteam(
            index: index,
            cartList: cartList,
            setState: setStateNow,
            checkDeliverable: checkDeliverable);
      },
    );
  }

  Future<void> flutterwavePayment(
    String? tranId,
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        var parameter = {
          AMOUNT: context.read<CartProvider>().totalPrice.toString(),
          ORDER_ID: orderID
        };
        apiBaseHelper.postAPICall(flutterwaveApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['link'];
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => WebViewClass(
                    url: data,
                    from: 'order',
                    orderId: orderID,
                  ),
                ),
              ).then(
                (value) {
                  print('value: $value');
                  if (value == 'true') {
                    // Transaction successful - navigate to success screen
                    context.read<UserProvider>().setCartCount('0');
                    clearAll();
                    Routes.navigateToOrderSuccessScreen(context);
                    context.read<CartProvider>().setProgress(false);
                  } else {
                    deleteOrder(orderID);
                  }
                },
              );
            } else {
              setSnackbar(msg!, context);
            }

            context.read<CartProvider>().setProgress(false);
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar('somethingMSg'.translate(context: context), context);
      }
    } else {
      if (mounted) {
        context.read<CartProvider>().checkoutState!(() {
          isNetworkAvail = false;
        });
      }
    }
  }

  void confirmDialog() {
    final cartProvider = context.read<CartProvider>();
    showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withValues(alpha: 0.5),
      transitionBuilder: (dialogContext, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              elevation: 2.0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(circularBorderRadius5),
                ),
              ),
              content: const GetContent(),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'CANCEL'.translate(context: context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    cartProvider.checkoutState!(
                      () {
                        cartProvider.placeOrder = true;
                      },
                    );
                    Routes.pop(dialogContext);
                  },
                ),
                TextButton(
                  child: Text(
                    'DONE'.translate(context: context),
                    style: const TextStyle(
                      color: colors.primary,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    Routes.pop(dialogContext);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (cartProvider.payMethod ==
                          'BANKTRAN'.translate(context: context)) {
                        bankTransfer();
                      } else {
                        placeOrder('');
                      }
                    });
                  },
                )
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: false,
      barrierLabel: '',
      context: context,
      pageBuilder: (dialogContext, animation1, animation2) {
        return const SizedBox();
      },
    );
  }

  void bankTransfer() {
    showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withValues(alpha: 0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              elevation: 2.0,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(circularBorderRadius5))),
              content: const GetBankTransferContent(),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'CANCEL'.translate(context: context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    context.read<CartProvider>().checkoutState!(
                      () {
                        context.read<CartProvider>().placeOrder = true;
                      },
                    );
                    Routes.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    'DONE'.translate(context: context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    Routes.pop(context);

                    context.read<CartProvider>().setProgress(true);

                    placeOrder('');
                  },
                )
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: false,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox();
      },
    );
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isCartLoad = true;
        _isSaveLoad = true;
      });
    }
    context.read<CartProvider>().isAvailable = true;
    if (context.read<UserProvider>().userId != '') {
      clearAll();
      _getCart('0');
      return _getSaveLater('1');
    } else {
      context.read<CartProvider>().oriPrice = 0;
      // if(mounted) context.read<CartProvider>().saveLaterList.clear();

      context.read<CartProvider>().productIds = (await db.getCart())!;
      await _getOffCart();
      context.read<CartProvider>().productVariantIds =
          (await db.getSaveForLater())!;
      await _getOffSaveLater();
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void _showOverlay(BuildContext context) async {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Theme.of(context).colorScheme.black26,
            ),
            Lottie.asset(
              DesignConfiguration.setLottiePath(Assets.celebrateName),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.white,
                    ),
                    borderRadius: BorderRadius.circular(circularBorderRadius20),
                    color: Theme.of(context).colorScheme.white),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Container(
                        child: Lottie.asset(
                            DesignConfiguration.setLottiePath(
                                Assets.promocodeName),
                            height: 150,
                            width: 150),
                      ),
                      Text(
                        '${context.read<CartProvider>().promocode} applied',
                        style: TextStyle(
                          fontSize: textFontSize16,
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${'You saved'.translate(context: context)} ${DesignConfiguration.getPriceFormat(context, context.read<CartProvider>().promoAmt)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: textFontSize18,
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        'with this coupon code'.translate(context: context),
                        style: TextStyle(
                          fontSize: textFontSize12,
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
            Expanded(
              child: Center(
                          child: Text(
                            'woohoo! Thanks'.translate(context: context),
                             style: const TextStyle(
                               fontSize: textFontSize12,
                               color: colors.red,
                               fontFamily: 'ubuntu',
                             ),
                                           ),
                                         ],
                                       ),
                                      ),

                                      const SizedBox(width: 8),

                                      // TABLA DINÁMICA DE DESCUENTOS Y ALERTA
                                      // if (context.read<CartProvider>().cartList.isNotEmpty)
                                      //   const DynamicDiscountTable(),

                                     // TABLA DINÁMICA DE DESCUENTOS Y ALERTA
                                     if (context.read<CartProvider>().cartList.isNotEmpty)
                                       const DynamicDiscountTable(),
                                    
                                     // BOTÓN DESCUENTOS
                                    Expanded(
                                      flex: 3,
                                      child: InkWell(
                                        onTap: discountApllied
                                            ? null
                                            : () =>
                                                _consultarDescuentos(context),
                                        borderRadius: BorderRadius.circular(
                                          circularBorderRadius7,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .gray,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              circularBorderRadius7,
                                            ),
                                          ),
                                          child: const Text(
                                            'Solicitar descuentos',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // BOTÓN CONFIRMAR
                                    ProceedCheckoutButton(
                                      onCheckout: checkout,
                                      onCallApi: callApi,
                                      cartWidget:
                                          Cart(fromBottom: widget.fromBottom),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
  }

  void _getCart(String save) {
    context.read<CartProvider>().getUserCart(save: save, context: context);
  }

  void _getSaveLater(String save) {
    context.read<CartProvider>().getUserCart(save: save, context: context);
  }

  void _getOffCart() {
    context.read<CartProvider>().getUserOfflineCart(context);
  }

  void _getOffSaveLater() {
    // TODO: implement offline save later if needed
  }

  Widget _showContent1(BuildContext context) {
    return _showContent(context);
  }

  Widget _showContent(BuildContext context) {
    return _isCartLoad || _isSaveLoad
        ? const ShimmerEffect()
        : context.read<CartProvider>().cartList.isEmpty &&
                context.read<CartProvider>().saveLaterList.isEmpty
            ? const EmptyCart()
            : Container(
                color: Theme.of(context).colorScheme.lightWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: double.maxFinite,
                        padding: const EdgeInsets.only(
                          right: 10.0,
                          left: 10.0,
                          top: 10,
                        ),
                        child: RefreshIndicator(
                          color: colors.primary,
                          key: _refreshIndicatorKey,
                          onRefresh: _refresh,
                          child: SizedBox(
                            height: double.maxFinite,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              controller: _scrollControllerOnCartItems,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (context
                                      .read<CartProvider>()
                                      .cartList
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 0.0),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: context
                                            .read<CartProvider>()
                                            .cartList
                                            .length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (innercontext, index) {
                                          return CartListViewLayOut(
                                            index: index,
                                            setState: setStateNow,
                                            saveForLatter: saveForLaterFun,
                                            perentcontext: context,
                                          );
                                        },
                                      ),
                                    ),
                                  if (context
                                      .read<CartProvider>()
                                      .saveLaterList
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'SAVEFORLATER_BTN'
                                            .translate(context: context),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontFamily: 'ubuntu',
                                            ),
                                      ),
                                    ),
                                  if (context
                                      .read<CartProvider>()
                                      .saveLaterList
                                      .isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: context
                                          .read<CartProvider>()
                                          .saveLaterList
                                          .length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (innercontext, index) {
                                        return SaveLatterIteam(
                                          index: index,
                                          setState: setStateNow,
                                          cartFunc: cartFun,
                                          perentcontext: context,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Builder(
                          builder: (context) {
                            final cartProvider = context.watch<CartProvider>();
                            final cartList = cartProvider.cartList;

                            if (cartList.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsetsDirectional.only(
                                top: 5.0,
                                end: 10.0,
                                start: 10.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.white,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(circularBorderRadius5),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    // TOTAL
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TOTAL_PRICE'
                                                .translate(context: context),
                                          ),
                                          Text(
                                            DesignConfiguration.getPriceFormat(
                                              context,
                                              cartProvider.oriPrice,
                                            )!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontFamily: 'ubuntu',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // BOTÓN DESCUENTOS
                                    Expanded(
                                      flex: 3,
                                      child: InkWell(
                                        onTap: discountApllied
                                            ? null
                                            : () =>
                                                _consultarDescuentos(context),
                                        borderRadius: BorderRadius.circular(
                                          circularBorderRadius7,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 4,
                                          ),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .gray,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              circularBorderRadius7,
                                            ),
                                          ),
                                          child: const Text(
                                            'Solicitar descuentos',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // BOTÓN CONFIRMAR
                                    ProceedCheckoutButton(
                                      onCheckout: checkout,
                                      onCallApi: callApi,
                                      cartWidget:
                                          Cart(fromBottom: widget.fromBottom),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
  }

  Future<void> _getAddress() async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        Map<String, dynamic> parameter = {
          // USER_ID: context.read<UserProvider>().userId,
        };

        apiBaseHelper.postAPICall(getAddressApi, parameter).then((getdata) {
          bool error = getdata['error'];

          if (!error) {
            var data = getdata['data'];

            context.read<CartProvider>().addressList =
                (data as List).map((data) => User.fromAddress(data)).toList();

            if (context.read<CartProvider>().addressList.length == 1) {
              context.read<CartProvider>().selectedAddress = 0;
              context.read<CartProvider>().selAddress =
                  context.read<CartProvider>().addressList[0].id;
              if (!ISFLAT_DEL) {
                if (context.read<CartProvider>().totalPrice <
                    double.parse(
                        context.read<CartProvider>().addressList[0].freeAmt!)) {
                  context.read<CartProvider>().deliveryCharge = double.parse(
                      context
                          .read<CartProvider>()
                          .addressList[0]
                          .deliveryCharge!);
                } else {
                  context.read<CartProvider>().deliveryCharge = 0;
                }
              }
            } else {
              for (int i = 0;
                  i < context.read<CartProvider>().addressList.length;
                  i++) {
                if (context.read<CartProvider>().addressList[i].isDefault ==
                    '1') {
                  context.read<CartProvider>().selectedAddress = i;
                  context.read<CartProvider>().selAddress =
                      context.read<CartProvider>().addressList[i].id;
                  if (!ISFLAT_DEL) {
                    if (context.read<CartProvider>().totalPrice <
                        double.parse(context
                            .read<CartProvider>()
                            .addressList[i]
                            .freeAmt!)) {
                      context.read<CartProvider>().deliveryCharge =
                          double.parse(context
                              .read<CartProvider>()
                              .addressList[i]
                              .deliveryCharge!);
                    } else {
                      context.read<CartProvider>().deliveryCharge = 0;
                    }
                  }
                }
              }
            }

            if (ISFLAT_DEL) {
              if ((context.read<CartProvider>().oriPrice) <
                  double.parse(MIN_AMT!)) {
                context.read<CartProvider>().deliveryCharge =
                    double.parse(CUR_DEL_CHR!);
              } else {
                context.read<CartProvider>().deliveryCharge = 0;
              }
            }
            context.read<CartProvider>().totalPrice =
                context.read<CartProvider>().totalPrice +
                    context.read<CartProvider>().deliveryCharge;
          } else {
            if (ISFLAT_DEL) {
              if ((context.read<CartProvider>().oriPrice) <
                  double.parse(MIN_AMT!)) {
                context.read<CartProvider>().deliveryCharge =
                    double.parse(CUR_DEL_CHR!);
              } else {
                context.read<CartProvider>().deliveryCharge = 0;
              }
            }
            context.read<CartProvider>().totalPrice =
                context.read<CartProvider>().totalPrice +
                    context.read<CartProvider>().deliveryCharge;
          }
          if (mounted) {
            setState(
              () {
                _isLoading = false;
              },
            );
          }
          if (mounted) {
            if (context.read<CartProvider>().checkoutState != null) {
              context.read<CartProvider>().checkoutState!(() {});
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {}
    } else {
      if (mounted) {
        setState(
          () {
            isNetworkAvail = false;
          },
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Map<String, dynamic> result =
        await updateOrderStatus(orderID: razorpayOrderId, status: PLACED);
    if (!result['error']) {
      // await addTransaction(
      //     response.paymentId, razorpayOrderId, SUCCESS, rozorpayMsg, true);
      context.read<UserProvider>().setCartCount('0');
      clearAll();
      Routes.navigateToOrderSuccessScreen(context);
    } else {
      setSnackbar('${result['message']}', context);
    }
    if (mounted) {
      context.read<CartProvider>().setProgress(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setSnackbar('somethingMSg'.translate(context: context), context);
    deleteOrder(razorpayOrderId);
    if (mounted) {
      context.read<CartProvider>().checkoutState!(
        () {
          context.read<CartProvider>().placeOrder = true;
        },
      );
    }
    context.read<CartProvider>().setProgress(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _consultarDescuentos(BuildContext context) async {
    // Mostrar mensaje de carga
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Consultando descuentos disponibles para ti...',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface, // 👈 color correcto
                    fontSize: 14,
                  ),
                ),
              ),
           ],
           ),
           );
      },
    );

    try {
      final cartProvider = context.read<CartProvider>();

      // Llamar a la API de descuentos por producto
      await cartProvider.solicitarYAplicarDescuentos(context);

      // Cerrar loader
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        discountApllied = true;
      });

      // Opcional: mostrar confirmación
      final appliedDiscount = cartProvider.cartList.isNotEmpty
          ? cartProvider.cartList.first.descuentoPorcentaje ?? 0.0
          : 0.0;
      ScaffoldMessenger.of(
        Navigator.of(context, rootNavigator: true).context,
      ).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Text(
            'Descuento aplicado: ${(appliedDiscount * 100).toInt()}%',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        Navigator.of(context, rootNavigator: true).context,
      ).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'No se pudieron obtener los descuentos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: widget.fromBottom
            ? getappbarforcart('MY_CART'.translate(context: context), context)
            : getSimpleAppBar('CART'.translate(context: context), context),
        body: isNetworkAvail
            ? Consumer<UserProvider>(builder: (context, data, child) {
                return data.userId != ''
                    ? Stack(
                        children: <Widget>[
                          _showContent(context),
                          Selector<CartProvider, bool>(
                            builder: (context, data, child) {
                              return DesignConfiguration.showCircularProgress(
                                  data, colors.primary);
                            },
                            selector: (_, provider) => provider.isProgress,
                          ),
                        ],
                      )
                    : Stack(
                        children: <Widget>[
                          _showContent1(context),
                          Selector<CartProvider, bool>(
                            builder: (context, data, child) {
                              return DesignConfiguration.showCircularProgress(
                                  data, colors.primary);
                            },
                            selector: (_, provider) => provider.isProgress,
                          ),
                        ],
                      );
              })
            : NoInterNet(
                setStateNoInternate: setStateNoInternate,
                buttonSqueezeanimation: buttonSqueezeanimation,
                buttonController: buttonController,
              ),
      ),
    );
  }
}
