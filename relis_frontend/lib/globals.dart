import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';
import 'dart:math';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:relis/arguments/pagearguments.dart';
import 'package:relis/audioBook/audiobook.dart';
import 'package:relis/authentication/otp.dart';
import 'package:relis/authentication/passwordChange.dart';
import 'package:relis/authentication/services.dart';
import 'package:relis/authentication/signIn.dart';
import 'package:relis/authentication/signUp.dart';
import 'package:relis/authentication/user.dart';
import 'package:relis/bookInfo.dart';
import 'package:relis/profile/profile.dart';
import 'package:relis/profile/showPhoto.dart';
import 'package:relis/view/bookView.dart';
import 'package:relis/view/creditsPage.dart';
import 'package:relis/view/homePage.dart';
import 'package:relis/view/pageView.dart';
import 'package:relis/view/payment.dart';
import 'package:relis/view/searchPage.dart';
import 'package:relis/view/splashScreen.dart';
import 'package:relis/view/statistics.dart';
import 'package:relis/view/translatedBook.dart';
import 'package:relis/view/demoMode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as webFile;

String appTitle = "ReLis - Let the book talk!!!";
var token;
int totalPageReadToday = 0;
var reLis_gif =
    "https://firebasestorage.googleapis.com/v0/b/audiobook-404e3.appspot.com/o/ReLis.gif?alt=media&token=bbcb7a6e-c7c2-4d27-8ced-5ab58d3e177c";
int wrongPassword = 0;
int maxWrongPassword = 3;

enum userTypes { admin, nonAdmin }  

imageLoader(ImageChunkEvent? loadingProgress) {
  return Center(
    child: CircularProgressIndicator(
      value: loadingProgress!.expectedTotalBytes != null
          ? loadingProgress!.cumulativeBytesLoaded /
              loadingProgress!.expectedTotalBytes!
          : null,
      color: mainAppAmber,
    ),
  );
}

dynamic signUpImage, signInImage, relisGif;

ThemeData appTheme = ThemeData(
  primarySwatch: Colors.blue,
  scrollbarTheme: ScrollbarThemeData(
    interactive: true,
    isAlwaysShown: true,
    radius: Radius.circular(10),
    thickness: MaterialStateProperty.all(10.00),
    showTrackOnHover: true,
    thumbColor: MaterialStateProperty.all(Color(0xFF032f4b)),
    trackColor: MaterialStateProperty.all(Color(0x8d032f4b)),
    trackBorderColor: MaterialStateProperty.all(Color(0xFF032f4b)),
    minThumbLength: 10,
  ),
);

var appRoutes = {
  SplashPage.routeName: (BuildContext context) => SplashPage(),
  SignUpPage.routeName: (BuildContext context) => SignUpPage(),
  SignInPage.routeName: (BuildContext context) => SignInPage(),
  OTPPage.routeName: (BuildContext context) => OTPPage(),
  HomePage.routeName: (BuildContext context) => HomePage(),
  BookView.routeName: (BuildContext context) => BookView(),
  TranslatedBook.routeName: (BuildContext context) => TranslatedBook(),
  PageTypeView.routeName: (BuildContext context) => PageTypeView(),
  Profile.routeName: (BuildContext context) => Profile(),
  ShowPhoto.routeName: (BuildContext context) => ShowPhoto(),
  SearchView.routeName: (BuildContext context) => SearchView(),
  PasswordChange.routeName: (BuildContext context) => PasswordChange(),
  CreditsPage.routeName: (BuildContext context) => CreditsPage(),
  PaymentPage.routeName: (BuildContext context) => PaymentPage(),
  DemoMode.routeName: (BuildContext context) => DemoMode(),
  StatisticsPage.routeName: (BuildContext context) => StatisticsPage(),
  AudioBook.routeName: (BuildContext context) => AudioBook()
};

bool changingPassword = false;
String changingEmailID = "";
ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);
bool stopLoading = false;
bool bookViewLoaded = false;

Map<String, int> credits = {
  "dailyLogin": 1,
  "dailyRead": 5,
  "dailyLoginStreak": 30,
  "completeProfile": 10,
  "connectFacebook": 10,
  "connectInstagram": 10,
};

isLoggedIn(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool logOutDecision;
  int diffEpoch = 0;
  String? emailId = prefs.getString("emailId");
  String? password = prefs.getString("password");
  String? sessionOutOnStr = prefs.getString("sessionOutOn") ?? "-";
  print("\t prefs.: Email-id: $emailId");
  print("\t prefs.: Password: $password");
  print("\t prefs.: sessionOutOn: $sessionOutOnStr");
  if (sessionOutOnStr != "-") {
    var sessionOutOn = DateTime.parse(sessionOutOnStr);
    var now = DateTime.now();
    var diff = sessionOutOn.difference(now);
    diffEpoch = diff.inMilliseconds;
  }
  if (diffEpoch <= 0) {
    logOutDecision = true;
    sessionOutOnStr = "-";
    prefs.setString("sessionOutOn", "-");
    loggedIn.value = false;
  } else {
    logOutDecision = false;
    loggedIn.value = true;
  }
  if (!stopLoading) {
    if (!loggedIn.value || logOutDecision) {
      print("\tisLoggedIn: going to log out");
      await logOut(context);
    } else if (loggedIn.value && currentPage != "Home") {
      // changePage("Home");
      print("\tisLoggedIn: going to getLoggedIn");
      await getLoggedIn(context, emailId!, password!, "true",
          sessionOutOnStr: sessionOutOnStr);
    }
  }
}

checkStatus(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? emailId = prefs.getString("emailId");
  String? password = prefs.getString("password");
  String? sessionOutOnStr = prefs.getString("sessionOutOn") ?? "-";
  if (sessionOutOnStr != "-") isLoggedIn(context);
}

achievedDailyLoginReward() {
  String today = "${DateTime.now().day.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().month.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().year}";
  print("....${user!["dailyRecords"]["loginRecords"]}");
  print("....${user!["dailyRecords"]["loginRecords"].length}");
  return (user!["dailyRecords"]["loginRecords"].length > 0
      ? user!["dailyRecords"]["loginRecords"].contains(today)
      : false);
}

int getStreakLength() {
  return user!["dailyRecords"]["streak"]!.length ?? 0;
}

updateCreditsInDB(String today) async {
  await Services()
      .addReward(user!["emailId"], user!["dailyRecords"], user!["credits"])
      .then((val) async {
    if (val != null && val.data['success']) {
    } else {
      // if(achievedDailyLoginReward()) {
      //   user!["dailyRecords"]["loginRecords"].remove(today);
      // }
      showMessageFlutterToast(
        "Error in updating credits!!",
        Color(0xFFFF0000),
      );
    }
  });
}

