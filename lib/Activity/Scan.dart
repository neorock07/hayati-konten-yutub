import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import "package:camera/camera.dart";
import 'package:hayati/Controller/ModelController.dart';
import 'package:hayati/Data/dataTret.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_v2/tflite_v2.dart';

class Scan extends StatefulWidget {
  const Scan({Key? key}) : super(key: key);

  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController? _camController;
  List? _hasilPred;
  Image? image;
  String? pathDir;
  DataTreat dt = DataTreat();

  @override
  void initState() {
    super.initState();
    FutureBuilder(future: loadModel(), builder: (_, snap) => Text(""));
  }

  Future<String?> loadModel() async {
    String? res = await Tflite.loadModel(
        model: "assets/model/model.tflite",
        labels: "assets/model/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false);
    return res;
  }

  Future<void> initCamera() async {
    var cameras = await availableCameras();
    _camController = CameraController(cameras[0], ResolutionPreset.high);
    await _camController!.initialize();
  }

  Future<String> takePicture() async {
    Directory root = await getTemporaryDirectory();
    String dir = "${root.path}/TANAMAN";
    await Directory(dir).create(recursive: true);
    String filePath = "${dir}/${DateTime.now()}.jpg";
    try {
      XFile? img = await _camController!.takePicture();
      img.saveTo(filePath);
    } catch (e) {
      log("Error : ${e.toString()}");
    }
    return filePath;
  }

  Future<dynamic> predict(String path) async {
    var prediksi = await Tflite.runModelOnImage(
        path: path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 3,
        threshold: 0.2,
        asynch: true);
    log("prediksi : ${prediksi}");
    return prediksi;
  }

  @override
  void dispose() {
    _camController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
          future: initCamera(),
          builder: (_, snapshot) => (snapshot.connectionState ==
                  ConnectionState.done)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        "SCAN TANAMAN",
                        style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height *
                            1 /
                            _camController!.value.aspectRatio,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: CameraPreview(_camController!),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      onTap: () async {
                        if (!_camController!.value.isTakingPicture) {
                          pathDir = null;
                          pathDir = await takePicture();
                          log("hasil : ${pathDir}");
                          // (pathDir != null)
                          //     ? log("iki lo : ${predict(pathDir!)}")
                          //     : log("kosong");
                          // ignore: use_build_context_synchronously
                          showModalBottomSheet(
                              context: context,
                              builder: ((context) {
                                return FutureBuilder(
                                    future: predict(pathDir!),
                                    builder: (_, snap) {
                                      return (snap.connectionState ==
                                              ConnectionState.done)
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 30),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  const SizedBox(
                                                    height: 30,
                                                  ),
                                                  const Align(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .topStart,
                                                    child: Text(
                                                      "Hasil Pengecekan :",
                                                      style: TextStyle(
                                                          fontFamily: "Poppins",
                                                          fontSize: 18,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                          "assets/virus.png",
                                                          fit: BoxFit.cover),
                                                      Text(
                                                        "${snap.data[0]['label']}",
                                                        style: const TextStyle(
                                                            fontFamily:
                                                                "Poppins",
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 15,
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      "Confidence : ${snap.data[0]['confidence']}",
                                                      style: const TextStyle(
                                                          fontFamily: "Poppins",
                                                          fontSize: 18,
                                                          color: Colors.black,
                                                          fontWeight: FontWeight
                                                              .normal),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  const Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      "Treatment : ",
                                                      style: TextStyle(
                                                          fontFamily: "Poppins",
                                                          fontSize: 18,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                   Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      "${dt.treatment[snap.data[0]['index']]}",
                                                      style:const TextStyle(
                                                          fontFamily: "Poppins",
                                                          fontSize: 18,
                                                          color: Colors.black,
                                                          fontWeight: FontWeight
                                                              .normal),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const CircularProgressIndicator();
                                    });
                              }));

                          setState(() {});
                        }
                      },
                      child: Container(
                        height: 80,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Color.fromRGBO(126, 217, 87, 1)),
                        child: const Center(
                          child: Text(
                            "PERIKSA",
                            style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : const Center(child: CircularProgressIndicator())),
    );
  }
}
