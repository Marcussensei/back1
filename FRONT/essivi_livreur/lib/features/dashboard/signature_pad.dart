import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignaturePad extends StatefulWidget {
  final Function(String) onSignatureCaptured;

  const SignaturePad({
    Key? key,
    required this.onSignatureCaptured,
  }) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  List<Offset?> _points = [];
  bool _isSigned = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Zone de signature
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                _points.add(localPosition);
                _isSigned = true;
              });
            },
            onPanEnd: (details) {
              _points.add(null); // Marquer la fin d'un trait
            },
            child: CustomPaint(
              painter: SignaturePainter(_points),
              size: Size.infinite,
            ),
          ),

          // Message d'instruction
          if (!_isSigned)
            Center(
              child: Text(
                'Faites signer le client ici',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),

          // Boutons
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Effacer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSigned ? _captureSignature : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSigned ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _isSigned = false;
    });
  }

  Future<void> _captureSignature() async {
    if (!_isSigned) return;

    try {
      // Créer une image de la signature
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = const Size(400, 200);

      // Fond blanc
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Dessiner la signature
      final signaturePainter = SignaturePainter(_points);
      signaturePainter.paint(canvas, size);

      // Convertir en image
      final picture = pictureRecorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      // Convertir en bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Encoder en base64
      final base64Signature = base64Encode(bytes);

      // Retourner la signature
      widget.onSignatureCaptured(base64Signature);
    } catch (e) {
      print('Erreur capture signature: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la capture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        // Point isolé
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