achievedDailyLoginStreakReward() {
  String today = "${DateTime.now().day.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().month.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().year}";
  if (!user!["dailyRecords"].containsKey("streak")) {
    user!["dailyRecords"]["streak"] = [];
  }
  int streakLength = getStreakLength();
  if (streakLength >= 30) {
    user!["dailyRecords"]["streak"].removeRange(0, 30);
  }
  streakLength = getStreakLength();
  for (int i = getStreakLength();
      i < user!["dailyRecords"]["loginRecords"].length - 1;
      ++i) {
    streakLength = getStreakLength();
    var day1String = user!["dailyRecords"]["loginRecords"][i];
    var day2String = user!["dailyRecords"]["loginRecords"][i + 1];
    DateTime day1 = DateFormat("dd/MM/yyyy").parse(day1String);
    DateTime day2 = DateFormat("dd/MM/yyyy").parse(day2String);
    var diff = day1.difference(day2).inDays.abs();
    if (streakLength <= 0) {
      print("diff is $diff");
      user!["dailyRecords"]["streak"].add(diff);
    } else if (diff > 1) {
      user!["dailyRecords"]["streak"].add(0);
    } else {
      user!["dailyRecords"]["streak"].add(streakLength != 0
          ? user!["dailyRecords"]["streak"][streakLength - 1] + diff
          : diff);
    }
  }
  streakLength = getStreakLength();
  // print(user!["dailyRecords"]["loginRecords"]);
  // print(user!["dailyRecords"]["streak"]);
  if (streakLength != 0 &&
      user!["dailyRecords"]["streak"][streakLength - 1] % 30 == 0) {
    user!["credits"] =
        (int.parse(user!["credits"]) + credits["dailyLoginStreak"]!).toString();
    // await updateCreditsInDB(today);
  }
  return streakLength == 0
      ? false
      : user!["dailyRecords"]["streak"][streakLength - 1] % 30 == 0
          ? true
          : false;
}

getGenreWiseReadBooksStats() {
  num totalPagesRead = 0;
  if (user!.containsKey("booksRead")) {
    print("User have read following books: ");
    print(user!["booksRead"].keys);
    for (var bookId in user!["booksRead"].keys) {
      var key = bookMap[bookId]["category"];
      print("...0-> ${key}");
      print("...0-> ${key.runtimeType}");
      print("...1-> ${category[key]["pagesRead"].runtimeType}");
      print("...2-> ${user!["booksRead"][bookId]["lastPageRead"].runtimeType}");
      print("...3-> ${user!["booksRead"][bookId]["lastPageRead"]}");
      int currentCategoryRead = (category[key]["pagesRead"] ?? 0) +
              user!["booksRead"][bookId]["lastPageRead"] ??
          0;
      category[key]["pagesRead"] = currentCategoryRead;
      print(
          "\t\t ~~~~~ ${category[key]["categoryName"]}: ${category[key]["pagesRead"]}");
    }
    for (var key in category.keys) {
      totalPagesRead = totalPagesRead + (category[key]["pagesRead"] ?? 0);
    }
    for (var key in category.keys) {
      category[key]["pagesRead"] = category[key]["pagesRead"] ?? 0;
      category[key]["totalPagesRead"] = totalPagesRead;
      print(
          "\t\t #### ${category[key]["categoryName"]}: ${category[key]["totalPagesRead"]}");
    }
  }
}

dailyLogin() async {
  String today = "${DateTime.now().day.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().month.toString().padLeft(2, '0')}" +
      "/" +
      "${DateTime.now().year.toString()}";
  if (!achievedDailyLoginReward()) {
    user!["dailyRecords"]["loginRecords"].add(today);
    user!["credits"] =
        (int.parse(user!["credits"]) + credits["dailyLogin"]!).toString();
    await updateCreditsInDB(today);
  }
}

getLoggedIn(
    BuildContext context, String emailId, String password, String redirect,
    {String sessionOutOnStr = "-"}) async {
  print('***** Login Authentication *****');
  await Services().login(emailId, password, redirect).then((val) async {
    print(val.data['userHasToChangePassword']);
    if(val != null && val.data['success']!=null && val.data['user']['isUserBlocked'] != null && val.data['user']['isUserBlocked']) {
      user = val.data['user'];
      showMessageSnackBar(
          context, "Dear ${user!["firstName"]} ${user!["lastName"]}, You are Blocked by Admins!! \nContact ReLis Team to UnBlock your account!!", Color(0xFF00FF88));
    }
    else if (val != null && val.data['success']!=null && val.data['success']) {
      token = val.data['token'];
      user = val.data['user'];
      loggedIn.value = true;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (sessionOutOnStr == "-") {
        sessionOutOnStr = DateTime.now().add(Duration(days: 1)).toString();
      }
      if(redirect == "false") {
        prefs.setString("emailId", user!["emailId"]);
        prefs.setString("password", user!["password"]);
        prefs.setString("sessionOutOn", sessionOutOnStr);
      }
      Fluttertoast.showToast(
        msg: "${user!["firstName"]} ${user!["lastName"]} Logged-In",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color(0xFF00FF00),
        textColor: Colors.white,
        webBgColor: "linear-gradient(to right, #00b09b, #96c93d)",
        fontSize: 16.0,
      );
      showMessageSnackBar(
          context, "Fetching Books, Please Wait!!", Color(0xFF00FF88));
      // Timer fetchBook = Timer.periodic(
      //   Duration(seconds: 4),
      //   (timer) {
      //     showMessageSnackBar(context, "Fetching Books, Please Wait!!", Color(0xFF00FF88));
      //   }
      // );
      // print("fetchBook: ${fetchBook.isActive}");
      if (bookList.length == 0 && !stopLoading) await getBooks(context);
      await getBookRecommendation(context);
      await dailyLogin();
      print('\t Current User: ${user!["firstName"]} ${user!["lastName"]}');
      print('***** Moving to HomePage *****');
      stopLoading = true;
      var date = DateTime.now();
      var dateStr =
          "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year} ";
      print("Currently dateStr: ${dateStr}");
      totalPageReadToday = user!["dailyRecords"]["pagesRead"][dateStr] ?? 0;
      print("Currently totalPageReadToday: ${totalPageReadToday}");
      print("Currently pagesRead: ${user!["dailyRecords"]["pagesRead"]}");
      // fetchBook.cancel();
      while (Navigator.of(context).canPop()) Navigator.of(context).pop();
      Navigator.of(context).pushNamed(HomePage.routeName);
    } else if(val != null && val.data['userHasToChangePassword']) {
      wrongPassword = val.data['wrongPasswordCount'];
      showMessageSnackBar(
        context, "Maximum Wrong Password Attempted. Now Change Password  !!", Color(0xFFFF0000));
    }
    else if(val != null && !val.data['userHasToChangePassword'] && val.data['isWrongPassword']) {
      wrongPassword = val.data['wrongPasswordCount'];
      showMessageSnackBar(
        context, "Wrong Password ${maxWrongPassword-wrongPassword} Attempts Left !!", Color(0xFFFF0000));
      print(val.data['wrongPasswordCount']);
    }
    else {
      print('***** Login Authentication - Error Occurred!! *****');
      stopLoading = false;
      showMessageSnackBar(
          context, "Error Occurred, Log in again!!", Color(0xFFFF0000));
      // await logOut(context);
    }
  });
}

