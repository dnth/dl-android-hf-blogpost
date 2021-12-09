import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map> detectImage(String imageBase64) async {
  // Animefy the given image by requesting the gradio API of AnimeGANv2
  final response = await http.post(
    Uri.parse(
        'https://hf.space/gradioiframe/dnth/webdemo-microalgae-counting/api/predict'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, List<dynamic>>{
      'data': [
        imageBase64,
        false,
        true,
        0.5
      ] // Input Image | Label | Box | Detection Threshold
    }),
  );

  if (response.statusCode == 200) {
    final detectionResult = jsonDecode(response.body)["data"];

    final imageData =
        detectionResult[0].replaceAll('data:image/png;base64,', '');

    return {"count": detectionResult[1], "image": imageData};
    // If the server did return a 200 CREATED response,
    // then decode the image and return it.
    // final imageData = jsonDecode(response.body)["data"][0]
    //     .replaceAll('data:image/png;base64,', '');
    // return base64Decode(imageData);
  } else {
    // If the server did not return a 200 OKAY response,
    // then throw an exception.
    throw Exception('Failed to classify image.');
  }
}
