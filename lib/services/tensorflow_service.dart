import 'package:tflite/tflite.dart';

class TensorflowService {
  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/mobilenet.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      print('error loading model');
      print(e);
    }
  }
}
 