getBookRecommendation(BuildContext context) async {
  await Services().getRecommendBooks().then((val) {
    if (val != null && val.data['success']) {
      if (user?["recommendedBooks"] != null &&
          user?["recommendedBooks"].length > 0)
        showMessageSnackBar(
            context,
            "Loaded Books Recommended for ${user!["firstName"]} ${user!["lastName"]}",
            Color.fromARGB(255, 72, 0, 255));
    } else {
      print("Exiting getBooks else");
      showMessageSnackBar(
          context,
          "Error, Can't recommend books info from db. Please Log in again",
          Color(0xFFFF0000));
      logOut(context);
    }
  });
}

logOut(BuildContext context) async {
  loggedIn.value = false;
  stopLoading = false;
  user = {};
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString("emailId", "");
  prefs.setString("password", "");
  prefs.setString("sessionOutOn", "-");
  // Navigator.of(context).popUntil(ModalRoute.withName(SplashPage.routeName));
  while (Navigator.canPop(context)) Navigator.of(context).pop();
  Navigator.of(context).pushNamed(SignInPage.routeName);
  showMessageSnackBar(context, "Please Log in!!", Color(0xFFFF8800));
}

Color mainAppBlue = Color(0xFF032f4b);
Color mainAppAmber = Color(0xFFdbb018);
Color appBarBackgroundColor = Color(0xFF1E8BC3);
Color appBarShadowColor = Color(0xFF2C3E50);
Color appBackgroundColor = mainAppAmber; // Color(0xFF1A93EF);
Color selectedDrawerTile = Color(0xFF197278);
Color commentBoxColor = Color(0xFF197278);

// Map<String, bool> pages = {
//   "SignIn": true,
//   "SignUp": false,
//   "Home": false,
//   "Genre": false,
//   "Trending": false,
//   "Cart": false,
//   "Favourites": false,
//   "Wish List": false,
//   "History": false,
//   "Bought": false,
//   "Rented": false,
//   "Demo": false,
//   "Statistic": false,
// };

Map<String, String> Registeration = {};
// Map<String, dynamic> rentCart = {};
// List<String> buyCart = [];

String currentPage = "SignIn";

void showMessageFlutterToast(String message, Color backgroundColor,
    {bool showClose = false}) {
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: backgroundColor,
    // webBgColor: "linear-gradient(to right, #${backgroundColor.red}${backgroundColor.blue}${backgroundColor.green}, #96c93d)",
    webBgColor:
        "linear(#${backgroundColor.red}${backgroundColor.blue}${backgroundColor.green})",
    gravity: ToastGravity.BOTTOM,
    toastLength: Toast.LENGTH_SHORT,
    webShowClose: showClose,
  );
}

void showMessageSnackBar(
    BuildContext context, String message, Color backgroundColor,
    {double snackBarWidth = 0}) {
  // snackBarWidth = snackBarWidth == 0 ? MediaQuery.of(context).size.width : snackBarWidth;
  final snackBar = new SnackBar(
    content: new Text('$message'),
    backgroundColor: backgroundColor,
    // behavior: SnackBarBehavior.floating,
    // width: snackBarWidth,
  );
  // ignore: deprecated_member_use
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// void changePage(String newPage) {
//   pages[currentPage] = false;
//   currentPage = newPage;
//   pages[currentPage] = true;
// }

// bool isPageOpened(String pageName) {
//   return pages[pageName]!;
// }

BoxDecoration boxDecoration = BoxDecoration(
  color: Colors.tealAccent,
  boxShadow: [
    BoxShadow(
      color: Color(0xFF1E824C),
      offset: const Offset(
        0.0,
        5.0,
      ),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
    BoxShadow(
      color: Colors.black,
      offset: const Offset(0.0, 5.0),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
  ],
  borderRadius: BorderRadius.circular(25.00),
  border: Border.all(color: Colors.teal, width: 2),
);
BoxDecoration innerBoxDecoration = BoxDecoration(
  color: Colors.tealAccent.withOpacity(0.6),
  borderRadius: BorderRadius.vertical(
      top: Radius.circular(20.00), bottom: Radius.circular(25.00)),
  border: Border.all(color: Colors.teal.withOpacity(0.4), width: 2),
);
BoxDecoration categoryDecoration = BoxDecoration(
  color: Color(0xFF032f4b),
  boxShadow: [
    BoxShadow(
      color: Color(0xFF1E824C),
      offset: const Offset(
        0.0,
        5.0,
      ),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
    BoxShadow(
      color: Colors.black,
      offset: const Offset(0.0, 5.0),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
  ],
  borderRadius: BorderRadius.circular(25.00),
  border: Border.all(color: Colors.teal, width: 2),
);
BoxDecoration commentBoxDecoration = BoxDecoration(
  color: Color(0xFF032f4b),
  boxShadow: [
    BoxShadow(
      color: Color(0xFF1E824C),
      offset: const Offset(
        0.0,
        5.0,
      ),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
    BoxShadow(
      color: Colors.black,
      offset: const Offset(0.0, 5.0),
      blurRadius: 10.0,
      spreadRadius: 1.5,
    ),
  ],
  borderRadius: BorderRadius.circular(25.00),
  border: Border.all(color: Colors.teal, width: 2),
);

// bool hover = false;
Map<String, ValueNotifier<bool>> favourite = {};
Map<String, ValueNotifier<bool>> wishList = {};
Map<String, ValueNotifier<bool>> recommendationHover = {};
Map<String, ValueNotifier<bool>> historyHover = {};
Map<String, ValueNotifier<bool>> favouriteHover = {};
Map<String, ValueNotifier<bool>> cartHover = {};
Map<String, ValueNotifier<bool>> trendingHover = {};
Map<String, ValueNotifier<bool>> categoryHover = {};
Map<String, ValueNotifier<bool>> categoryBookHover = {};
Map<String, ValueNotifier<bool>> wishListHover = {};
Map<String, ValueNotifier<bool>> boughtHover = {};
Map<String, ValueNotifier<bool>> rentedHover = {};
Map<String, ValueNotifier<bool>> toBuyHover = {};
Map<String, ValueNotifier<bool>> toRentHover = {};
Map<String, ValueNotifier<bool>> personalBooksHover = {};
Map<String, ValueNotifier<bool>> adminBookHover = {};
Map<String, bool> visible = {
  "recommendation": true,
  "trending": true,
  "categories": true,
  "history": true,
  "stats1": true,
  "stats2": true,
};
int bookListLength = bookMap.length;
int categoryListLength = category.length;
ScrollController recommendationController = new ScrollController();
ScrollController scrollController = new ScrollController();
ScrollController trendingController = new ScrollController();
ScrollController historyController = new ScrollController();
CarouselController carouselController = CarouselController();

enum pageType {
  none,
  category,
  trending,
  favourite,
  wishList,
  cart,
  history,
  bought,
  rented,
  personalBooks,
  adminBookView,
  recommendation,
}

gotToRoute(BuildContext context, pageType type) {
  switch (type) {
    case pageType.category:
      {
        // changePage("Genre");
        return Navigator.of(context).popAndPushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.category,
          ),
        );
      }
      break;
    case pageType.trending:
      {
        // changePage("Trending");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.trending,
          ),
        );
      }
      break;
    case pageType.cart:
      {
        // changePage("Cart");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.cart,
          ),
        );
      }
      break;
    case pageType.favourite:
      {
        // changePage("Favourites");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.favourite,
          ),
        );
      }
      break;
    case pageType.wishList:
      {
        // changePage("Wish List");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.wishList,
          ),
        );
      }
      break;
    case pageType.history:
      {
        // changePage("History");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.history,
          ),
        );
      }
      break;
    case pageType.bought:
      {
        // changePage("Bought");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.bought,
          ),
        );
      }
      break;
    case pageType.rented:
      {
        // changePage("Rented");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.rented,
          ),
        );
      }
      break;
    case pageType.personalBooks:
      {
        // changePage("Trending");
        return Navigator.of(context).pushNamed(
          PageTypeView.routeName,
          arguments: PageArguments(
            pageType.personalBooks,
          ),
        );
      }
      break;
    case pageType.none:
    default:
      {
        // changePage("Home");
        return Navigator.of(context).pushNamed(HomePage.routeName);
      }
      break;
  }
}

