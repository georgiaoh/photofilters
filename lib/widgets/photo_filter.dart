import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photofilters/filters/filters.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path_provider/path_provider.dart';

class PhotoFilter extends StatelessWidget {
  final imageLib.Image image;
  final String filename;
  final Filter filter;
  final BoxFit fit;
  final Widget loader;
  PhotoFilter({
    @required this.image,
    @required this.filename,
    @required this.filter,
    this.fit = BoxFit.fill,
    this.loader = const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
      ),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: compute(applyFilter, <String, dynamic>{
        "filter": filter,
        "image": image,
        "filename": filename,
      }),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return loader;
          case ConnectionState.active:
          case ConnectionState.waiting:
            return loader;
          case ConnectionState.done:
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            return Image.memory(
              snapshot.data,
              fit: fit,
            );
        }
        return null; // unreachable
      },
    );
  }
}

String _filterName;

void setFilterName(Filter filter) {
  _filterName = filter.name;
}

String getFilterName() {
  return _filterName;
}

///The PhotoFilterSelector Widget for apply filter from a selected set of filters
class PhotoFilterSelector extends StatefulWidget {
  //final Widget title;

  final List<Filter> filters;
  final imageLib.Image image;
  final Widget loader;
  final BoxFit fit;
  final String filename;
  final bool circleShape;
  final bool photoIsPortrait;

  const PhotoFilterSelector({
    Key key,
    //@required this.title,
    @required this.filters,
    @required this.image,
    this.loader = const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
      ),
    ),
    this.fit = BoxFit.fill,
    @required this.filename,
    this.circleShape = false,
    this.photoIsPortrait,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _PhotoFilterSelectorState();
}

class _PhotoFilterSelectorState extends State<PhotoFilterSelector> {
  String filename;
  Map<String, List<int>> cachedFilters = {};
  Filter _filter;
  imageLib.Image _checkImage;
  imageLib.Image image;
  bool loading;
  bool photoIsPortrait;

  @override
  void initState() {
    super.initState();
    loading = false;
    _filter = widget.filters[0];
    filename = widget.filename;
    photoIsPortrait = widget.photoIsPortrait;
    checkPhotoDimensions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkPhotoDimensions() {
    _checkImage = widget.image;
    image = _checkImage;
    if (photoIsPortrait) {
      int width = _checkImage.width;
      int height = _checkImage.height;
      if (width > height) {
        image = imageLib.copyRotate(_checkImage, 90);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Container(
        child: loading
            ? widget.loader
            : orientation == Orientation.portrait
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _photoFilterViewer(orientation),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _photoFilterViewer(orientation),
                  ),
      );
    });
  }

  List<Widget> _photoFilterViewer(Orientation orientation) {
    return [
      Expanded(
        flex: 2,
        child: Container(
          padding: EdgeInsets.all(12.0),
          child: _buildFilteredImage(
            _filter,
            image,
            filename,
          ),
        ),
      ),
      Expanded(
        flex: 1,
        child: Container(
          child: ListView.builder(
            scrollDirection: orientation == Orientation.portrait
                ? Axis.horizontal
                : Axis.vertical,
            itemCount: widget.filters.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                child: Container(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _buildFilterThumbnail(
                          widget.filters[index], image, filename),
                      SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        widget.filters[index].name,
                      )
                    ],
                  ),
                ),
                onTap: () {
                  setState(() {
                    _filter = widget.filters[index];
                    setFilterName(_filter);
                  });
                  saveFilteredImage();
                },
              );
            },
          ),
        ),
      ),
    ];
  }

  _buildFilterThumbnail(Filter filter, imageLib.Image image, String filename) {
    if (cachedFilters[filter?.name ?? "_"] == null) {
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(52.0)),
                  border: Border.all(
                    color: filter == _filter ? Color(0xFF0097af) : Colors.white,
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 46.0,
                    child: Center(
                      child: widget.loader,
                    ),
                  ),
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              cachedFilters[filter?.name ?? "_"] = snapshot.data;
              return Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(52.0)),
                  border: Border.all(
                    color: filter == _filter ? Color(0xFF0097af) : Colors.white,
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    radius: 46.0,
                    backgroundImage: MemoryImage(
                      snapshot.data,
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              );
          }
          return null; // unreachable
        },
      );
    } else {
      return Container(
        width: 100.0,
        height: 100.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(52.0)),
          border: Border.all(
            color: filter == _filter ? Color(0xFF0097af) : Colors.white,
            width: 2.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0),
          child: CircleAvatar(
            radius: 46.0,
            backgroundImage: MemoryImage(
              cachedFilters[filter?.name ?? "_"],
            ),
            backgroundColor: Colors.white,
          ),
        ),
      );
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/filtered_${_filter?.name ?? "_"}_$filename');
  }

  Future<File> saveFilteredImage() async {
    var imageFile = await _localFile;
    await imageFile.writeAsBytes(cachedFilters[_filter?.name ?? "_"]);
    return imageFile;
  }

  Widget _buildFilteredImage(
      Filter filter, imageLib.Image image, String filename) {
    if (cachedFilters[filter?.name ?? "_"] == null) {
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return widget.loader;
            case ConnectionState.active:
            case ConnectionState.waiting:
              return widget.loader;
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              cachedFilters[filter?.name ?? "_"] = snapshot.data;
              return widget.circleShape
                  ? SizedBox(
                      height: MediaQuery.of(context).size.width / 3,
                      width: MediaQuery.of(context).size.width / 3,
                      child: Center(
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width / 3,
                          backgroundImage: MemoryImage(
                            snapshot.data,
                          ),
                        ),
                      ),
                    )
                  : Image.memory(
                      snapshot.data,
                      fit: BoxFit.contain,
                    );
          }
          return null; // unreachable
        },
      );
    } else {
      return widget.circleShape
          ? SizedBox(
              height: MediaQuery.of(context).size.width / 3,
              width: MediaQuery.of(context).size.width / 3,
              child: Center(
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width / 3,
                  backgroundImage: MemoryImage(
                    cachedFilters[filter?.name ?? "_"],
                  ),
                ),
              ),
            )
          : Image.memory(
              cachedFilters[filter?.name ?? "_"],
              fit: widget.fit,
            );
    }
  }
}

///The global applyfilter function
List<int> applyFilter(Map<String, dynamic> params) {
  Filter filter = params["filter"];
  imageLib.Image image = params["image"];
  String filename = params["filename"];
  List<int> _bytes = image.getBytes();
  if (filter != null) {
    filter.apply(_bytes);
  }
  imageLib.Image _image =
      imageLib.Image.fromBytes(image.width, image.height, _bytes);
  _bytes = imageLib.encodeNamedImage(_image, filename);

  return _bytes;
}

///The global buildThumbnail function
List<int> buildThumbnail(Map<String, dynamic> params) {
  int width = params["width"];
  params["image"] = imageLib.copyResize(params["image"], width: width);
  return applyFilter(params);
}
