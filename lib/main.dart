import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // On urlChanged stream
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  /// Active image file
  File _imageFile;
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  final String phpEndPoint = 'http://192.168.0.104:80/phpAPI/image';

  /// Cropper plugin
  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
        sourcePath: _imageFile.path,
        // ratioX: 1.0,
        // ratioY: 1.0,
        // maxWidth: 512,
        // maxHeight: 512,
        toolbarColor: Colors.purple,
        toolbarWidgetColor: Colors.white,
        toolbarTitle: 'Crop It');

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  /// Select an image via gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = selected;
    });

    print("close");
    if (_imageFile == null) {
      print("close in");
      flutterWebViewPlugin.show();
    }
  }

  /// Remove image
  void _clear() {
    setState(() => _imageFile = null);
  }

  void _startUpload() {
    File file = _imageFile;
    if (file == null) return;
    String base64Image = base64Encode(file.readAsBytesSync());
    String fileName = file.path.split("/").last;

    http.post(phpEndPoint, body: {
      "image": base64Image,
      "name": fileName,
    }).then((res) {
      print(res.statusCode);
      print(fileName);
      Navigator.of(context).pop(null);
      flutterWebViewPlugin.show();
    }).catchError((err) {
      print(err);
    });
  }

  void initState() {
    super.initState();
    String selectedUrl = "https://your-url?ref=test-redirect";

    _onStateChanged = flutterWebViewPlugin.onStateChanged.listen((viewState) async {
      print("loading URLS");
      print(viewState.url);
      // start loading
      if (viewState.type == WebViewState.shouldStart) {
        if (viewState.url.startsWith("https://your-url?ref=test-camera")) {
          setState(() {
            flutterWebViewPlugin.evalJavascript("\$('.loading-screen-gif').css('display', 'none')");
            flutterWebViewPlugin.hide();
            _pickImage(ImageSource.camera);
          });
        } else if (viewState.url.startsWith("https://your-url?ref=test-gallery")) {
          setState(() {
            flutterWebViewPlugin.evalJavascript("\$('.loading-screen-gif').css('display', 'none')");
            flutterWebViewPlugin.hide();
            _pickImage(ImageSource.gallery);
          });
        }
      }

      // ready to load
      if (viewState.type == WebViewState.startLoad) {
        if (viewState.url.startsWith('https://you-web-url.in/download')) {
          setState(() {
            flutterWebViewPlugin.evalJavascript("\$('.loading-screen-gif').css('display', 'none')");
          });
        }
      }
    });

    Timer(Duration(seconds: 2), () {
      flutterWebViewPlugin.launch(selectedUrl,
          rect: Rect.fromLTWH(0.0, MediaQuery.of(context).padding.top, MediaQuery.of(context).size.width + 2.00, MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top + 2.00),
          scrollBar: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Preview the image and crop it
      body: ListView(
        children: <Widget>[
          if (_imageFile != null) ...[
            Image.file(_imageFile),
            Row(
              children: <Widget>[
                FlatButton(
                  child: Icon(Icons.crop),
                  onPressed: _cropImage,
                ),
                FlatButton(
                  child: Icon(Icons.delete),
                  onPressed: _clear,
                ),
              ],
            ),
            FlatButton.icon(
              label: Text('Upload to DB'),
              icon: Icon(Icons.cloud_upload),
              onPressed: _startUpload,
            ),
          ]
        ],
      ),
    );
  }
}