String pageName(pageType type) {
  switch (type) {
    case pageType.category:
      return "in this Genre";
    case pageType.trending:
      return "in Trending";
    case pageType.favourite:
      return "in Favourites";
    case pageType.wishList:
      return "in WishList";
    case pageType.history:
      return "in History";
    case pageType.bought:
      return "Bought";
    case pageType.rented:
      return "Rented";
    case pageType.personalBooks:
      return "in your Personal Library";
    case pageType.none:
    default:
      return "";
  }
}

getBooks(BuildContext context) async {
  await createPagesReadMap();
  await Services().getAllBooks(user!["emailId"]).then((val) {
    if (val != null && val.data['success']) {
      bookList = val.data["books"];
      print("Exiting getBooks if");
    } else {
      print("Exiting getBooks else");
      showMessageSnackBar(
          context,
          "Error, Can't fetch books info from db. Please Log in again",
          Color(0xFFFF0000));
      logOut(context);
    }
  });
  int i = 0;
  // bookList = bookList[0];
  // print("bookList... ${bookList}");
  for (var currentBook in bookList) {
    currentBook["image"] = await getBookImage(currentBook["id"]);
    if(currentBook["isBookBlocked"] != null && currentBook["isBookBlocked"] == true) {
      blockedBooks.add(currentBook["id"]);
    }
    ++i;
    showMessageFlutterToast(
      " ${i} / ${bookList.length} Book Loaded",
      Color(0xFF00FF00),
      showClose: true,
    );
  }
  print("Exited getBooks");
}

getBookImage(String bookId) async {
  // print("In getBookImage - ");
  // print("Book is "+bookId);
  Dio dio = new Dio();
  Response response = await dio.post(
    // "http://localhost:3000/getBookImage"
    "https://relis-nodejs1.herokuapp.com/getBookImage",
    data: {"emailId": user!["emailId"], "bookId": bookId},
  );
  if (response.data['success']) {
    var imageListDynamic = response.data["imagePng"]["data"]["data"];
    var imageList = imageListDynamic.cast<int>();
    var imageData = imageList;
    return Image.memory(
      Uint8List.fromList(imageData),
      fit: BoxFit.fill,
      width: double.infinity,
      repeat: ImageRepeat.noRepeat,
    );
  }
}

getImage(String imageType) async {
  print("In getImage - $imageType");
  Dio dio = new Dio();
  Response response = await dio.post(
    // "http://localhost:3000/getImage",
    "https://relis-nodejs1.herokuapp.com/getImage",
    data: {"imageType": imageType},
  );
  if (response.data['success']) {
    var imageListDynamic = response.data["imagePng"]["data"]["data"];
    var imageList = imageListDynamic.cast<int>();
    var imageData = imageList;
    print("Out getImage - $imageType");
    return Image.memory(
      Uint8List.fromList(imageData),
      fit: BoxFit.fill,
      width: double.infinity,
      repeat: ImageRepeat.noRepeat,
    );
  }
}

isBookBlocked(String bookId) {
  if (blockedBooks.contains(bookId))
    return true;
  return false;
}

isBookBought(String bookId) {
  if (user!["booksBought"].containsKey(bookId)) return true;
  return false;
}

isBookRented(String bookId) {
  if (user!["booksRented"].containsKey(bookId)) {
    var dueDate = DateTime.parse(user!["booksRented"][bookId]["dueOn"]);
    var daysLeft = dueDate.difference(DateTime.now()).inMilliseconds;
    print("\t dueDate: ${dueDate}");
    print("\t now: ${DateTime.now()}");
    print("\t\t daysLeft: ${daysLeft}");
    if (daysLeft <= 0) {
      return false;
    } else {
      return true;
    }
  }
  return false;
}

var bookList = [];
var blockedBooks = [];

Map<String, dynamic> bookMap = {};

