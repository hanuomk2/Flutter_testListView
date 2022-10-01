import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:transparent_image/transparent_image.dart';
// import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test DropDownButton',
      //title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Test listView'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // photo gallery package start
  // Global配列など
  List<Album>? _albums;         // photo gallery packageのAlbum List型
  bool _loading = false;        // load用のフラグ
  var _locations = <String>[];  // DropDownButtonの要素(Album) String配列
  var _selectedLocation;        // DropDownButtonで選択された要素(Album)
  // for ListView add 2022.08.04
  List<Medium>? _media;         // 選択されたAlbumのMedia List型
  var _mediaCount = 0;          // 選択されたAlbumのMediaの数
  // for ImageView(FadeInImage) add 2022.09.30
  Medium? _mediaIndex;          // 選択されたThumbnail画像の本体

  @override
  void initState() {
    super.initState();
    _loading = true;
    initAsync();
  }

  // photo gallery packageへのアクセス許可とAlbumの取得
  Future<void> initAsync() async {
    if (await _promptPermissionSetting()) {
      List<Album> albums =
      await PhotoGallery.listAlbums(mediumType: MediumType.image);
      setState(() {
        _albums = albums;
        _loading = false;
        albums.forEach((album) {
          final name = album.name;
          if (name != null) _locations.add(name);
        });
        // _selectedLocation = albums[0].name;
        // _selectedLocationTogetAlbum(albums[0]);
      });
    }
    setState(() {
      _loading = false;
    });
  }

  // photo gallery packageへのアクセス許可
  Future<bool> _promptPermissionSetting() async {
    if (Platform.isIOS &&
        await Permission.storage.request().isGranted &&
        await Permission.photos.request().isGranted ||
        Platform.isAndroid && await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }
  // photo gallery package end

  // for listView add 2022.08.04
  // Albumが選択された場合のMediaの取得
  Future<void> _selectedLocationTogetAlbum(Album album) async {
    if (album != null) {
      final MediaPage mediaPage = await album.listMedia();
      setState(() {
        _media = mediaPage.items;
        _mediaCount = mediaPage.items.length;
      });
    }
  }

  // for ImageView(FadeInImage) add 2022.09.30
  // Thumbnailが選択された場合のMediaIndexの取得
  Future<void> _selectedThumbnail(Medium medium) async {
    setState(() {
      _mediaIndex = medium;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
      ? Center(
        child: CircularProgressIndicator(),
      )
      : Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedLocation,
              // DropdownButtonが選択された場合
              onChanged: (newValue) {
                setState(() {
                  if (newValue != null)
                    // for listView add 2022.08.04
                    // 選択されたAlbumで_selectedLocationTogetAlbumを呼び出す
                    if (newValue != _selectedLocation) {
                      _selectedLocation = newValue;
                      if (_albums != null) {
                        _albums!.forEach((album) {
                          final name = album.name;
                          if (name == _selectedLocation) {
                            _selectedLocationTogetAlbum(album);
                          }
                        });
                      }
                  };
                });
              },
              items: _locations.map((location) {
                return DropdownMenuItem(
                  child: new Text(location),
                  value: location,
                );
              }).toList(),
            ),
            // listView for add 2022.09.23
            // listViewは横スクロール、高さ160、幅120(最小)、アスペクト比fitHeightでサムネイル表示
            Container(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaCount,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _selectedThumbnail(_media![index]),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 120.0),
                      child: FadeInImage(
                        fit: BoxFit.fitHeight,
                        placeholder: MemoryImage(kTransparentImage),
                        image: ThumbnailProvider(
                          mediumId: _media![index].id,
                          mediumType: _media![index].mediumType,
                          highQuality: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // for ImageView(FadeInImage) add 2022.09.30
            // Thumbnailが選択された場合、取得したMediaIndexからImageView(FadeInImage)
            Expanded( //Container(
              // alignment: Alignment.center,
              child: _mediaIndex != null // _mediaIndex?.mediumType == MediumType.image
              ? FadeInImage(
                  fit: BoxFit.contain,
                  placeholder: MemoryImage(kTransparentImage),
                  image: PhotoProvider(mediumId: _mediaIndex!.id),
              )
              : Text('non selected thumbnail')
              /*: VideoProvider(
                  mediumId: _mediaIndex?.id,
              )*/
            ),
          ],
        ),
      ),
    );
  }
}
