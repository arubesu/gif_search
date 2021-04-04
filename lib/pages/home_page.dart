import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gif_search/pages/gif_page.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum SearchType { trending, query }

class _HomePageState extends State<HomePage> {
  String _currentQuery = "";

  final baseApi = "https://api.giphy.com/v1/gifs";

  ScrollController _scrollController;
  var _currentPage = 1;
  var _pageSize = 10;
  var _gifs = [];
  var _isLoadingGifs;
  var _lastSearchType = SearchType.trending;
  var _lastQuery;

  @override
  void initState() {
    super.initState();

    _isLoadingGifs = true;

    _getGifs().then((data) {
      _fillGifs(data);
    });

    _scrollController = ScrollController(initialScrollOffset: 5.0)
      ..addListener(_scrollListener);
  }

  Future<Map> _getGifs() async {
    var _offset = (_currentPage - 1) * _pageSize;
    var _currentSearch =
        _currentQuery.isEmpty ? SearchType.trending : SearchType.query;

    if (_currentSearch != _lastSearchType || _lastQuery != _currentQuery) {
      _gifs = [];
      _offset = 0;
      _currentPage = 1;
    }

    var _url = _currentSearch == SearchType.query
        ? Uri.parse(
            "$baseApi/search?api_key=${env["API_KEY"]}&q=$_currentQuery&limit=$_pageSize&offset=$_offset&rating=g&lang=en")
        : Uri.parse(
            "$baseApi/trending?api_key=${env["API_KEY"]}&limit=$_pageSize&offset=$_offset&rating=g");

    _isLoadingGifs = true;

    var response = await http.get(_url);

    _lastSearchType = _currentSearch;
    _lastQuery = _currentQuery;

    return json.decode(response.body);
  }

  _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        if (!_isLoadingGifs) {
          _currentPage = _currentPage + 1;
        }
      });
    }
  }

  Future _fillGifs(Map responseData) async {
    var gifData = responseData["data"];

    for (var gifItem in gifData) {
      _gifs.add(gifItem["images"]["fixed_height"]["url"]);
    }

    _isLoadingGifs = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Image.network(
            "https://developers.giphy.com/branch/master/static/header-logo-8974b8ae658f704a5b48a2d039b8ad93.gif"),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
                onSubmitted: (text) {
                  setState(() {
                    _currentQuery = text;
                  });
                },
                decoration: InputDecoration(
                    labelText: "Search",
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.white),
                    )),
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center),
          ),
          Expanded(
            child: FutureBuilder(
              future: _getGifs(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Container(
                      width: 200,
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        strokeWidth: 5,
                      ),
                    );
                  default:
                    if (snapshot.hasError) {
                      return Container(
                        child: Text(
                            'Something wrong happened =( \n\n\nTry again later!',
                            style: TextStyle(
                              color: Colors.white,
                            )),
                        alignment: Alignment.center,
                      );
                    }

                    return _buildGifTable(context, snapshot);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGifTable(BuildContext context, AsyncSnapshot snapshot) {
    _fillGifs(snapshot.data);

    return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(10),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _gifs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return GifPage(_gifs[index]);
              }));
            },
            onLongPress: () {
              Share.share(_gifs[index]);
            },
            child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: _gifs[index],
                height: 300,
                fit: BoxFit.cover),
          );
        });
  }
}