Map<String, dynamic> categoryOther = {
  "id": "ct-000",
  "categoryName": "Other",
  "categoryColor": Color(0xFFFF0000),
  "bookList": null,
};
Map<String, dynamic> categoryNovel = {
  "id": "ct-001",
  "categoryName": "Novel",
  "categoryColor": Colors.lightGreen,
  "bookList": null,
};
Map<String, dynamic> categoryThriller = {
  "id": "ct-002",
  "categoryName": "Thriller",
  "bookList": null,
  "categoryColor": Colors.grey,
};
Map<String, dynamic> categoryFictional = {
  "id": "ct-003",
  "categoryName": "Fictional",
  "categoryColor": Color(0xff845bef),
  "bookList": null,
};
Map<String, dynamic> categorySciFic = {
  "id": "ct-004",
  "categoryName": "Sci-Fic",
  "categoryColor": Colors.lightBlue,
  "bookList": null,
};
Map<String, dynamic> categoryHistorical = {
  "id": "ct-005",
  "categoryName": "Historical",
  "categoryColor": Colors.orange,
  "bookList": null,
};
Map<String, dynamic> categoryPoetry = {
  "id": "ct-006",
  "categoryName": "Poetry",
  "categoryColor": Colors.teal,
  "bookList": null,
};
Map<String, dynamic> categoryRomance = {
  "id": "ct-007",
  "categoryName": "Romance",
  "categoryColor": Colors.pink,
  "bookList": null,
};
Map<String, dynamic> categoryAction = {
  "id": "ct-008",
  "categoryName": "Action",
  "categoryColor": Colors.lime,
  "bookList": null,
};
Map<String, dynamic> categoryHorror = {
  "id": "ct-009",
  "categoryName": "Horror",
  "categoryColor": Colors.brown,
  "bookList": null,
};
var categoryList = [
  categoryOther,
  categoryNovel,
  categoryThriller,
  categoryFictional,
  categorySciFic,
  categoryHistorical,
  categoryPoetry,
  categoryRomance,
  categoryAction,
  categoryHorror
];
Map<String, dynamic> category = {};

void addItem(Map<String, dynamic> map, var list) {
  // print("\n\n\n\n\n");
  // print("list: $list");
  // print("\n\n\n\n\n");
  for (var ls in list) {
    map[ls["id"]] = ls;
  }
}

void loadBooksInCategory() {
  for (var bookId in bookMap.keys) {
    var catId = bookMap[bookId]["category"];
    if (category[catId]["bookList"] == null) {
      category[catId]["bookList"] = [];
    }
    category[catId]["bookList"].add(bookId);
  }
}

void loadEachHover() {
  loadHoverMap(category, categoryHover);
  loadHover(
      user?["recommendedBooks"] == null ? 0 : user?["recommendedBooks"].length,
      user?["recommendedBooks"],
      recommendationHover,
      "recommendedBooks");
  loadHover(bookInfo["trendingBook"].length, bookInfo["trendingBook"],
      trendingHover, "trendingBook");
  loadHover(user?["favouriteBook"].length, user?["favouriteBook"],
      favouriteHover, "favouriteBook");
  loadHover(user?["cart"]["toRent"].length, user?["cart"]["toRent"], cartHover,
      "cart");
  loadHover(
      user?["cart"]["toBuy"].length, user?["cart"]["toBuy"], cartHover, "cart");
  loadHover(user?["wishListBook"].length, user?["wishListBook"], wishListHover,
      "wishListBook");
  loadHover(user?["bookHistory"].length, user?["bookHistory"], historyHover,
      "bookHistory");
  loadHoverMap(
    user?["booksBought"],
    boughtHover,
  );
  loadHoverMap(
    user?["booksRented"],
    rentedHover,
  );
  loadHover(user?["personalBooks"].length, user?["personalBooks"],
      personalBooksHover, "personalBooks");
}

void loadData() {
  addItem(bookMap, bookList);
  addItem(category, categoryList);
  loadBooksInCategory();
  bookMap.forEach((key, value) {
    favourite[key] = ValueNotifier<bool>(false);
    wishList[key] = ValueNotifier<bool>(false);
  });
  loadEachHover();
}

void loadValues(Map<String, dynamic> user, var currentBook) {
  favourite[currentBook["id"]]!.value = isFavourite(user, currentBook["id"]);
  wishList[currentBook["id"]]!.value = isWishList(user, currentBook["id"]);
}

void loadHoverMap(var data, var hover) {
  if (data != null && data.length > 0)
    for (var cat in data.values) {
      hover[cat["id"]!] = ValueNotifier<bool>(false);
    }
}

loadCategoryBooks(var bookList, var hover) {
  for (var id in bookList) {
    print("${id} is Category Hover.....");
    hover[id] = ValueNotifier<bool>(false);
    print("\t${id}Category Hover: ${hover[id]}");
  }
  return hover;
}

void loadHover(var length, var data, var hover, var type) {
  // print("type: $type");
  // print("\n\n length: $length");
  // print("data: $data");
  for (int i = 0; i < length; ++i) {
    hover[data[i]] = ValueNotifier<bool>(false);
  }
  // print("$type: ${hover!.length}");
}

void favouriteBook(
    BuildContext context, Map<String, dynamic> user, var currentBook) {
  print("IN favouriteBook");
  if (isFavourite(user, currentBook["id"])) {
    Services()
        .removeFromFavourites(user["emailId"], currentBook["id"])
        .then((val) {
      if (val != null && val.data['success']) {
        favouriteHover.remove(currentBook["id"]);
        favourite[currentBook["id"]] = ValueNotifier<bool>(false);
        user["favouriteBook"] = val.data["favouriteBook"];
      } else {
        showMessageSnackBar(
            context, "Error, Can't remove From favourites", Color(0xFFFF0000));
      }
    });
  } else {
    Services().addToFavourites(user["emailId"], currentBook["id"]).then((val) {
      if (val != null && val.data['success']) {
        favouriteHover[currentBook["id"]] = ValueNotifier<bool>(false);
        favourite[currentBook["id"]] = ValueNotifier<bool>(true);
        user["favouriteBook"] = val.data["favouriteBook"];
      } else {
        showMessageSnackBar(
            context, "Error, Can't add to favourites", Color(0xFFFF0000));
      }
    });
  }
  // favourite[currentBook["id"]]!.value = !favourite[currentBook["id"]]!.value;
  // for(int i=0; i<favouriteHover.length; ++i)
  // hover = true;
  print("\t ... ${favouriteHover}");
  print("OUT favouriteBook");
}

