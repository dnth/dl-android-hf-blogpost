import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_microalgae/detect_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final List<String> imgList = [
  'https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80',
  'https://images.unsplash.com/photo-1522205408450-add114ad53fe?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=368f45b0888aeb0b7b08e3a1084d3ede&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=94a1e718d89ca60a6337a6008341ca50&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
  'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
  'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80'
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microalgae Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Microalgae Detector'),
      debugShowCheckedModeBanner: false,
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
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  // File? imageURI;
  String? imageURIWeb;
  Uint8List? imageMemory;
  Uint8List? imgBytes;
  bool isClassifying = false;
  int _microalgaeCount = 0;

  Future<File> cropImage(XFile pickedFile) async {
    // Crop image here
    final File? croppedFile = await ImageCropper.cropImage(
      sourcePath: pickedFile.path,
      cropStyle: CropStyle.rectangle,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        // CropAspectRatioPreset.ratio3x2,
        // CropAspectRatioPreset.original,
        // CropAspectRatioPreset.ratio4x3,
        // CropAspectRatioPreset.ratio16x9
      ],
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      iosUiSettings: const IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    );

    return croppedFile!;
  }

  final List<Widget> imageSliders = imgList
      .map((item) => Container(
            child: Container(
              margin: const EdgeInsets.all(5.0),
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  child: Stack(
                    children: <Widget>[
                      Image.network(item, fit: BoxFit.cover, width: 1000.0),
                      Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(200, 0, 0, 0),
                                Color.fromARGB(0, 0, 0, 0)
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          child: Text(
                            'No. ${imgList.indexOf(item)} image',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: 2.0,
                  enlargeCenterPage: true,
                ),
                items: imageSliders,
              ),
              imageMemory == null
                  ? const Text(
                      'Select a sample image above or upload your own image by pressing the shutter icon',
                      textAlign: TextAlign.center,
                    )
                  : SizedBox(
                      height: 300,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.memory(
                          imageMemory!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
              const SizedBox(
                height: 10,
              ),
              Text("Microalgae Count: $_microalgaeCount",
                  style: Theme.of(context).textTheme.headline6),
              const SizedBox(height: 20),
              RoundedLoadingButton(
                width: MediaQuery.of(context).size.width,
                child:
                    const Text('Count!', style: TextStyle(color: Colors.white)),
                controller: _btnController,
                onPressed: isClassifying || (imageMemory == null)
                    ? null // null value disables the button
                    : () async {
                        setState(() {
                          isClassifying = true;
                        });

                        if (kIsWeb) {
                          imgBytes = imageMemory;
                        } else {
                          imgBytes = imageMemory;
                        }

                        String base64Image =
                            "data:image/png;base64," + base64Encode(imgBytes!);

                        final result =
                            await detectImage(base64Image, false, 0.5);

                        _btnController.reset();

                        setState(() {
                          _microalgaeCount = result['count'];

                          imageMemory = base64Decode(result['image']);

                          isClassifying = false;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (kIsWeb) {
            // running on the web!
            print("Operating on web");

            final pickedFile =
                await ImagePicker().pickImage(source: ImageSource.gallery);

            final img = await pickedFile!.readAsBytes();

            setState(() {
              // imageURIWeb = pickedFile!.path;
              imageMemory = img;
            });
          } else {
            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return Container(
                    height: 120,
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera),
                          title: const Text("Camera"),
                          onTap: () async {
                            final XFile? pickedFile = await ImagePicker()
                                .pickImage(source: ImageSource.camera);

                            if (pickedFile != null) {
                              // Clear result of previous inference as soon as new image is selected
                              setState(() {
                                _microalgaeCount = 0;
                              });

                              File croppedFile = await cropImage(pickedFile);
                              final imgFile = File(croppedFile.path);

                              setState(() {
                                imageMemory = imgFile.readAsBytesSync();
                              });
                              Navigator.pop(context);
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.image),
                          title: const Text("Gallery"),
                          onTap: () async {
                            final XFile? pickedFile = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);

                            if (pickedFile != null) {
                              // Clear result of previous inference as soon as new image is selected
                              setState(() {
                                _microalgaeCount = 0;
                              });

                              File croppedFile = await cropImage(pickedFile);
                              final imgFile = File(croppedFile.path);

                              setState(() {
                                imageMemory = imgFile.readAsBytesSync();
                              });
                              Navigator.pop(context);
                            }
                          },
                        )
                      ],
                    ));
              },
            );
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
