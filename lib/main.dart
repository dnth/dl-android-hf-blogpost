import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_microalgae/detect_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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

  String parseResultsIntoString(Map results) {
    return """
    ${results['confidences'][0]['label']} - ${(results['confidences'][0]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][1]['label']} - ${(results['confidences'][1]['confidence'] * 100.0).toStringAsFixed(2)}% \n
    ${results['confidences'][2]['label']} - ${(results['confidences'][2]['confidence'] * 100.0).toStringAsFixed(2)}% """;
  }

  Widget buildPercentIndicator(String className, double classConfidence) {
    return LinearPercentIndicator(
      width: 200.0,
      lineHeight: 18.0,
      percent: classConfidence,
      center: Text(
        "${(classConfidence * 100.0).toStringAsFixed(2)} %",
        style: const TextStyle(fontSize: 12.0),
      ),
      trailing: Text(className),
      leading: const Icon(Icons.arrow_forward_ios),
      linearStrokeCap: LinearStrokeCap.roundAll,
      backgroundColor: Colors.grey,
      progressColor: Colors.blue,
      animation: true,
    );
  }

  Widget buildResultsIndicators(Map resultsDict) {
    return Column(
      children: [
        buildPercentIndicator(resultsDict['confidences'][0]['label'],
            (resultsDict['confidences'][0]['confidence'])),
        buildPercentIndicator(resultsDict['confidences'][1]['label'],
            (resultsDict['confidences'][1]['confidence'])),
        buildPercentIndicator(resultsDict['confidences'][2]['label'],
            (resultsDict['confidences'][2]['confidence']))
      ],
    );
  }

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
              imageMemory == null
                  ? const Text(
                      'Select an image by pressing the shutter icon',
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
                      )),
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