void wishListBook(
    BuildContext context, Map<String, dynamic> user, var currentBook) {
  print("IN wishListBook");
  if (isWishList(user, currentBook["id"])) {
    Services()
        .removeFromWishList(user["emailId"], currentBook["id"])
        .then((val) {
      if (val != null && val.data['success']) {
        wishListHover.remove(currentBook["id"]);
        user["wishListBook"] = val.data["wishListBook"];
      } else {
        showMessageSnackBar(
            context, "Error, Can't remove From wishList", Color(0xFFFF0000));
      }
    });
  } else {
    Services().addToWishList(user["emailId"], currentBook["id"]).then((val) {
      if (val != null && val.data['success']) {
        wishListHover[currentBook["id"]] = ValueNotifier<bool>(false);
        user["wishListBook"] = val.data["wishListBook"];
      } else {
        showMessageSnackBar(
            context, "Error, Can't add to wishList", Color(0xFFFF0000));
      }
    });
  }
  wishList[currentBook["id"]]!.value = !wishList[currentBook["id"]]!.value;
  print("OUT wishListBook");
}

void addToHistory(
    BuildContext context, Map<String, dynamic> user, var currentBook) {
  var historyList = new Queue();
  if (user.containsKey("bookHistory") && user?["bookHistory"].length > 0)
    historyList.addAll(user?["bookHistory"].toList());
  if (isHistory(user, currentBook)) {
    historyList.remove(currentBook["id"]);
  }
  historyList.addFirst(currentBook["id"]);
  user?["bookHistory"] = historyList.toList();
  loadHover(user?["bookHistory"].length, user?["bookHistory"], historyHover,
      "bookHistory");
  changeHistory(context);
}

void removeFromHistory(
    BuildContext context, Map<String, dynamic> user, var currentBook) {
  var historyList = new Queue();
  if (user.containsKey("bookHistory") && user?["bookHistory"].length > 0)
    historyList.addAll(user?["bookHistory"].toList());
  if (isHistory(user, currentBook)) {
    historyList.remove(currentBook["id"]);
  }
  user?["bookHistory"] = historyList.toList();
  loadHover(user?["bookHistory"].length, user?["bookHistory"], historyHover,
      "bookHistory");
  changeHistory(context);
}

changeHistory(BuildContext context) async {
  await Services()
      .changeHistory(user!["emailId"], user?["bookHistory"])
      .then((val) {
    if (val != null && val.data['success']) {
    } else {
      showMessageSnackBar(
          context,
          "Error, Can't fetch books info from db. Please Log in again",
          Color(0xFFFF0000));
      logOut(context);
    }
  });
}

bool isFavourite(Map<String, dynamic> user, String bookId) {
  var favList = user["favouriteBook"].toList();
  if (favList.contains(bookId)) {
    return true;
  }
  return false;
}

bool isWishList(Map<String, dynamic> user, String bookId) {
  var wishList = user["wishListBook"].toList();
  if (wishList.contains(bookId)) {
    return true;
  }
  return false;
}

bool isHistory(Map<String, dynamic> user, var currentBook) {
  var wishList = [];
  if (user.containsKey("bookHistory") && user?["bookHistory"].length > 0)
    wishList = user?["bookHistory"].toList();
  if (wishList.contains(currentBook["id"])) {
    return true;
  }
  return false;
}

String getCategoryName(String categoryId) {
  if (category.containsKey(categoryId))
    return category[categoryId]["categoryName"];
  return "-";
}

dynamic getBooksList(var bookList, {bool isList = false}) {
  print("${bookList.runtimeType}");
  if (bookList == null || bookList.length == 0) {
    return null;
  }
  var bookData = new Queue();
  for (var id in bookList) {
    if (bookMap.keys.contains(id)) bookData.addLast(bookMap[id]);
  }
  if (bookData.length == 0) {
    return null;
  }
  return bookData.toList();
}

Map<String, dynamic> getBooksMap(var bookList, {bool isList = false}) {
  // print("${bookList.runtimeType}");
  if (bookList == null || bookList.length == 0) {
    return {};
  }
  Map<String, dynamic> bookData = {};
  for (var id in bookList) {
    if (bookMap.keys.contains(id)) bookData[id] = bookMap[id];
  }
  if (bookData.length == 0) {
    return {};
  }
  return bookData;
}

void makeAllHoverOff() {
  for (var favBook in favouriteHover.values) {
    favBook.value = false;
  }
}

bool cameraSource(BuildContext context) {
  if (MediaQuery.of(context).size.width <= 700) {
    return false;
  }
  return true;
}

Future<void> uploadImage(BuildContext context, File photo) async {
  String fileName = photo.path.split('/').last;
  String extension = fileName.split('.').last;
  // var map = {
  //   'name': fileName,
  //   'photo': await MultipartFile.fromFile(
  //     photo.path,
  //     filename: fileName,
  //     // contentType: new MediaType("image", extension),
  //   ),
  // };
  // FormData formData = new FormData.fromMap(map,);
  // var response = await dio.put(
  //     uploadUserProfilePhotoURL,
  //     data: formData,
  //     options: Options(headers: {"token": widget.jwt_token}));
  // if(response.data['success'])
  // {
  //   await getUserProfile(widget.u_id, widget.jwt_token);
  // }
}

Future<void> chooseImage(BuildContext context, bool imageSource) async {
  // File _image;
  dynamic _image;
  final pickedFile = await ImagePicker().pickImage(
      source: imageSource ? ImageSource.camera : ImageSource.gallery);
  if (pickedFile != null) {
    _image = File(pickedFile.path);
    uploadImage(context, _image);
  } else {
    _image = null;
  }
}

uploadFileData(BuildContext context, File file) async {
  String fileName = file.path.split('/').last;
  String extension = fileName.split('.').last;
  print("Received file: ${fileName}.${extension}");
  var bookData = file.readAsBytesSync();
  print("bookData Length: ");
  print(bookData.length);
  return bookData;
  // var map = {
  //   'name': fileName,
  //   'photo': await MultipartFile.fromFile(
  //     photo.path,
  //     filename: fileName,
  //     // contentType: new MediaType("image", extension),
  //   ),
  // };
  // FormData formData = new FormData.fromMap(map,);
  // var response = await dio.put(
  //     uploadUserProfilePhotoURL,
  //     data: formData,
  //     options: Options(headers: {"token": widget.jwt_token}));
  // if(response.data['success'])
  // {
  //   await getUserProfile(widget.u_id, widget.jwt_token);
  // }
}

chooseFile(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    // print("result: ");
    // print(result);
    PlatformFile file = result.files.first;
    print("fileName: ${file.name} - ${file.bytes!.length}");
    // File file = File(result.files.single.path!);
    return file.bytes; // await uploadFileData(context, );
  } else {
    // User canceled the picker
    print('Please Choose a File');
  }
}

