import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WallpaperApp());
}

class WallpaperApp extends StatefulWidget {
  @override
  _WallpaperAppState createState() => _WallpaperAppState();
}

class _WallpaperAppState extends State<WallpaperApp> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<String> wallpapers = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(onSearchQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void onSearchQueryChanged() {
    setState(() {
      searchQuery = _searchController.text;
      currentPage = 1;
      totalPages = 1;
      wallpapers.clear();
    });
    searchWallpapers();
  }

  void searchWallpapers() async {
    if (isLoading || currentPage > totalPages) return;

    setState(() {
      isLoading = true;
    });

    final results = await fetchWallpapers(searchQuery, currentPage);

    setState(() {
      wallpapers.addAll(results);
      currentPage++;
      isLoading = false;
    });
  }

  Future<List<String>> fetchWallpapers(String searchQuery, int page) async {
    final response = await http.get(
      Uri.parse(
          'https://api.unsplash.com/search/photos?query=$searchQuery&page=$page'),
      headers: {
        'Authorization':
            'Client-ID RqkdzJ6EJTL-A_4EM7r6DYpEUg16BcH0qJ3Z0oi4TuY',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> photos = data['results'];
      totalPages = data['total_pages'];
      return photos.map<String>((photo) => photo['urls']['regular']).toList();
    } else {
      throw Exception('Failed to fetch wallpapers');
    }
  }

  Widget buildWallpaperGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: wallpapers.length + 1, // +1 for the loading indicator
      itemBuilder: (BuildContext context, int index) {
        if (index == wallpapers.length) {
          if (currentPage <= totalPages) {
            return Center(child: CircularProgressIndicator());
          } else {
            return SizedBox.shrink();
          }
        } else {
          return GestureDetector(
            onTap: () {
              // Implement wallpaper details screen or download functionality
              print('Downloading wallpaper: ${wallpapers[index]}');
            },
            child: Image.network(
              wallpapers[index],
              fit: BoxFit.cover,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Wallpaper App'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Wallpaper',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      onSearchQueryChanged();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: wallpapers.isEmpty
                  ? Center(child: Text('No wallpapers to display'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification) {
                          final metrics = scrollNotification.metrics;
                          if (metrics.atEdge && metrics.pixels != 0) {
                            searchWallpapers();
                          }
                        }
                        return false;
                      },
                      child: buildWallpaperGrid(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
