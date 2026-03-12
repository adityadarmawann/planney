import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/sp_button.dart';

class QrisCameraScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const QrisCameraScreen({super.key, this.onBackToHome});

  @override
  State<QrisCameraScreen> createState() => _QrisCameraScreenState();
}

class _QrisCameraScreenState extends State<QrisCameraScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCaptured = false;
  File? _capturedImage;
  final double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  bool _flashEnabled = false;

  void _handleBackNavigation() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!.call();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      final controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;
      _initializeControllerFuture = controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _maxZoom = 5.0; // Default max zoom multiplier
            _currentZoom = _minZoom;
          });
        }
        return;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengakses kamera')),
        );
        _handleBackNavigation();
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) return;

      if (_flashEnabled) {
        await controller.setFlashMode(FlashMode.off);
      } else {
        await controller.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _setZoom(double zoom) async {
    try {
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) return;

      await controller.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final initFuture = _initializeControllerFuture;
      final controller = _cameraController;
      if (initFuture == null || controller == null) return;

      await initFuture;
      
      // Trigger autofocus before capture
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Error setting autofocus: $e');
      }

      final image = await controller.takePicture();

      setState(() {
        _capturedImage = File(image.path);
        _isCaptured = true;
      });

      // Auto navigate to payment screen
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _navigateToPayment();
      });
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil foto')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _isCaptured = true;
        });

        // Auto navigate to payment screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _navigateToPayment();
        });
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka galeri')),
        );
      }
    }
  }

  void _navigateToPayment() {
    if (_capturedImage == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.qrisPayment,
      arguments: {
        'imagePath': _capturedImage!.path,
      },
    );

    // Reset state after navigation
    setState(() {
      _isCaptured = false;
      _capturedImage = null;
    });
  }

  void _retakePhoto() {
    setState(() {
      _isCaptured = false;
      _capturedImage = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QRIS'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: _handleBackNavigation,
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          final controller = _cameraController;

          if (snapshot.connectionState == ConnectionState.done &&
              controller != null &&
              controller.value.isInitialized) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Camera Preview or Captured Image
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: _isCaptured && _capturedImage != null
                              ? Image.file(
                                  _capturedImage!,
                                  fit: BoxFit.cover,
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Camera preview fills the container
                                    Positioned.fill(
                                      child: CameraPreview(controller),
                                    ),
                                    // Focus square overlay
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.secondary,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        // Flash button - top right
                        if (!_isCaptured)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _flashEnabled
                                    ? AppColors.secondary
                                    : Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _flashEnabled
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleFlash,
                                tooltip: _flashEnabled ? 'Flash On' : 'Flash Off',
                              ),
                            ),
                          ),
                        // Zoom slider - bottom of preview
                        if (!_isCaptured && _maxZoom > _minZoom)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.zoom_out,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _currentZoom,
                                      min: _minZoom,
                                      max: _maxZoom,
                                      onChanged: _setZoom,
                                      activeColor: AppColors.secondary,
                                      inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_currentZoom.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Instructions
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips Memindai:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Pastikan pencahayaan cukup terang\n'
                            '• Posisikan QRIS tepat di tengah frame\n'
                            '• Gunakan Zoom untuk fokus lebih dekat\n'
                            '• Aktifkan Flash jika kurang terang\n'
                            '• Tap Ambil Foto untuk capture',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Buttons
                    if (!_isCaptured) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: SpButton(
                          text: 'Ambil Foto',
                          onPressed: _capturePhoto,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: Icon(Icons.image_outlined),
                          label: Text('Pilih dari Galeri'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'QRIS berhasil dipilih',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _retakePhoto,
                          icon: Icon(Icons.refresh),
                          label: Text('Ambil Ulang'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _handleBackNavigation,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Batal'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Gagal mengakses kamera'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleBackNavigation,
                    child: Text('Kembali'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
