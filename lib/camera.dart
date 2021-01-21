import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'data/hive_database.dart';

List<CameraDescription> cameras;

IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

class CameraWidget extends StatefulWidget {
  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<CameraWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<CameraDescription> cameras;
  CameraController controller;
  bool isReady = false;
  bool showCamera = true;
  String imagePath;
  Note note;
  // Inputs
  TextEditingController nameController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController abvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setupCameras();
  }

  Future<void> setupCameras() async {
    try {
      cameras = await availableCameras();
      controller = new CameraController(cameras[0], ResolutionPreset.medium);
      await controller.initialize();
    } on CameraException catch (_) {
      setState(() {
        isReady = false;
      });
    }
    setState(() {
      isReady = true;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        body: Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Center(
                child: showCamera
                    ? Container(
                        height: 500,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Center(child: cameraPreviewWidget()),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            imagePreviewWidget(),
                            editCaptureControlRowWidget(),
                          ]),
              ),
              showCamera ? captureControlRowWidget() : Container(),
              cameraOptionsWidget(),
            ],
          ),
        )));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      showInSnackBar('Camera error $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget cameraOptionsWidget() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          showCamera ? cameraTogglesRowWidget() : Container(),
        ],
      ),
    );
  }

  Widget cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras != null) {
      if (cameras.isEmpty) {
        return const Center(child: Text('No camera found'));
      } else {
        for (CameraDescription cameraDescription in cameras) {
          toggles.add(
            SizedBox(
              width: 90.0,
              child: RadioListTile<CameraDescription>(
                title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
                groupValue: controller?.description,
                value: cameraDescription,
                onChanged: controller != null ? onNewCameraSelected : null,
              ),
            ),
          );
        }
      }
    }

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: toggles);
  }

  Widget captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null && controller.value.isInitialized
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }

  Widget editCaptureControlRowWidget() {
    final List args = ModalRoute.of(context).settings.arguments;
    final Note note = args[0];
    final noteIndex = args[1];
    final editing = args[2];

    return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Align(
          alignment: Alignment.topCenter,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton.icon(
                  label: Text('Retake Image'),
                  style: TextButton.styleFrom(
                    primary: Colors.red,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => setState(() {
                    print('retaking image');
                    deleteFile();
                    showCamera = true;
                  }),
                ),
                TextButton.icon(
                  label: Text('Save Image'),
                  icon: const Icon(Icons.save),
                  // color: Colors.blue,
                  onPressed: () => setState(() {
                    print('heres your image: ' + imagePath);
                    note.imageLocation = imagePath;
                    Navigator.pushNamed(context, '/notes/add',
                        arguments: [note, noteIndex, editing]);
                  }),
                ),
              ]),
        ));
  }

  Future<File> deleteFile() async {
    try {
      final file = File(imagePath);
      print('deleting ' + imagePath);
      return await file.delete();
    } catch (e) {
      print(e);
      return File(imagePath);
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((file) {
      if (mounted) {
        setState(() {
          showCamera = false;
          imagePath = file.path;
        });
      }
    });
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<XFile> takePicture() async {
    if (!controller.value.isInitialized) {
      return null;
    }

    if (controller.value.isTakingPicture) {
      return null;
    }

    try {
      XFile imageFile = await controller.takePicture();
      return imageFile;
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  Widget cameraPreviewWidget() {
    if (!isReady || !controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Widget imagePreviewWidget() {
    return Container(
        child: Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.topCenter,
        child: imagePath == null
            ? null
            : SizedBox(
                child: Image.file(File(imagePath)),
                height: 290.0,
              ),
      ),
    ));
  }
}
