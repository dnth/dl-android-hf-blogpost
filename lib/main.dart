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

  String? _resultString;
  Map _resultDict = {
    "label": "None",
    "confidences": [
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0},
      {"label": "None", "confidence": 0.0}
    ]
  };
  File? imageURI;
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

  Future<File?> _createFileFromString(String base64ImageString) async {
    final encodedStr = base64ImageString;
    Uint8List bytes = base64.decode(encodedStr);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File(
        "$dir/" + DateTime.now().millisecondsSinceEpoch.toString() + ".pdf");
    await file.writeAsBytes(bytes);
    return file;
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
              imageURI == null
                  ? const Text(
                      'Select an image by pressing the camera icon and I will tell you my',
                      textAlign: TextAlign.center,
                    )
                  : Image.file(imageURI!, height: 300, fit: BoxFit.cover),
              const SizedBox(
                height: 10,
              ),
              Text("Microalgae Count: ${_microalgaeCount}",
                  style: Theme.of(context).textTheme.headline6),
              const SizedBox(height: 20),
              // buildResultsIndicators(_resultDict),
              // const SizedBox(
              //   height: 10,
              // ),
              RoundedLoadingButton(
                width: MediaQuery.of(context).size.width,
                child:
                    const Text('Count!', style: TextStyle(color: Colors.white)),
                controller: _btnController,
                onPressed: isClassifying || imageURI == null
                    ? null // null value disables the button
                    : () async {
                        setState(() {
                          isClassifying = true;
                        });

                        imgBytes = imageURI!.readAsBytesSync();
                        String base64Image =
                            "data:image/png;base64," + base64Encode(imgBytes!);
                        final result = await detectImage(base64Image);

                        final imgFiel =
                            await _createFileFromString(result['image']);

                        _btnController.reset();

                        setState(() {
                          // _resultString = parseResultsIntoString(result);
                          // _resultDict = result;
                          _microalgaeCount = result['count'];
                          imageURI = imgFiel;
                          // print(result['image']);
                          // imageURI!.writeAsBytesSync(result['image']);

                          isClassifying = false;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                                _resultString = "";
                                _resultDict = {
                                  "label": "None",
                                  "confidences": [
                                    {"label": "None", "confidence": 0.0},
                                    {"label": "None", "confidence": 0.0},
                                    {"label": "None", "confidence": 0.0}
                                  ]
                                };
                              });

                              File croppedFile = await cropImage(pickedFile);
                              final imgFile = File(croppedFile.path);

                              setState(() {
                                imageURI = imgFile;
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
                                _resultString = "";
                                _resultDict = {
                                  "label": "None",
                                  "confidences": [
                                    {"label": "None", "confidence": 0.0},
                                    {"label": "None", "confidence": 0.0},
                                    {"label": "None", "confidence": 0.0}
                                  ]
                                };
                              });

                              File croppedFile = await cropImage(pickedFile);
                              final imgFile = File(croppedFile.path);

                              setState(() {
                                imageURI = imgFile;
                              });
                              Navigator.pop(context);
                            }
                          },
                        )
                      ],
                    ));
              });
        },
        child: const Icon(Icons.camera),
      ),
    );
  }
}
