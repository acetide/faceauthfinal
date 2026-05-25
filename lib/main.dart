import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'face_net_service.dart';
import 'face_painter.dart';
import 'services/api_service.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const FaceDetectorApp());
}

class FaceDetectorApp extends StatelessWidget {
  const FaceDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Verification',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
      ),
      home: const FaceDetectorScreen(),
    );
  }
}

class FaceDetectorScreen extends StatefulWidget {
  const FaceDetectorScreen({super.key});

  @override
  State<FaceDetectorScreen> createState() => _FaceDetectorScreenState();
}

class _FaceDetectorScreenState extends State<FaceDetectorScreen> {
  // ─────────────────────────────────────────────────────────────
  // ML KIT
  // ─────────────────────────────────────────────────────────────

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // FACENET
  // ─────────────────────────────────────────────────────────────

  final FaceNetService _faceNet = FaceNetService();

  // ─────────────────────────────────────────────────────────────
  // IMAGE PICKER
  // ─────────────────────────────────────────────────────────────

  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────────────────────────
  // STATES
  // ─────────────────────────────────────────────────────────────

  bool _loadingReference = false;
  bool _isProcessing = false;

  String? _errorMessage;

  final TextEditingController _employeeKodeNikController = TextEditingController();

  // REFERENCE IMAGE
  File? _referenceFile;
  List<Face> _referenceFaces = [];
  List<double>? _referenceEmbedding;

  // PROBE IMAGE
  File? _probeImageFile;
  List<Face> _probeFaces = [];

  // RESULT
  int? _verifyResult;
  double? _verifySimilarity;

  // IMAGE SIZE
  Size _imageSize = Size.zero;

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _employeeKodeNikController.dispose();
    _faceDetector.close();
    _faceNet.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD REFERENCE IMAGE FROM ASSETS
  // ─────────────────────────────────────────────────────────────

  Future<void> _initializeReferenceFromFileApi() async {
    setState(() {
      _loadingReference = true;
      _errorMessage = null;
    });

    try {
      final employeeKodeNik = _employeeKodeNikController.text.trim();
      if (employeeKodeNik.isEmpty) {
        throw Exception('Employee KodeNik is required.');
      }

      await _faceNet.init();

      // Use Dio with JWT for authenticated request
      final response = await ApiService().dio.get<List<int>>(
        '/Api/Mobile/Portal/GetEmployeeFaceReference/$employeeKodeNik',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load reference from FILEAPI (${response.statusCode}): ${response.statusMessage}');
      }

      final bytes = response.data!;
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/reference_$employeeKodeNik.jpg');
      await tempFile.writeAsBytes(bytes);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('No face found in FILEAPI reference image.');
      }

      // Convert bytes to Uint8List for embedding and decoding
      final uint8Bytes = Uint8List.fromList(bytes);
      final embedding = await _faceNet.embedFromImage(uint8Bytes, faces.first);
      if (embedding == null) {
        throw Exception('Failed to create embedding from FILEAPI reference image.');
      }

      final decoded = await decodeImageFromList(uint8Bytes);
      setState(() {
        _referenceFile = tempFile;
        _referenceFaces = faces;
        _referenceEmbedding = embedding;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _loadingReference = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Reference load failed: $e';
        _loadingReference = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PICK PROBE IMAGE
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _probeImageFile = file;
        _probeFaces = [];

        _verifyResult = null;
        _verifySimilarity = null;

        _errorMessage = null;

        _isProcessing = true;
      });

      await _detectFaces(
        file,
        onDone: (faces, size) async {
          setState(() {
            _probeFaces = faces;
            _imageSize = size;
            _isProcessing = false;
          });

          if (faces.isEmpty) {
            setState(() {
              _errorMessage = 'No face found in selected image.';
            });

            return;
          }

          await _runVerification(file, faces.first);
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Image picking failed: $e';
        _isProcessing = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DETECT FACES
  // ─────────────────────────────────────────────────────────────

  Future<void> _detectFaces(
    File imageFile, {
    required void Function(List<Face>, Size) onDone,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final decoded = await decodeImageFromList(bytes);

      final size = Size(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      );

      final inputImage = InputImage.fromFilePath(imageFile.path);

      final faces = await _faceDetector.processImage(inputImage);

      onDone(faces, size);
    } catch (e) {
      setState(() {
        _errorMessage = 'Face detection failed: $e';
        _isProcessing = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFY FACE
  // ─────────────────────────────────────────────────────────────

  Future<void> _runVerification(
    File file,
    Face face,
  ) async {
    try {
      if (_referenceEmbedding == null) {
        setState(() {
          _errorMessage = 'Reference embedding not loaded.';
        });

        return;
      }

      final bytes = await file.readAsBytes();

      final probeEmbedding = await _faceNet.embedFromImage(bytes, face);

      if (probeEmbedding == null) {
        setState(() {
          _errorMessage = 'Failed to create embedding from selected image.';
        });

        return;
      }

      final result = _faceNet.verify(
        probeEmbedding,
        _referenceEmbedding!,
      );

      setState(() {
        _verifyResult = result.verified;
        _verifySimilarity = result.similarity;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final verified = _verifyResult == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '🔍 Face Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // REFERENCE LOADING
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _employeeKodeNikController,
                    decoration: const InputDecoration(
                      labelText: 'Employee KodeNik',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadingReference ? null : _initializeReferenceFromFileApi,
                  child: const Text('Load FILEAPI Reference'),
                ),
              ],
            ),
          ),
          if (_loadingReference)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading reference face from FILEAPI...'),
                ],
              ),
            ),

          // IMAGES
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildImageSlot(
                    title: 'Reference',
                    file: _referenceFile,
                    faces: _referenceFaces,
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _buildImageSlot(
                    title: 'Probe',
                    file: _probeImageFile,
                    faces: _probeFaces,
                  ),
                ),
              ],
            ),
          ),

          // RESULT
          if (_verifyResult != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: verified
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: verified ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    verified ? Icons.check_circle : Icons.cancel,
                    size: 48,
                    color: verified ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verified ? 'MATCH FOUND' : 'NOT A MATCH',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: verified ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Similarity: ${((_verifySimilarity ?? 0) * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // ERROR
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),

          // BUTTONS
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingReference
                        ? null
                        : () => _pickImage(
                              ImageSource.gallery,
                            ),
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingReference
                        ? null
                        : () => _pickImage(
                              ImageSource.camera,
                            ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE SLOT
  // ─────────────────────────────────────────────────────────────

  Widget _buildImageSlot({
    required String title,
    required File? file,
    required List<Face> faces,
  }) {
    if (file == null) {
      return Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 18,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              file,
              fit: BoxFit.contain,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            if (faces.isNotEmpty)
              CustomPaint(
                size: Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
                painter: FacePainter(
                  faces: faces,
                  imageSize: _imageSize,
                  availableSize: Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}
