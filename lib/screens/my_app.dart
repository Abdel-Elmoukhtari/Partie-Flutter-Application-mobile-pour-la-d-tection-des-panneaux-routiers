import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:aoto_route/services/tensorflow_service.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  final CameraDescription camera;

  const MyApp({@required this.camera});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  TensorflowService tensorflowService = TensorflowService();

  CameraController controller;
  bool isDetecting = false;
  List<dynamic> preds = [];

  Future startUp() async {
    await tensorflowService.loadModel();
  }

  Future<dynamic> delayed() async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    startUp();

    controller = CameraController(widget.camera, ResolutionPreset.high);

    controller.initialize().then(
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        controller.startImageStream(
          (CameraImage img) {
            if (!isDetecting) {
              isDetecting = true;
              delayed(); // TODO: averiguar a real necessidade
              Tflite.runModelOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(), // required
                imageHeight: img.height,
                imageWidth: img.width,
                numResults: 3,
              ).then(
                (recognitions) {
                  setState(() {
                    preds = recognitions;
                  });
                  // setRecognitions(recognitions, img.height, img.width);
                  print(recognitions);
                  isDetecting = false;
                },
              );
            }
          },
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // starts camera and then loads the tensorflow model
      startUp();
      controller = CameraController(widget.camera, ResolutionPreset.high);

      controller.initialize().then(
        (_) {
          if (!mounted) {
            return;
          }
          setState(() {});
          controller.startImageStream(
            (CameraImage img) {
              if (!isDetecting) {
                isDetecting = true;
                delayed(); // TODO: averiguar a real necessidade
                Tflite.runModelOnFrame(
                  bytesList: img.planes.map((plane) {
                    return plane.bytes;
                  }).toList(), // required
                  imageHeight: img.height,
                  imageWidth: img.width,
                  numResults: 3,
                ).then(
                  (recognitions) {
                    setState(() {
                      preds = recognitions;
                    });
                    // setRecognitions(recognitions, img.height, img.width);
                    print(recognitions);
                    isDetecting = false;
                  },
                );
              }
            },
          );
        },
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-Route',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFFF00FF),
      ),
      theme: ThemeData.dark(),
      home: Scaffold(
        body: controller.value.isInitialized
            ? _MainScreen(controller: controller, preds: preds)
            : Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }
}

class _MainScreen extends StatelessWidget {
  const _MainScreen({@required this.controller, @required this.preds});

  final CameraController controller;
  final List preds;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // shows the camera preview
        _CameraScreen(controller: controller),
        // shows the predictions
        preds.length > 0
            ? _PredictionsWidget(preds: preds)
            : Center(
                child: CircularProgressIndicator(),
              ),
      ],
    );
  }
}

class _PredictionsWidget extends StatelessWidget {
  const _PredictionsWidget({@required this.preds});

  final List preds;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF120320),
                ),
                height: 200,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    // shows recognition title
                    _titleWidget(),   
                    //testfoncyion 
                    //_testFonction(),              
                    // shows recognitions list
                    _contentWidget(context),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleWidget() {
    return Container(
      padding: EdgeInsets.only(top: 15, left: 90, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "Auto-Route",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
 
  // names: les labels des panne
  Widget _contentWidget(context) {
    var _width = MediaQuery.of(context).size.width - 91.0;
    var _padding = 10.0;
    var _labelWitdth = 200.0;
    var _labelConfidence = 30.0;
    var _barWitdth = _width - _labelWitdth - _labelConfidence - _padding * 1.5;
     
    if (preds.length > 0) {
      return Container(
        height: 100,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: preds.length,
          itemBuilder: (BuildContext context, int index) {
          
            AssetImage assetImage = AssetImage('assets/3.png');
            Image image = Image(image: assetImage);
            return Container(
              height: 100,
              child: Row(
                children: <Widget>[
                  Container(
                    child: image,
                    width: 90.0,
                    height: 90.0,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: _padding, right: _padding),
                    width: _labelWitdth,
                    child: Text(
                        preds[index]['label'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: _barWitdth,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      value: preds[index]['confidence'],
                    ),
                  ),
                  Container(
                    width: _labelConfidence,
                    child: Text(
                      (preds[index]['confidence'] * 100).toStringAsFixed(0) +
                          '%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

 }

class _CameraScreen extends StatelessWidget {
  const _CameraScreen({@required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return Container(
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black, Colors.transparent])
              .createShader(Rect.fromLTRB(0, 0, rect.width, rect.height / 4));
        },
        blendMode: BlendMode.darken,
        child: Transform.scale(
          scale: 1.0,
          child: AspectRatio(
            aspectRatio: MediaQuery.of(context).size.aspectRatio,
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                alignment: Alignment
                    .center, // introduced do center the camera screen preview
                fit: BoxFit.fitHeight,
                child: Container(
                  width: size,
                  height: size / controller.value.aspectRatio,
                  child: Stack(
                    children: <Widget>[
                      CameraPreview(controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


 