// void printHover(var bookHover) {
//   print("bookHover: ${bookHover}");
//   for(var key in bookHover.keys)
//     print("\t ${key}: ${bookHover[key]}");
// }

String loadBookTooltip(String id) {
  if (!(isRented(id) || isPurchased(id)))
    return "Not yet Purchased or Rented!!";
  String userBookDetails = "";
  if (isRented(id))
    userBookDetails =
        "Rented on: ${user?["booksRented"][id]["rentedOn"]}\n\nDue on: ${user?["booksRented"][id]["dueOn"]}";
  if (isRented(id) && isPurchased(id)) userBookDetails += "\n";
  if (isPurchased(id))
    userBookDetails +=
        "Purchased on: ${user?["booksBought"][id]["purchasedOn"]}";
  return userBookDetails;
}

isRented(String id) {
  return user?["booksRented"]!.keys.contains(id);
}

isPurchased(String id) {
  return user?["booksBought"]!.keys.contains(id);
}

addCartToDb() async {
  print("...Reached Here - 0");
  dynamic cartTemp = {};
  dynamic booksBoughtTemp = {};
  dynamic booksRentedTemp = {};
  if (user!.containsKey("cart") && user!["cart"].length > 0) {
    print("cart: ${user!["cart"]}");
    cartTemp = new Map<dynamic, dynamic>.from(user!["cart"]);
  }
  print("...Reached Here - 1");
  if (user!.containsKey("booksBought") && user!["booksBought"].length > 0) {
    print("booksBought: ${user!["booksBought"]}");
    booksBoughtTemp = new Map<dynamic, dynamic>.from(user!["booksBought"]);
  }
  print("...Reached Here - 2");
  if (user!.containsKey("booksRented") && user!["booksRented"].length > 0) {
    print("booksRented: ${user!["booksRented"]}");
    booksRentedTemp = new Map<dynamic, dynamic>.from(user!["booksRented"]);
  }
  print("...Reached Here - 3");
  var now = DateTime.now();
  print("...Reached here - 4");
  // Emptying Cart and adding books in booksBought and booksRented
  for (var bookId in user!["cart"]["toBuy"]) {
    user!["booksBought"]
        [bookId] = {"id": bookId, "purchasedOn": now.toString()};
    user!["cart"]["toBuy"].remove(bookId);
  }
  for (var bookId in user!["cart"]["toRent"]) {
    var due = isBookRented(bookId)
        ? DateTime.parse(user!["booksRented"][bookId]["dueOn"])
            .add(Duration(days: 7))
        : DateTime.now().add(Duration(days: 7));
    user!["booksRented"][bookId] = {
      "id": bookId,
      "rentedOn": now.toString(),
      "dueOn": due.toString(),
    };
    user!["cart"]["toRent"].remove(bookId);
  }
  print("...Reached here - 5");
  await Services()
      .buyBooks(user!["emailId"], user!["cart"], user!["booksBought"],
          user!["booksRented"])
      .then((val) {
    if (val != null && val.data['success']) {
      print("...Reached here - 6");
      showMessageFlutterToast(
        "Books Bought Successfully!!",
        Colors.green,
      );
    } else {
      print("...Reached here - 7");
      user!["cart"] = cartTemp;
      user!["booksBought"] = booksBoughtTemp;
      user!["booksRented"] = booksRentedTemp;
      showMessageFlutterToast(
        "Books Bought Failed!!",
        Colors.red,
      );
    }
  });
}

addToCart(BuildContext context, String bookId, String bookName,
    {bool isRent = false}) async {
  if (user!["cart"]["toRent"].contains(bookId) ||
      user!["cart"]["toBuy"].contains(bookId)) {
    showMessageFlutterToast(
      "$bookName already in cart!!",
      Color(0xFFFF0000),
    );
    return;
  } else if (isRent) {
    // if(user!["cart"]["toRent"].length > 0)
    //   rentCart.addAll(user!["cart"]["toRent"]);
    user!["cart"]["toRent"].add(bookId);
    // rentCart[bookId] = {
    //   "bookId" : bookId,
    //   "buyDate" : DateTime.now(),
    //   "dueDate" : DateTime.now().add(Duration(days: 7)),
    // };
    // user!["cart"]["toRent"] = rentCart;
  } else {
    user!["cart"]["toBuy"].add(bookId);
    // buyCart.add(bookId);
  }
  await Services()
      .updateCart(user!["emailId"], user!["cart"])
      .then((val) async {
    if (val != null && val.data['success']) {
      showMessageFlutterToast(
        "$bookName added to your cart!!",
        Colors.green,
      );
    } else {
      if (user!["cart"]["toRent"].contains(bookId)) {
        user!["cart"]["toRent"].remove(bookId);
      } else if (user!["cart"]["toBuy"].contains(bookId)) {
        user!["cart"]["toBuy"].remove(bookId);
      }
      showMessageFlutterToast(
        "Error in adding $bookName to your cart!!",
        Color(0xFFFF0000),
      );
    }
  });
  // for(var bk in user!["cart"]["toRent"]) {
  //   print("\t Book in rentCart: ${bk}");
  // }
  // for(var bk in user!["cart"]["toBuy"]) {
  //   print("\t Book in buyCart: ${bk}");
  // }
}

removeFromCart(BuildContext context, String bookId, String bookName) async {
  if (user!["cart"]["toRent"].contains(bookId)) {
    user!["cart"]["toRent"].remove(bookId);
  } else if (user!["cart"]["toBuy"].contains(bookId)) {
    user!["cart"]["toBuy"].remove(bookId);
  }
  await Services()
      .updateCart(user!["emailId"], user!["cart"])
      .then((val) async {
    if (val != null && val.data['success']) {
      showMessageFlutterToast(
        "$bookName removed from your cart!!",
        Colors.green,
      );
    } else {
      showMessageFlutterToast(
        "Error in removing $bookName from your cart!!",
        Color(0xFFFF0000),
      );
    }
  });
}

createPagesReadMap() async {
  Map<String, int> pagesRead = {};
  var temp2 = user!["dailyRecords"];
  for (int i = 6; i >= 0; --i) {
    var date = DateTime.now().subtract(Duration(days: i));
    pagesRead[
        "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}"] = 0;
  }
  for (var keys in pagesRead.keys) {
    pagesRead[keys] = user!["dailyRecords"]["pagesRead"][keys] ?? 0;
  }
  user!["dailyRecords"]["pagesRead"] = pagesRead;
  await Services()
      .changeDailyRecords(user!["emailId"], user!["dailyRecords"])
      .then((val) async {
    if (val != null && val.data['success']) {
    } else {
      user!["dailyRecords"] = temp2;
      showMessageFlutterToast(
        "Error in updating dailyRecords...",
        Color(0xFFFF0000),
      );
    }
  });
}

