import 'dart:async';
import 'dart:io';
// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:native_pdf_view/native_pdf_view.dart';
import 'package:relis/authentication/services.dart';
import 'package:relis/authentication/user.dart';
import 'package:relis/globals.dart';
import 'dart:html' as webFile;

class PDFViewer extends StatefulWidget {
  String? url;
  String? path;
  String? bookId;
  dynamic? fileData;

  PDFViewer({
    this.url,
    this.path,
    this.bookId,
    this.fileData,
  });

  @override
  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  static int _initialPage = 1;
  int _actualPageNumber = _initialPage, _allPagesCount = 0;
  bool isSampleDoc = true;
  int _lastPageRead = _initialPage;
  double viewportFraction = 2.0;
  var file;
  PdfController _pdfController = PdfController(
    document: PdfDocument.openAsset('ReLis.gif'),
  );

  @override
  void initState() {
    super.initState();
    _initialPage = getInitialPage();
    _actualPageNumber = _initialPage;
    _lastPageRead = _initialPage;
    // print("filePath: ${file.path}");
    _pdfController = PdfController(
      // document: PdfDocument.openAsset(widget.path!),
      document: PdfDocument.openData(widget.fileData),
      initialPage: _initialPage,
      viewportFraction: viewportFraction,
    );
  }
  
  int getInitialPage() {
    if(user!.containsKey("booksRead") && user!["booksRead"].containsKey(widget.bookId)) {
      return user!["booksRead"][widget.bookId]["lastPageRead"];
    }
    return 1;
  }

  @override
  void dispose() {
    _pdfController.dispose();
    Future.delayed(
      Duration.zero,
      () async {
        await changeLastPageRead(widget.bookId!, _lastPageRead);
      }
    );
    print("...pdfViewer dispose runned ${user!["booksRead"]}");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("viewportFraction: ${viewportFraction}");
    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        leading: IconButton(
          color: mainAppAmber,
          splashColor: Colors.white,
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.white,
          ),
          iconSize: 28,
          onPressed: (){
            Future.delayed(
              Duration.zero,
              () async {
                await changeLastPageRead(widget.bookId!, _lastPageRead);
                Navigator.of(context).pop();
              },
            );
          },
        ),
        // leading: IconButton(
        //   icon: Icon(
        //     Icons.arrow_back_rounded,
        //     color: Colors.white,
        //   ),
        //   onPressed: () async {
        //     // await changeLastPageRead(widget.bookId!, _lastPageRead);
        //   },
        // ),
        actions: <Widget>[
          // IconButton(
          //   icon: Icon(Icons.zoom_in),
          //   onPressed: () {
          //     viewportFraction = viewportFraction * 2;
          //     setState(() {});
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.navigate_before),
            onPressed: () {
              _pdfController.previousPage(
                curve: Curves.ease,
                duration: Duration(milliseconds: 100),
              );
            },
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              '$_actualPageNumber/$_allPagesCount',
              style: TextStyle(fontSize: 22),
            ),
          ),
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              _pdfController.nextPage(
                curve: Curves.ease,
                duration: Duration(milliseconds: 100),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (isSampleDoc) {
                _pdfController.loadDocument(
                    PdfDocument.openData(widget.fileData));
              } else {
                _pdfController.loadDocument(
                    PdfDocument.openData(widget.fileData));
              }
              isSampleDoc = !isSampleDoc;
            },
          )
        ],
      ),
      body: PdfView(
        documentLoader: Center(child: CircularProgressIndicator()),
        pageLoader: Center(child: CircularProgressIndicator()),
        controller: _pdfController,
        onDocumentLoaded: (document) async {
          setState(() {
            _allPagesCount = document.pagesCount;
          });
        },
        onPageChanged: (page) {
          _actualPageNumber = page;
          if(page > _lastPageRead) {
            _lastPageRead = page;
            ++totalPageReadToday;
          }
          setState(() {});
        },
        backgroundDecoration: BoxDecoration(
          color: appBarBackgroundColor,
        ),
        errorBuilder: (exception) {
          return Center(
            child: Container(
              color: mainAppAmber,
              child: Text(
                "Some Error Occured!! Please Log-in again. If Error continues, write email to us",
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: true,
                style: TextStyle(color: Color(0xFFFF0000)),
              ),
            ),
          );
        },
        renderer: (PdfPage page) => page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageFormat.PNG,
          backgroundColor: appBarBackgroundColor.toString(),
        ),
      ),
    );
  }
}