changeLastPageRead(String bookId, int lastPageRead) async {
  var temp1 = user!["booksRead"];
  var temp2 = user!["dailyRecords"];
  var currMap = {
    "id": bookId,
    "lastReadAt": DateTime.now().toString(),
    "lastPageRead": lastPageRead,
  };
  if (!user!.containsKey("booksRead")) {
    user!["booksRead"] = {};
  }
  user!["booksRead"][bookId] = currMap;
  var date = DateTime.now(); // weeks[(today-i-1)%7] + "\n" +
  var dateStr =
      "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}";
  for (var key in user!["dailyRecords"]["pagesRead"].keys) {
    // print("1: ${key==dateStr}");
    // print("2: ${identical(key,dateStr)}");
    // print("2: ${key.compareTo(dateStr)}");
    if (key == dateStr)
      user!["dailyRecords"]["pagesRead"][dateStr] += totalPageReadToday;
  }
  print("Now pagesRead:");
  print(user!["dailyRecords"]["pagesRead"]);
  await Services()
      .changeLastPageRead(
          user!["emailId"], user!["booksRead"], user!["dailyRecords"])
      .then((val) async {
    if (val != null && val.data['success']) {
      print("......pdfViewer dispose 2 ${user!["booksRead"]}");
    } else {
      print("......pdfViewer dispose 2 3 ${user!["booksRead"]}");
      user!["booksRead"] = temp1;
      user!["dailyRecords"] = temp2;
      showMessageFlutterToast(
        "Error in updating last page read...",
        Color(0xFFFF0000),
      );
    }
  });
}

Widget customDivider() {
  return Column(
    children: [
      Container(
        color: Color(0xFF032f4b),
        height: 5,
      ),
      Container(
        color: Colors.transparent,
        height: 2,
      ),
      Container(
        color: Color(0xFF032f4b),
        height: 5,
      ),
    ],
  );
}

sendFeedback(BuildContext context, String bookId, var newCommentInfo,
    var currentBook) async {
  await Services()
      .addFeedback(user!["emailId"], bookId, newCommentInfo["comment"],
          newCommentInfo["rating"])
      .then((val) async {
    if (val != null && val.data['success']) {
      print("Feedback: ");
      print(val.data['feedback']);
      currentBook["feedback"] = val.data['feedback'];
      showMessageFlutterToast(
        "Feedback added!!",
        Colors.green,
      );
      print("Out of sendFeedback");
    } else {
      showMessageFlutterToast(
        "Error in adding Feedback!!",
        Color(0xFFFF0000),
      );
    }
    return currentBook;
  });
  // for(var bk in user!["cart"]["toRent"]) {
  //   print("\t Book in rentCart: ${bk}");
  // }
  // for(var bk in user!["cart"]["toBuy"]) {
  //   print("\t Book in buyCart: ${bk}");
  // }
}

addPersonalBooks(BuildContext context, var newBook) async {
  print("... in Globals addPersonalBooks");
  await Services()
      .addPersonalBooks(user!["emailId"], newBook)
      .then((val) async {
    if (val != null && val.data['success']) {
      bookList.add(newBook);
      user?["personalBooks"].addLast(newBook["id"]);
      showMessageFlutterToast(
        "New Book added!!",
        Colors.green,
      );
    } else {
      showMessageFlutterToast(
        "Error in adding new book!!",
        Color(0xFFFF0000),
      );
    }
  });
  // for(var bk in user!["cart"]["toRent"]) {
  //   print("\t Book in rentCart: ${bk}");
  // }
  // for(var bk in user!["cart"]["toBuy"]) {
  //   print("\t Book in buyCart: ${bk}");
  // }
}

getUserDetails(String emailId, String userId) async {
  try {
    print("In getUserDetails");
    var val = await Services().getUserDetails(emailId, userId);
    print("val.data['success']: ");
    print(val.data['success']);
    if (val.data['success']) {
      print("in if of getUserDetails");
      var feedUser = val.data["userDetails"];
      return feedUser;
    } else {
      print("in else of getUserDetails");
      return [];
    }
  } catch (error) {
    print("getAudioBook Error: $error");
    return [];
  }
}

getBookFile(String bookId) async {
  try {
    print("In getBookFile");
    var val = await Services().getBookFile(user!["emailId"], bookId);
    print("val.data['success']: ");
    print(val.data['success']);
    if (val.data['success']) {
      print("in if of getBookFile");
      var bookListDynamic = val.data["bookFile"]["data"]["data"];
      var bookBufferList = bookListDynamic.cast<int>();
      var bookData = Uint8List.fromList(bookBufferList);
      return bookData;
    } else {
      print("in else of getBookFile");
      return [];
    }
  } catch (error) {
    print("getBookFile Error: $error");
    return [];
  }
}

getAudioBook(String bookId) async {
  try {
    print("In getAudioBook File");
    var val = await Services().getAudioBook(user!["emailId"], bookId);
    print("val.data['success']: ");
    print(val.data['success']);
    if (val.data['success']) {
      print("in if of getAudioBook");
      var audioBooksList = val.data["audioBooks"];
      return audioBooksList;
    } else {
      print("in else of getAudioBook");
      return [];
    }
  } catch (error) {
    print("getAudioBook Error: $error");
    return [];
  }
}

getAudioBookFile(String bookId, String audioId) async {
  try {
    print("In getAudioBookFile");
    var val =
        await Services().getAudioBookFile(user!["emailId"], bookId, audioId);
    print("val.data['success']: ");
    print(val.data['success']);
    if (val.data['success']) {
      print("in if of getAudioBookFile");
      var audioBookFileListDynamic = val.data["audioFile"]["data"]["data"];
      var audioBookFileList = audioBookFileListDynamic.cast<int>();
      var audioBookFileData = Uint8List.fromList(audioBookFileList);
      // print("\t\t...$bookId/$audioId.mp3");
      // var audioFile = webFile.File(audioBookFileData, "$bookId/$audioId.mp3",);
      // print("relativePath: ${audioFile.relativePath}");
      return audioBookFileData;
    } else {
      print("in else of getAudioBookFile");
      return [];
    }
  } catch (error) {
    print("getAudioBookFile Error: $error");
    return [];
  }
}

String getDuration(String seconds) {
  Duration duration = new Duration(seconds: int.parse(seconds));
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return duration.inHours == 0
      ? "$twoDigitMinutes:$twoDigitSeconds"
      : "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}